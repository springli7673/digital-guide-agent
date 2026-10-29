/** 流式阶段的进度提示：理解需求 → 筛库 → 打分 → 组织话术 */
const STEPS = {
  parsing: '理解需求',
  searching: '检索候选',
  scoring: '参数打分',
  answering: '组织话术',
}

const StreamingStatus = {
  name: 'StreamingStatus',
  props: {
    status: { type: Object, required: true },
  },
  computed: {
    order() {
      return Object.keys(STEPS)
    },
    current() {
      return this.order.indexOf(this.status.stage)
    },
  },
  template: `
    <div class="status">
      <span class="spinner"></span>
      <span class="status-text">{{ status.text }}</span>
      <span class="steps">
        <i v-for="(label, key, i) in STEPS" :key="key"
           :class="{ done: i < current, active: i === current }">{{ label }}</i>
      </span>
    </div>
  `,
  setup() {
    return { STEPS }
  },
}

export default StreamingStatus
