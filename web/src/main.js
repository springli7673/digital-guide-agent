import { createApp } from './vue.js'
import App from './components/App.js'
import { state } from './store.js'

const app = createApp(App)

// 渲染期 / 生命周期里抛的异常默认只会打到 console，界面就"卡住"了。
// 这里统一接住并显示到页面顶部，避免再出现"一直转圈但不知道为什么"。
app.config.errorHandler = (err, instance, info) => {
  console.error('[vue]', info, err)
  const message = err && err.message ? err.message : String(err)
  state.fatalError = `前端异常（${info}）：${message}`
}

window.addEventListener('unhandledrejection', (event) => {
  console.error('[promise]', event.reason)
  const reason = event.reason
  state.fatalError = `未捕获的异常：${reason && reason.message ? reason.message : String(reason)}`
})

app.mount('#app')
