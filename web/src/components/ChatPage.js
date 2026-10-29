/**
 * 智能客服页：只有 main，没有顶部品牌栏。
 * 左边对话，右边推荐结果（卡片 + 参数对比表）。
 */
import { computed, nextTick, onMounted, ref, watch } from '../vue.js'
import { EXAMPLES, init, reset, send, state, toggleSelected } from '../store.js'
import MessageBubble from './MessageBubble.js'
import ProductCard from './ProductCard.js'
import CompareTable from './CompareTable.js'
import StreamingStatus from './StreamingStatus.js'

const ChatPage = {
  name: 'ChatPage',
  components: { MessageBubble, ProductCard, CompareTable, StreamingStatus },
  setup() {
    const draft = ref('')
    const scroller = ref(null)

    const compareList = computed(() =>
      state.candidates.filter((c) => state.selected.includes(c.id))
    )
    const showExamples = computed(() => state.messages.length <= 1 && !state.busy)
    const lastText = computed(() => {
      const last = state.messages[state.messages.length - 1]
      return last ? last.text.length : 0
    })

    function scrollDown() {
      nextTick(() => {
        const el = scroller.value
        if (el) el.scrollTop = el.scrollHeight
      })
    }

    function submit() {
      const text = draft.value
      if (!text.trim() || state.busy) return
      draft.value = ''
      send(text)
    }

    function pick(text) {
      send(text)
    }

    function useExample(text) {
      draft.value = text
    }

    watch(() => state.messages.length, scrollDown)
    watch(lastText, scrollDown)

    onMounted(() => {
      if (!state.messages.length) init()
      scrollDown()
    })

    return {
      state,
      draft,
      scroller,
      examples: EXAMPLES,
      compareList,
      showExamples,
      submit,
      pick,
      useExample,
      reset,
      toggleSelected,
    }
  },
  template: `
    <main class="chat-page">
      <section class="chat">
        <header class="chat-head">
          <div class="chat-title">
            <h2>智能客服</h2>
            <p>说出预算和偏好，给你 3 款推荐 + 参数对比</p>
          </div>
          <div class="chat-actions">
            <button class="ghost" @click="reset">新会话</button>
          </div>
        </header>

        <div class="stream" ref="scroller">
          <MessageBubble v-for="m in state.messages" :key="m.id" :msg="m" @pick="pick" />
          <StreamingStatus v-if="state.status" :status="state.status" />
        </div>

        <div class="examples" v-if="showExamples">
          <button v-for="e in examples" :key="e" class="chip" @click="useExample(e)">{{ e }}</button>
        </div>

        <footer class="composer">
          <textarea
            v-model="draft"
            rows="1"
            placeholder="例如：预算 3000，想要续航好、拍照好的手机"
            @keydown.enter.exact.prevent="submit"
          ></textarea>
          <button class="send" :disabled="state.busy || !draft.trim()" @click="submit">
            {{ state.busy ? '生成中' : '发送' }}
          </button>
        </footer>
      </section>

      <aside class="panel">
        <div class="panel-empty" v-if="!state.candidates.length">
          <h2>推荐对比</h2>
          <p>说出预算和最看重的点，这里会出现 3 张候选卡片和一张参数对比表。</p>
          <ul class="tips">
            <li><b>硬条件</b>（品类 / 预算 / 品牌）走 SQL 过滤，先筛掉不符合的</li>
            <li><b>软偏好</b>（续航 / 拍照 / 轻薄）按类目配置的权重归一化打分</li>
            <li><b>模型只解释，不生产数据</b>——不会出现库里没有的型号和价格</li>
          </ul>
          <p class="note">价格为电商参考价，非实时成交价。</p>
        </div>

        <div class="panel-body" v-else>
          <header class="panel-head">
            <h2>推荐结果</h2>
            <span class="muted">命中 {{ state.candidateTotal }} 款 · 展示前 {{ state.candidates.length }}</span>
          </header>
          <div class="cards">
            <ProductCard
              v-for="(it, i) in state.candidates"
              :key="it.id"
              :item="it"
              :rank="i + 1"
              :selected="state.selected.includes(it.id)"
              @toggle="toggleSelected"
            />
          </div>
          <CompareTable :items="compareList" />
          <p class="note">点击卡片可加入/移出对比；得分是候选集内的相对分，不是绝对评分。</p>
        </div>
      </aside>
    </main>
  `,
}

export default ChatPage
