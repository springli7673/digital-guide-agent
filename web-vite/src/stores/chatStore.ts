/**
 * 聊天仓库：消息、候选、流式状态。
 *
 * 和旧版 store 的差别只有一处：从"一个 reactive 对象"变成 Pinia 的 state。
 * 业务逻辑（看门狗超时、clarifyCount 计数、候选勾选）原样保留。
 */
import { defineStore } from 'pinia'
import { runRealChat } from '@/api/agent'
import type { Candidate, ChatMessage, ChatEventName, ChatEventPayload } from '@/types'
import { useShopStore } from './shopStore'

/** 示例提示词：三条推荐链路 + 一条工具链路 */
export const EXAMPLES: string[] = [
  '预算 3000，想要续航好、拍照好的手机',
  '两千以内，学生用，别太重',
  '5000 左右，打游戏为主',
  'Redmi K80 和 iQOO Neo10 哪个更值得买',
]

// 一次问答最多等多久（冷启动 + 模型生成本身就要几秒到几十秒）
const TIMEOUT_MS = 60000

let seq = 0
const nextId = () => ++seq

interface ChatState {
  messages: ChatMessage[]
  candidates: Candidate[]
  candidateTotal: number
  selected: number[]
  status: { stage: string; text: string } | null
  busy: boolean
  clarifyCount: number
  fatalError: string
}

export const useChatStore = defineStore('chat', {
  state: (): ChatState => ({
    messages: [],
    candidates: [],
    candidateTotal: 0,
    selected: [],
    status: null,
    busy: false,
    clarifyCount: 0,
    fatalError: '',
  }),

  getters: {
    /** 对比表只展示勾中的，且按分数排序 */
    compareItems(state): Candidate[] {
      return state.candidates
        .filter((c) => state.selected.includes(c.id))
        .sort((a, b) => b.score - a.score)
    },
    showExamples(state): boolean {
      return state.messages.length <= 1 && !state.busy
    },
  },

  actions: {
    init(): void {
      if (this.messages.length) return
      this.messages.push({
        id: nextId(),
        role: 'assistant',
        text: '想看什么手机？说个预算，或者直接说你在意的点，续航、拍照、别太重，我帮你挑几款。',
        streaming: false,
      })
    },

    reset(): void {
      this.messages.length = 0
      this.candidates.length = 0
      this.candidateTotal = 0
      this.selected.length = 0
      this.status = null
      this.busy = false
      this.clarifyCount = 0
      this.init()
    },

    async send(text: string): Promise<void> {
      const content = String(text || '').trim()
      if (!content || this.busy) return

      // 最近几轮对话（不含本轮）作为上下文。不带上下文时，
      // 「不限预算，只看参数」这种补充回答会被后端当成全新问题，于是反复追问同一个问题。
      const history = this.messages
        .filter((m) => m.role === 'user' || (m.role === 'assistant' && m.text))
        .slice(-6)
        .map((m) => ({ role: m.role, content: m.text }))
      const clarifyCount = this.clarifyCount

      this.busy = true
      this.candidates.length = 0
      this.candidateTotal = 0
      this.selected.length = 0

      this.messages.push({ id: nextId(), role: 'user', text: content, streaming: false })
      this.messages.push({
        id: nextId(),
        role: 'assistant',
        text: '',
        streaming: true,
        intent: null,
        clarify: null,
        error: null,
        latency: null,
      })
      // 关键：必须拿到数组里的「响应式代理」再改，
      // 直接改 push 进去的原始对象不会触发视图更新（气泡会一直转圈不显示内容）
      const reply = this.messages[this.messages.length - 1]

      const emit = <E extends ChatEventName>(event: E, data: ChatEventPayload[E]) => {
        switch (event) {
          case 'status':
            this.status = data as ChatEventPayload['status']
            break
          case 'intent':
            reply.intent = data as ChatEventPayload['intent']
            break
          case 'candidates': {
            const payload = data as ChatEventPayload['candidates']
            this.clarifyCount = 0 // 需求已经补齐，下一轮重新计
            this.candidates.length = 0
            this.candidates.push(...(payload.items || []))
            this.candidateTotal = payload.total || 0
            this.selected.length = 0
            this.selected.push(...this.candidates.map((c) => c.id))
            break
          }
          case 'clarify':
            reply.clarify = data as ChatEventPayload['clarify']
            this.clarifyCount += 1
            break
          case 'token':
            reply.text += (data as ChatEventPayload['token']).text || ''
            break
          case 'done':
            reply.latency = (data as ChatEventPayload['done']).latencyMs
            break
          case 'error':
            reply.error = (data as ChatEventPayload['error']).msg || '出错了'
            break
          default:
            break
        }
      }

      try {
        // 看门狗：网关卡死 / 模型长时间无响应时，不要让界面无限转圈
        const run = runRealChat(content, emit, { history, clarifyCount })
        await Promise.race([
          run,
          new Promise((_, reject) =>
            setTimeout(
              () => reject(new Error(`超过 ${Math.round(TIMEOUT_MS / 1000)} 秒没有结果`)),
              TIMEOUT_MS,
            ),
          ),
        ])
      } catch (error) {
        const e = error as Error
        reply.error = e.name === 'AbortError' ? '请求已取消' : `调用失败：${e.message}`
      } finally {
        reply.streaming = false
        this.status = null
        this.busy = false
        // 聊天结束后查一次：agent 可能刚准备了一个待确认订单
        void useShopStore().loadPending()
      }
    },

    toggleSelected(id: number): void {
      const i = this.selected.indexOf(id)
      if (i >= 0) this.selected.splice(i, 1)
      else this.selected.push(id)
    },
  },
})
