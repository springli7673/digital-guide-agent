/** 推荐卡片：型号、参考价、得分、命中理由、关键参数 */
const ProductCard = {
  name: 'ProductCard',
  props: {
    item: { type: Object, required: true },
    rank: { type: Number, default: 1 },
    selected: { type: Boolean, default: false },
  },
  emits: ['toggle'],
  computed: {
    priceText() {
      const p = this.item.priceRef
      if (p === null || p === undefined) return '暂无报价'
      return '¥' + Number(p).toLocaleString('zh-CN')
    },
    chips() {
      const m = this.item.metrics || {}
      const out = []
      if (m.battery_mah) out.push(m.battery_mah + 'mAh')
      if (m.charge_w) out.push(m.charge_w + 'W 快充')
      if (m.rear_mp) out.push(m.rear_mp + ' 万主摄')
      if (m.weight_g) out.push(m.weight_g + 'g')
      return out
    },
  },
  template: `
    <article class="card" :class="{ on: selected }" @click="$emit('toggle', item.id)">
      <header class="card-head">
        <span class="rank">NO.{{ rank }}</span>
        <span class="score"><b>{{ item.score }}</b><small>分</small></span>
      </header>
      <h3 class="card-title">{{ item.brand }} {{ item.model }}</h3>
      <p class="card-price">{{ priceText }} <small>参考价</small></p>
      <ul class="card-reasons">
        <li v-for="(r, i) in item.reasons" :key="i">{{ r }}</li>
      </ul>
      <div class="card-chips">
        <span v-for="c in chips" :key="c">{{ c }}</span>
      </div>
      <div class="card-pick">{{ selected ? '✓ 已加入对比' : '加入对比' }}</div>
    </article>
  `,
}

export default ProductCard
