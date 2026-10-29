/**
 * 一条消息气泡。用户消息只显示文本；
 * 助手消息额外承载：结构化意图回显、追问选项、错误提示、耗时。
 */
const MessageBubble = {
  name: 'MessageBubble',
  props: {
    msg: { type: Object, required: true },
  },
  emits: ['pick'],
  computed: {
    budgetText() {
      const b = this.msg.intent?.budget
      if (!b) return ''
      if (b.min && b.max) return `¥${b.min}–${b.max}`
      if (b.max) return `≤¥${b.max}`
      if (b.min) return `≥¥${b.min}`
      return '不限预算'
    },
  },
  template: `
    <div class="msg" :class="msg.role">
      <div class="avatar">{{ msg.role === 'user' ? '你' : 'AI' }}</div>
      <div class="bubble">
        <div v-if="msg.intent" class="intent">
          <span class="itag cat">{{ msg.intent.categoryLabel }}</span>
          <span v-if="budgetText" class="itag">{{ budgetText }}</span>
          <span v-for="p in msg.intent.prefs" :key="p.key" class="itag pref">{{ p.label }}</span>
          <span v-for="b in msg.intent.brands" :key="b" class="itag">{{ b }}</span>
        </div>

        <p v-if="msg.text" class="text">{{ msg.text }}<span v-if="msg.streaming" class="caret"></span></p>
        <p v-else-if="msg.streaming" class="text thinking">
          <span class="dot"></span><span class="dot"></span><span class="dot"></span>
        </p>

        <div v-if="msg.clarify" class="clarify">
          <p class="q">{{ msg.clarify.question }}</p>
          <div class="chips">
            <button v-for="o in msg.clarify.options" :key="o" @click="$emit('pick', o)">{{ o }}</button>
          </div>
        </div>

        <p v-if="msg.error" class="err">{{ msg.error }}</p>
        <p v-if="msg.latency" class="meta">{{ msg.latency }} ms</p>
      </div>
    </div>
  `,
}

export default MessageBubble
