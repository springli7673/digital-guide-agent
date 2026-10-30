<script setup lang="ts">
/** 推荐卡片：排名、得分、型号、参考价、命中理由、关键参数；点击切换是否加入对比 */
import { computed } from 'vue'
import { brandStyle } from '@/brandColors'
import type { Candidate } from '@/types'

const props = defineProps<{
  item: Candidate
  rank: number
  selected: boolean
}>()

defineEmits<{ (e: 'toggle', id: number): void }>()

const tag = computed(() => brandStyle(props.item.brand))
const priceText = computed(() => {
  const p = props.item.priceRef
  if (p === null || p === undefined) return '暂无报价'
  return '¥' + Number(p).toLocaleString('zh-CN')
})

const chips = computed(() => {
  const m = props.item.metrics || {}
  const out: string[] = []
  if (m.battery_mah) out.push(m.battery_mah + 'mAh')
  if (m.charge_w) out.push(m.charge_w + 'W 快充')
  if (m.rear_mp) out.push(m.rear_mp + ' 万主摄')
  if (m.weight_g) out.push(m.weight_g + 'g')
  return out
})
</script>

<template>
  <article
    class="rc hover-lift"
    :class="{ on: selected }"
    @click="$emit('toggle', item.id)"
  >
    <header class="rc-head">
      <span class="rc-rank">NO.{{ rank }}</span>
      <span class="rc-score"><b>{{ item.score }}</b><small>分</small></span>
    </header>

    <div class="rc-title-row">
      <span class="brand-tag" :style="{ color: tag.color, background: tag.bg }">{{ item.brand }}</span>
      <h3 class="rc-title">{{ item.model }}</h3>
    </div>

    <p class="rc-price">{{ priceText }} <small class="muted">参考价</small></p>

    <ul class="rc-reasons">
      <li v-for="(r, i) in item.reasons" :key="i">{{ r }}</li>
    </ul>

    <div class="rc-chips">
      <span v-for="c in chips" :key="c">{{ c }}</span>
    </div>

    <div class="rc-pick">{{ selected ? '✓ 已加入对比' : '加入对比' }}</div>
  </article>
</template>

<style scoped>
.rc {
  background: var(--dg-card);
  border: 1px solid var(--dg-border);
  border-radius: var(--dg-radius);
  box-shadow: var(--dg-shadow);
  padding: 12px 14px 10px;
  cursor: pointer;
}

.rc.on {
  border-color: var(--el-color-primary);
  box-shadow: 0 0 0 1px var(--el-color-primary-light-5), var(--dg-shadow);
}

.rc-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.rc-rank {
  font-size: 11px;
  font-weight: 700;
  color: var(--dg-text-3);
  letter-spacing: 0.5px;
}

.rc-score b {
  font-size: 16px;
  color: var(--dg-primary);
}

.rc-score small {
  font-size: 11px;
  color: var(--dg-text-3);
  margin-left: 2px;
}

.rc-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.rc-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.rc-price {
  margin: 0 0 8px;
  font-size: 15px;
  font-weight: 700;
  color: var(--dg-primary);
}

.rc-reasons {
  margin: 0 0 8px;
  padding-left: 16px;
  font-size: 12px;
  line-height: 1.7;
  color: var(--dg-text-2);
}

.rc-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 10px;
}

.rc-chips span {
  background: #f6f7f9;
  color: var(--dg-text-2);
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 6px;
}

.rc-pick {
  border-top: 1px dashed var(--dg-border);
  padding-top: 8px;
  font-size: 12px;
  color: var(--dg-text-3);
  text-align: center;
}

.rc.on .rc-pick {
  color: var(--dg-primary);
  font-weight: 600;
}
</style>
