<script setup lang="ts">
/**
 * 一条消息气泡。用户消息只显示文本；
 * 助手消息额外承载：结构化意图回显、追问选项、错误提示、耗时。
 */
import { computed } from 'vue'
import type { ChatMessage } from '@/types'

const props = defineProps<{ msg: ChatMessage }>()
defineEmits<{ (e: 'pick', text: string): void }>()

const isUser = computed(() => props.msg.role === 'user')

const budgetText = computed(() => {
  const b = props.msg.intent?.budget
  if (!b) return ''
  if (b.min && b.max) return `¥${b.min}–${b.max}`
  if (b.max) return `≤¥${b.max}`
  if (b.min) return `≥¥${b.min}`
  return '不限预算'
})
</script>

<template>
  <div class="msg" :class="isUser ? 'user' : 'assistant'">
    <div class="avatar">{{ isUser ? '你' : 'AI' }}</div>

    <div class="bubble">
      <div v-if="msg.intent" class="intent">
        <span class="itag cat">{{ msg.intent.categoryLabel }}</span>
        <span v-if="budgetText" class="itag">{{ budgetText }}</span>
        <span v-for="p in msg.intent.prefs || []" :key="p.key" class="itag pref">{{ p.label }}</span>
        <span v-for="b in msg.intent.brands || []" :key="b" class="itag">{{ b }}</span>
      </div>

      <p v-if="msg.text" class="text">{{ msg.text }}<span v-if="msg.streaming" class="caret" /></p>
      <p v-else-if="msg.streaming" class="text thinking">
        <span class="dot" /><span class="dot" /><span class="dot" />
      </p>

      <div v-if="msg.clarify" class="clarify">
        <p class="q">{{ msg.clarify.question }}</p>
        <div class="chips">
          <el-button
            v-for="o in msg.clarify.options"
            :key="o"
            size="small"
            round
            @click="$emit('pick', o)"
          >{{ o }}</el-button>
        </div>
      </div>

      <p v-if="msg.error" class="err">{{ msg.error }}</p>
      <p v-if="msg.latency" class="meta">{{ msg.latency }} ms</p>
    </div>
  </div>
</template>

<style scoped>
.msg {
  display: flex;
  gap: 10px;
  margin-bottom: 16px;
}

.msg.user {
  flex-direction: row-reverse;
}

.avatar {
  flex: none;
  width: 30px;
  height: 30px;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
}

.assistant .avatar {
  background: var(--el-color-primary-light-9);
  color: var(--dg-primary);
}

.user .avatar {
  background: #eef0f4;
  color: var(--dg-text-2);
}

.bubble {
  max-width: min(680px, 78%);
  background: var(--dg-card);
  border: 1px solid var(--dg-border);
  border-radius: 12px;
  padding: 12px 14px;
  box-shadow: var(--dg-shadow);
}

.user .bubble {
  background: var(--el-color-primary-light-9);
  border-color: var(--el-color-primary-light-7);
}

.intent {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 8px;
}

.itag {
  font-size: 11px;
  padding: 1px 8px;
  border-radius: 6px;
  background: #f4f5f7;
  color: var(--dg-text-2);
}

.itag.cat {
  background: var(--el-color-primary-light-9);
  color: var(--dg-primary);
  font-weight: 600;
}

.itag.pref {
  background: #eef7ff;
  color: #2563eb;
}

.text {
  margin: 0;
  font-size: 14px;
  line-height: 1.75;
  white-space: pre-wrap;
  word-break: break-word;
}

.caret {
  display: inline-block;
  width: 2px;
  height: 14px;
  margin-left: 2px;
  vertical-align: -2px;
  background: var(--dg-primary);
  animation: blink 1s steps(2, start) infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.thinking {
  display: flex;
  gap: 4px;
  align-items: center;
}

.thinking .dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--dg-text-3);
  animation: bounce 1.2s infinite ease-in-out;
}

.thinking .dot:nth-child(2) {
  animation-delay: 0.15s;
}

.thinking .dot:nth-child(3) {
  animation-delay: 0.3s;
}

@keyframes bounce {
  0%, 80%, 100% {
    opacity: 0.3;
    transform: translateY(0);
  }
  40% {
    opacity: 1;
    transform: translateY(-3px);
  }
}

.clarify {
  margin-top: 10px;
  border-top: 1px dashed var(--dg-border);
  padding-top: 8px;
}

.clarify .q {
  margin: 0 0 8px;
  font-size: 13px;
  color: var(--dg-text-2);
}

.clarify .chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.err {
  margin: 8px 0 0;
  font-size: 12px;
  color: #e5484d;
}

.meta {
  margin: 8px 0 0;
  font-size: 11px;
  color: var(--dg-text-3);
}
</style>
