/** 登录 / 注册页（同一个表单，切换模式） */
import { computed, ref } from '../vue.js'
import { doLogin, doRegister, replayPendingIntent, shop } from '../shopState.js'
import { setView } from '../store.js'

const LoginPage = {
  name: 'LoginPage',
  setup() {
    const mode = ref('login') // 'login' | 'register'
    const username = ref('')
    const password = ref('')
    const nickname = ref('')
    const localError = ref('')

    const isRegister = computed(() => mode.value === 'register')
    const title = computed(() => (isRegister.value ? '注册账号' : '登录'))
    const submitText = computed(() => (isRegister.value ? '注册并登录' : '登录'))
    // 模板里不写 &&：Vue 全局构建在属性表达式中遇到它会编译失败（踩过）
    const showNickname = computed(() => isRegister.value)

    function toggle() {
      mode.value = isRegister.value ? 'login' : 'register'
      localError.value = ''
    }

    async function submit() {
      localError.value = ''
      if (!username.value.trim() || !password.value) {
        localError.value = '用户名和密码都要填'
        return
      }
      try {
        if (isRegister.value) {
          await doRegister(username.value.trim(), password.value, nickname.value.trim())
        } else {
          await doLogin(username.value.trim(), password.value)
        }
        // 登录前攒下的加购动作，登录后自动补上
        await replayPendingIntent()
        setView('shop')
      } catch (e) {
        localError.value = e instanceof Error ? e.message : String(e)
      }
    }

    return { mode, username, password, nickname, localError, isRegister, title, submitText, showNickname, toggle, submit, shop }
  },
  template: `
    <section class="login-wrap">
      <form class="login-card" @submit.prevent="submit">
        <h2>{{ title }}</h2>
        <p class="login-tip">登录后，智能客服会记住你聊过的内容，购物车也会跟着你的账号走。</p>

        <label class="login-field">
          <span>用户名</span>
          <input v-model="username" autocomplete="username" placeholder="3-32 位字母、数字或下划线" />
        </label>
        <label class="login-field">
          <span>密码</span>
          <input v-model="password" type="password" autocomplete="current-password" placeholder="至少 6 位" />
        </label>
        <label class="login-field" v-if="showNickname">
          <span>昵称</span>
          <input v-model="nickname" placeholder="不填就用用户名" />
        </label>

        <p class="login-error" v-if="localError">{{ localError }}</p>

        <button class="btn-primary" type="submit" :disabled="shop.busy">
          {{ shop.busy ? '处理中…' : submitText }}
        </button>
        <button class="btn-link" type="button" @click="toggle">
          {{ isRegister ? '已有账号？去登录' : '没有账号？去注册' }}
        </button>
      </form>
    </section>
  `,
}

export default LoginPage
