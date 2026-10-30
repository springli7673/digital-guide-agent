/** 左侧目录：手机商城 / 购物车 / 智能客服 / 登录。样式照 Element Plus 的 menu 做（激活项蓝色左边条） */
import { computed } from '../vue.js'
import { doLogout, shop } from '../shopState.js'

const SideMenu = {
  name: 'SideMenu',
  props: {
    current: { type: String, default: 'shop' },
    total: { type: Number, default: 0 },
    javaOnline: { type: Boolean, default: false },
  },
  emits: ['select'],
  setup() {
    const cartCount = computed(() => (shop.cart ? shop.cart.totalQty : 0))
    const userText = computed(() => (shop.user ? shop.user.nickname || shop.user.username : ''))
    const loggedIn = computed(() => shop.user !== null)
    function logout() {
      doLogout()
    }
    return { shop, cartCount, userText, loggedIn, logout }
  },
  template: `
    <aside class="sidebar">
      <div class="side-brand">
        <div class="logo">DG</div>
        <div class="side-brand-text">
          <b>数码导购</b>
          <span>digital guide</span>
        </div>
      </div>

      <nav class="side-menu">
        <button class="menu-item" :class="{ active: current === 'shop' }" @click="$emit('select', 'shop')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round">
            <rect x="6.5" y="2.5" width="11" height="19" rx="2.5" />
            <path d="M10.5 18.5h3" />
          </svg>
          <span>手机商城</span>
        </button>

        <button class="menu-item" :class="{ active: current === 'cart' }" @click="$emit('select', 'cart')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 4h2l2.2 10.2a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.6L20.5 7H6" />
            <circle cx="9.5" cy="19" r="1.4" />
            <circle cx="17" cy="19" r="1.4" />
          </svg>
          <span>购物车</span>
          <em class="menu-badge" v-if="cartCount > 0">{{ cartCount }}</em>
        </button>

        <button class="menu-item" :class="{ active: current === 'chat' }" @click="$emit('select', 'chat')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 5h16v10.5H9.5L4 19.5V5z" />
            <path d="M8.5 10h7" />
          </svg>
          <span>智能客服</span>
        </button>

        <button v-if="!loggedIn" class="menu-item" :class="{ active: current === 'login' }" @click="$emit('select', 'login')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 4h4v16h-4" />
            <path d="M10 8l4 4-4 4" />
            <path d="M3 12h11" />
          </svg>
          <span>登录 / 注册</span>
        </button>
      </nav>

      <div class="side-user" v-if="loggedIn">
        <span>已登录：<b>{{ userText }}</b></span>
        <button @click="logout">退出</button>
      </div>

      <div class="side-foot">
        <div class="side-stat">
          <span class="dot" :class="javaOnline ? 'ok' : 'bad'"></span>
          {{ javaOnline ? total + ' 款在售' : '后端未连接' }}
        </div>
        <p>型号与价格来自数据库<br />模型只做解释，不编造</p>
      </div>
    </aside>
  `,
}

export default SideMenu
