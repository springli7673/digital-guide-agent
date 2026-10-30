<script setup lang="ts">
/**
 * 智能客服页：左边对话，右边推荐结果（卡片 + 参数对比表）。
 * 流式事件由 chatStore 消费，这里只负责渲染与滚动。
 */
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { EXAMPLES, useChatStore } from '@/stores/chatStore'
import MessageBubble from '@/components/MessageBubble.vue'
import StreamingStatus from '@/components/StreamingStatus.vue'
import RecommendCard from '@/components/RecommendCard.vue'
import CompareTable from '@/components/CompareTable.vue'

const chat = useChatStore()
const draft = ref('')
const scroller = ref<HTMLElement | null>(null)

const lastText = computed(() => {
  const last = chat.messages[chat.messages.length - 1]
  return last ? last.text.length : 0
})

function scrollDown(): void {
  void nextTick(() => {
    const el = scroller.value
    if (el) el.scrollTop = el.scrollHeight
  })
}

function submit(): void {
  const text = draft.value
  if (!text.trim() || chat.busy) return
  draft.value = ''
  void chat.send(text)
}

function useExample(text: string): void {
  draft.value = text
}

function pick(text: string): void {
  void chat.send(text)
}

watch(() => chat.messages.length, scrollDown)
watch(lastText, scrollDown)

onMounted(() => {
  chat.init()
  scrollDown()
})
</script>

<template>
  <div class="chat-page">
    <section class="chat panel-soft">
      <header class="chat-head">
        <div>
          <h2>智能客服</h2>
          <p class="muted">说出预算和偏好，给你 3 款推荐 + 参数对比</p>
        </div>
        <el-button @click="chat.reset()">新会话</el-button>
      </header>

      <div ref="scroller" class="stream">
        <MessageBubble v-for="m in chat.messages" :key="m.id" :msg="m" @pick="pick" />
        <StreamingStatus v-if="chat.status" :status="chat.status" />
      </div>

      <div v-if="chat.showExamples" class="examples">
        <el-button
          v-for="e in EXAMPLES"
          :key="e"
          round
          size="small"
          @click="useExample(e)"
        >{{ e }}</el-button>
      </div>

      <footer class="composer">
        <el-input
          v-model="draft"
          type="textarea"
          :rows="1"
          :autosize="{ minRows: 1, maxRows: 4 }"
          placeholder="例如：预算 3000，想要续航好、拍照好的手机"
          @keydown.enter.exact.prevent="submit"
        />
        <el-button type="primary" :disabled="chat.busy || !draft.trim()" @click="submit">
          {{ chat.busy ? '生成中' : '发送' }}
        </el-button>
      </footer>
    </section>

    <aside class="panel">
      <div v-if="!chat.candidates.length" class="panel-soft empty">
        <h2>推荐对比</h2>
        <p class="muted">说出预算和最看重的点，这里会出现 3 张候选卡片和一张参数对比表。</p>
        <ul class="tips">
          <li><b>硬条件</b>（品类 / 预算 / 品牌）走 SQL 过滤，先筛掉不符合的</li>
          <li><b>软偏好</b>（续航 / 拍照 / 轻薄）按类目配置的权重归一化打分</li>
          <li><b>模型只解释，不生产数据</b>——不会出现库里没有的型号和价格</li>
        </ul>
        <p class="note">价格为电商参考价，非实时成交价。</p>
      </div>

      <div v-else class="panel-soft">
        <header class="panel-head">
          <h2>推荐结果</h2>
          <span class="muted">
            命中 {{ chat.candidateTotal }} 款 · 展示前 {{ chat.candidates.length }}
          </span>
        </header>

        <div class="cards">
          <RecommendCard
            v-for="(it, i) in chat.candidates"
            :key="it.id"
            :item="it"
            :rank="i + 1"
            :selected="chat.selected.includes(it.id)"
            @toggle="chat.toggleSelected"
          />
        </div>

        <CompareTable :items="chat.compareItems" />
        <p class="note">点击卡片可加入/移出对比；得分是候选集内的相对分，不是绝对评分。</p>
      </div>
    </aside>
  </div>
</template>

<style scoped>
.chat-page {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 1fr);
  gap: 18px;
  height: calc(100vh - 48px);
}

.chat {
  display: flex;
  flex-direction: column;
  min-height: 0;
  padding: 16px 18px;
}

.chat-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--dg-border);
}

.chat-head h2 {
  margin: 0 0 4px;
  font-size: 18px;
}

.stream {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 16px 4px 4px;
}

.examples {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  padding: 8px 0 10px;
}

.composer {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  border-top: 1px solid var(--dg-border);
  padding-top: 12px;
}

.composer :deep(.el-textarea__inner) {
  border-radius: 10px;
  resize: none;
}

.panel {
  min-height: 0;
  overflow-y: auto;
}

.panel-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 12px;
}

.panel-head h2 {
  margin: 0;
  font-size: 16px;
}

.empty h2 {
  margin: 0 0 8px;
  font-size: 16px;
}

.tips {
  margin: 12px 0;
  padding-left: 18px;
  font-size: 13px;
  line-height: 1.9;
  color: var(--dg-text-2);
}

.cards {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

@media (max-width: 1100px) {
  .chat-page {
    grid-template-columns: 1fr;
    height: auto;
  }

  .stream {
    max-height: 52vh;
  }
}
</style>
