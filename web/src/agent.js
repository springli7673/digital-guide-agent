/**
 * 与后端 Agent 的对接：消费 POST /v1/chat 的 SSE 流。
 * Agent 已经并入 Java 进程（:8080），不再有独立的 Python 服务。
 *
 * 事件协议（改这里必须同步 backend/.../ai/web/AiChatController.java 与 ai/graph 的节点）：
 *   status     {stage, text}
 *   intent     {category, categoryLabel, budget:{min,max}|null, prefs:[{key,label}], brands:[]}
 *   candidates {total, items:[Recommendation]}
 *   clarify    {question, options:[]}
 *   token      {text}
 *   done       {latencyMs}
 *   error      {msg}
 *
 * 注意不能用 EventSource：它只支持 GET，而我们是 POST + JSON body。
 */

export async function runRealChat(text, emit, { sessionId, signal, history, clarifyCount } = {}) {
  let resp
  try {
    resp = await fetch('/v1/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'text/event-stream' },
      body: JSON.stringify({
        message: text,
        sessionId,
        history: history || [],
        clarifyCount: clarifyCount || 0,
      }),
      signal,
    })
  } catch (err) {
    throw new Error(`连不上后端（:8080），确认 Java 服务在跑。原始错误：${err.message}`)
  }

  if (!resp.ok || !resp.body) {
    throw new Error(`后端返回 ${resp.status}，检查 Java 控制台日志`)
  }

  const reader = resp.body.getReader()
  const decoder = new TextDecoder()
  let buf = ''
  let event = 'message'
  let data = []

  const flush = () => {
    if (data.length) {
      const raw = data.join('\n')
      let payload
      try {
        payload = JSON.parse(raw)
      } catch {
        payload = { text: raw }
      }
      emit(event, payload)
    }
    event = 'message'
    data = []
  }

  for (;;) {
    const { done, value } = await reader.read()
    if (done) break
    // 残帧必须保留在 buf 里，否则中文字符被切在 chunk 边界上会变乱码
    buf += decoder.decode(value, { stream: true })
    let idx
    while ((idx = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, idx).replace(/\r$/, '')
      buf = buf.slice(idx + 1)
      if (line === '') {
        flush()
        continue
      }
      if (line.startsWith(':')) continue
      const c = line.indexOf(':')
      const field = c < 0 ? line : line.slice(0, c)
      const val = c < 0 ? '' : line.slice(c + 1).replace(/^ /, '')
      if (field === 'event') event = val
      else if (field === 'data') data.push(val)
    }
  }
  flush()
}
