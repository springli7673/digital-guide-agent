/**
 * 外壳：左侧目录 + 右侧内容。
 * 点「手机商城」→ 品牌栏 + 商品网格；点「智能客服」→ 只有聊天主区，没有顶部品牌栏。
 */
import { onMounted } from '../vue.js'
import { EXAMPLES, refreshBackend, send, setView, state } from '../store.js'
import SideMenu from './SideMenu.js'
import ShopPage from './ShopPage.js'
import ChatPage from './ChatPage.js'

const App = {
  name: 'App',
  components: { SideMenu, ShopPage, ChatPage },
  setup() {
    function select(view) {
      setView(view)
    }

    function reload() {
      location.reload()
    }

    onMounted(() => {
      refreshBackend()
      // ?demo=1 直接进客服页跑一遍示例，方便截图和演示
      if (/[?&]demo=1/.test(location.search)) {
        setView('chat')
        setTimeout(() => send(EXAMPLES[0]), 400)
      }
    })

    return { state, select, reload }
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
        <ShopPage v-if="state.view === 'shop'" />
        <ChatPage v-else />
      </div>
    </div>
  `,
}

export default App
