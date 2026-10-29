/** 左侧目录：手机商城 / 智能客服。样式照 Element Plus 的 menu 做（激活项蓝色左边条） */
const SideMenu = {
  name: 'SideMenu',
  props: {
    current: { type: String, default: 'shop' },
    total: { type: Number, default: 0 },
    javaOnline: { type: Boolean, default: false },
  },
  emits: ['select'],
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
        <button class="menu-item" :class="{ active: current === 'chat' }" @click="$emit('select', 'chat')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 5h16v10.5H9.5L4 19.5V5z" />
            <path d="M8.5 10h7" />
          </svg>
          <span>智能客服</span>
        </button>
      </nav>

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
