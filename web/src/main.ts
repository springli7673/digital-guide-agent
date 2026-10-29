/**
 * 入口：挂载 + 兜底错误显示（TypeScript 版）。
 *
 * 渲染期异常默认只打 console，界面就"卡住"了；这里统一接住并显示在页面顶部，
 * 避免再出现"一直转圈但不知道为什么"。
 */
import { createApp } from './vue.js'
import App from './components/App.js'
import { state } from './store.js'

const app = createApp(App)

app.config.errorHandler = (err: unknown, _instance: unknown, info: string) => {
  console.error('[vue]', info, err)
  const message = err instanceof Error ? err.message : String(err)
  state.fatalError = `前端异常（${info}）：${message}`
}

window.addEventListener('unhandledrejection', (event: PromiseRejectionEvent) => {
  console.error('[promise]', event.reason)
  const reason = event.reason
  state.fatalError = `未捕获的异常：${reason instanceof Error ? reason.message : String(reason)}`
})

app.mount('#app')
