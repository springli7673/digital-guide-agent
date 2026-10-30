/**
 * 外壳：左侧目录 + 右侧内容。
 * 手机商城 → 品牌栏 + 商品网格；购物车 → 结算页；登录 → 账号页；智能客服 → 只有聊天主区。
 *
 * 「待确认下单」的横幅放在这里而不是聊天页：agent 提议后用户可能已经切到别的页，
 * 放在外壳上才不会丢。
 */
import { onMounted } from '../vue.js'
import { EXAMPLES, refreshBackend, send, setView, state } from '../store.js'
import { confirmPending, dismissPending, loadPending, restoreSession, shop } from '../shopState.js'
import { installShopStyles } from '../shopStyle.js'
import SideMenu from './SideMenu.js'
import ShopPage from './ShopPage.js'
import ChatPage from './ChatPage.js'
import CartPage from './CartPage.js'
import LoginPage from './LoginPage.js'

const App = {
  name: 'App',
  components: { SideMenu, ShopPage, ChatPage, CartPage, LoginPage },
  setup() {
    installShopStyles()

    function select(view) {
      setView(view)
    }

    function reload() {
      location.reload()
    }

    onMounted(() => {
      refreshBackend()
      // 用 localStorage 里的 token 恢复登录态，再拉一次待确认动作
      restoreSession().then(() => loadPending())
      if (/[?&]demo=1/.test(location.search)) {
        setView('chat')
        setTimeout(() => send(EXAMPLES[0]), 400)
      }
    })

    return { state, shop, select, reload, confirmPending, dismissPending }
  },
  template: `
    <div class="layout">
      <SideMenu
        :current="state.view"
        :total="state.backend.total"
        :java-online="state.backend.java"
        @select="select"
      />
      <div class="content">
        <div class="fatal" v-if="state.fatalError">
          <span>{{ state.fatalError }}</span>
          <button @click="reload">刷新页面</button>
        </div>

        <!-- agent 只能"提议"，真正下单要用户点这里 -->
        <div class="pending-bar" v-if="shop.pending">
          <span class="pending-text">
            智能客服准备好了订单：{{ shop.pending.summary }}，合计 ¥{{ shop.pending.total }}。
            确认后才会扣库存。
          </span>
          <button class="ok" :disabled="shop.busy" @click="confirmPending">确认下单</button>
          <button class="no" @click="dismissPending">先不买</button>
        </div>

        <ShopPage v-if="state.view === 'shop'" />
        <CartPage v-else-if="state.view === 'cart'" />
        <LoginPage v-else-if="state.view === 'login'" />
        <ChatPage v-else />
      </div>
    </div>
  `,
}

export default App
