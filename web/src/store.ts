/**
 * 会话状态 + 发送流程编排（TypeScript 版）。
 * 一个 reactive 对象就够了，没必要上 Pinia（单页单会话）。
 */
import { reactive } from './vue.js'
import { runRealChat } from './agent.js'
import { listProducts } from './api.js'
import { loadPending } from './shopState.js'
import type { AppState, ChatEventName, ChatEventPayload, ChatMessage } from './types.js'

let seq = 0
const nextId = () => ++seq

// 一次问答最多等多久（真 Agent 冷启动 + 模型生成本身就要几秒到几十秒）
const TIMEOUT_MS = 60000

// ?view=chat 直接进客服页；默认是手机商城
const params = new URLSearchParams(location.search)
const startView: AppState['view'] = params.get('view') === 'chat' ? 'chat' : 'shop'

export const state = reactive<AppState>({
  view: startView,
  messages: [],
  candidates: [],
  candidateTotal: 0,
  selected: [],
  status: null,
  busy: false,
  backend: { java: false, total: 0 },
  fatalError: '',
  clarifyCount: 0,
})

/** 左侧菜单切换（手机商城 / 购物车 / 智能客服 / 登录） */
const VIEWS = ['shop', 'chat', 'cart', 'login']

export function setView(view: string): void {
  const next = VIEWS.includes(view) ? view : 'shop'
  // AppState['view'] 的类型是 'shop' | 'chat'，这里运行时允许更多视图，故做一次窄化断言
  ;(state as unknown as { view: string }).view = next
}

export const EXAMPLES: string[] = [
  '预算 3000，想要续航好、拍照好的手机',
  '两千以内，学生用，别太重',
  '5000 左右，打游戏为主',
  '想要 300 元的降噪耳机',
]

export function init(): void {
  state.messages.push({
    id: nextId(),
    role: 'assistant',
    text: '想看什么手机？说个预算，或者直接说你在意的点，续航、拍照、别太重，我帮你挑几款。',
    streaming: false,
  })
  refreshBackend()
}

export async function refreshBackend(): Promise<void> {
  try {
    const page = await listProducts({ size: 1 })
    state.backend.java = true
    state.backend.total = page.total
  } catch {
    state.backend.java = false
  }
}

export function reset(): void {
  state.messages.length = 0
  state.candidates.length = 0
  state.candidateTotal = 0
  state.selected.length = 0
  state.status = null
  state.busy = false
  state.clarifyCount = 0
  init()
}

export async function send(text: string): Promise<void> {
  const content = String(text || '').trim()
  if (!content || state.busy) return

  // 最近几轮对话（不含本轮）作为上下文。不带上下文时，
  // 「不限预算，只看参数」这种补充回答会被后端当成全新问题，于是反复追问同一个问题。
  const history = state.messages
    .filter((m: ChatMessage) => m.role === 'user' || (m.role === 'assistant' && m.text))
    .slice(-6)
    .map((m: ChatMessage) => ({ role: m.role, content: m.text }))
  const clarifyCount = state.clarifyCount

  state.busy = true
  state.candidates.length = 0
  state.candidateTotal = 0
  state.selected.length = 0

  state.messages.push({ id: nextId(), role: 'user', text: content, streaming: false })
  state.messages.push({
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
  const reply = state.messages[state.messages.length - 1]

  const emit = <E extends ChatEventName>(event: E, data: ChatEventPayload[E]) => {
    switch (event) {
      case 'status':
        state.status = data as ChatEventPayload['status']
        break
      case 'intent':
        reply.intent = data as ChatEventPayload['intent']
        break
      case 'candidates': {
        const payload = data as ChatEventPayload['candidates']
        state.clarifyCount = 0 // 需求已经补齐，下一轮重新计
        state.candidates.length = 0
        state.candidates.push(...(payload.items || []))
        state.candidateTotal = payload.total || 0
        state.selected.length = 0
        state.selected.push(...state.candidates.map((c) => c.id))
        break
      }
      case 'clarify':
        reply.clarify = data as ChatEventPayload['clarify']
        state.clarifyCount += 1
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
    state.status = null
    state.busy = false
    // 聊天结束后查一次：agent 可能刚准备了一个待确认订单，外壳据此渲染确认按钮
    void loadPending()
  }
}

/** 对比表里勾选/取消 */
export function toggleSelected(id: number): void {
  const i = state.selected.indexOf(id)
  if (i >= 0) state.selected.splice(i, 1)
  else state.selected.push(id)
}

/** 对比表只展示勾中的，且按分数排序 */
export function compareItems() {
  return state.candidates
    .filter((c) => state.selected.includes(c.id))
    .sort((a, b) => b.score - a.score)
}
