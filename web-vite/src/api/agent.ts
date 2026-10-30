/**
 * 与后端 Agent 的对接：消费 POST /v1/chat 的 SSE 流。
 *
 * 事件协议（改这里必须同步 backend/.../ai/web/AiChatController.java 与 ai/graph 的节点）：
 *   status / intent / candidates / clarify / token / done / error
 *
 * 注意不能用 EventSource：它只支持 GET，而我们是 POST + JSON body。
 * 所以这里是手写 SSE 解析——**这段逻辑不要改**，它是逐字节对齐后端输出的。
 */
import type { ChatEventName, ChatEventPayload } from '@/types'
import { getToken } from './client'

export interface HistoryItem {
  role: string
  content: string
}

interface RunOptions {
  sessionId?: string
  signal?: AbortSignal
  history?: HistoryItem[]
  clarifyCount?: number
}

export type Emit = <E extends ChatEventName>(event: E, payload: ChatEventPayload[E]) => void

export async function runRealChat(
  text: string,
  emit: Emit,
  options: RunOptions = {},
): Promise<void> {
  const { sessionId, signal, history = [], clarifyCount = 0 } = options

  let resp: Response
  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
    }
    // 带登录态：后端据此把记忆归到 u:{userId}，工具也才能拿到用户身份
    const token = getToken()
    if (token) headers['Authorization'] = 'Bearer ' + token
    resp = await fetch('/v1/chat', {
      method: 'POST',
      headers,
      body: JSON.stringify({ message: text, sessionId, history, clarifyCount }),
      signal,
    })
  } catch (err) {
    throw new Error(
      `连不上后端（:8080），确认 Java 服务在跑。原始错误：${err instanceof Error ? err.message : String(err)}`,
    )
  }

  if (!resp.ok || !resp.body) {
    throw new Error(`后端返回 ${resp.status}，检查 Java 控制台日志`)
  }

  const reader = resp.body.getReader()
  const decoder = new TextDecoder()
  let buf = ''
  let event: ChatEventName | 'message' = 'message'
  let data: string[] = []

  const flush = () => {
    if (!data.length) {
      event = 'message'
      return
    }
    const raw = data.join('\n')
    let payload: unknown
    try {
      payload = JSON.parse(raw)
    } catch {
      payload = { text: raw }
    }
    if (event !== 'message') {
      emit(event, payload as never)
    }
    event = 'message'
    data = []
  }

  for (;;) {
    const { done, value } = await reader.read()
    if (done) break
    // 残帧必须留在 buf 里，否则中文字符被切在 chunk 边界上会变乱码
    buf += decoder.decode(value, { stream: true })
    let idx: number
    while ((idx = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, idx).replace(/\r$/, '')
      buf = buf.slice(idx + 1)
      if (line === '') {
        flush()
        continue
      }
      if (line.startsWith(':')) continue
      const colon = line.indexOf(':')
      const field = colon < 0 ? line : line.slice(0, colon)
      const val = colon < 0 ? '' : line.slice(colon + 1).replace(/^ /, '')
      if (field === 'event') event = val as ChatEventName
      else if (field === 'data') data.push(val)
    }
  }
  flush()
}
