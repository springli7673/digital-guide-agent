<script setup lang="ts">
/** 商城里的一张商品卡片：主图、品牌色标签、型号、容量、关键参数、参考价、两个操作按钮 */
import { computed, ref } from 'vue'
import { brandStyle } from '@/brandColors'
import type { ShopItem } from '@/types'

const props = defineProps<{ item: ShopItem }>()
defineEmits<{ (e: 'add', id: number): void; (e: 'buy', id: number): void }>()

const broken = ref(false)
const thumb = computed(() => props.item.imageThumb || props.item.imageUrl || '')
const showImage = computed(() => Boolean(thumb.value) && !broken.value)
const tag = computed(() => brandStyle(props.item.brand))

const priceText = computed(() => {
  const p = props.item.priceRef
  if (p === null || p === undefined) return '暂无报价'
  return '¥' + Number(p).toLocaleString('zh-CN')
})

/** title 形如「荣耀WIN Turbo2（16GB/512GB）」，把括号里的容量单独拿出来 */
const storage = computed(() => {
  const match = /[（(]([^）)]+)[）)]/.exec(props.item.title || '')
  return match ? match[1] : ''
})

const chips = computed(() => {
  const m = props.item.metrics || {}
  const out: string[] = []
  if (m.battery_mah) out.push(m.battery_mah + 'mAh')
  if (m.charge_w) out.push(m.charge_w + 'W')
  if (m.rear_mp) out.push(m.rear_mp + '万像素')
  if (m.weight_g) out.push(m.weight_g + 'g')
  return out
})
</script>

<template>
  <article class="tile hover-lift">
    <div class="tile-img">
      <img v-if="showImage" :src="thumb" :alt="item.brand + item.model" loading="lazy" @error="broken = true" />
      <span v-else class="tile-fallback">{{ item.brand }}</span>
    </div>

    <div class="tile-top">
      <span class="brand-tag" :style="{ color: tag.color, background: tag.bg }">{{ item.brand }}</span>
      <span class="muted">{{ item.launchDate || '' }}</span>
    </div>

    <h3 class="tile-title">{{ item.brand }} {{ item.model }}</h3>
    <p class="tile-sub" v-if="storage">{{ storage }}</p>

    <div class="tile-chips">
      <span v-for="c in chips" :key="c">{{ c }}</span>
    </div>

    <div class="tile-foot">
      <span class="tile-price">{{ priceText }}</span>
      <small class="muted">参考价</small>
    </div>

    <div class="tile-actions">
      <el-button size="small" @click.stop="$emit('add', item.id)">加入购物车</el-button>
      <el-button size="small" type="primary" @click.stop="$emit('buy', item.id)">立即购买</el-button>
    </div>
  </article>
</template>

<style scoped>
.tile {
  background: var(--dg-card);
  border: 1px solid var(--dg-border);
  border-radius: var(--dg-radius);
  box-shadow: var(--dg-shadow);
  padding: 12px 14px 14px;
  display: flex;
  flex-direction: column;
  cursor: default;
}

.tile-img {
  aspect-ratio: 1 / 1;
  border-radius: 10px;
  background: #fafafb;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  margin-bottom: 10px;
}

.tile-img img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.tile-fallback {
  font-size: 12px;
  color: var(--dg-text-3);
}

.tile-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.tile-title {
  margin: 0 0 4px;
  font-size: 14px;
  font-weight: 600;
  color: var(--dg-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tile-sub {
  margin: 0 0 8px;
  font-size: 12px;
  color: var(--dg-text-3);
}

.tile-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 10px;
}

.tile-chips span {
  background: #f6f7f9;
  color: var(--dg-text-2);
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 6px;
}

.tile-foot {
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin-top: auto;
}

.tile-price {
  font-size: 18px;
  font-weight: 700;
  color: var(--dg-primary);
}

.tile-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--dg-border);
}

.tile-actions :deep(.el-button) {
  flex: 1;
  margin-left: 0;
}
</style>
