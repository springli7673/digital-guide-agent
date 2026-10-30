<script setup lang="ts">
/**
 * 参数对比表。
 * 行由 SPEC_SCHEMA 决定（和后端类目权重同源），某一行所有候选都缺数据就整行不显示，
 * 每行把最优值高亮出来。
 */
import { computed } from 'vue'
import { SPEC_SCHEMA } from '@/spec'
import type { Candidate } from '@/types'

const props = defineProps<{ items: Candidate[] }>()

interface Row {
  key: string
  label: string
  unit: string
  cells: Array<number | null>
  best: number
  count: number
}

function valueOf(item: Candidate, key: string): number | null {
  // 参考价不在 metrics 里，单独取。
  // 用 unknown 接住：后端可能返回空串，这里要按"缺失"处理，
  // 但 TS 会把 number 与 '' 的比较判成不可能发生（TS2367）。
  const raw: unknown = key === 'priceRef' ? item.priceRef : item.metrics?.[key]
  if (raw === undefined || raw === null || raw === '') return null
  const n = Number(raw)
  return Number.isFinite(n) ? n : null
}

const columns = computed(() =>
  props.items.map((it) => ({
    id: it.id,
    name: `${it.brand} ${it.model}`,
    price: it.priceRef === null || it.priceRef === undefined
      ? '暂无报价'
      : '¥' + Number(it.priceRef).toLocaleString('zh-CN'),
  })),
)

const rows = computed<Row[]>(() => {
  const out: Row[] = []
  for (const dim of SPEC_SCHEMA) {
    const cells = props.items.map((it) => valueOf(it, dim.key))
    const present = cells.filter((c): c is number => c !== null)
    if (!present.length) continue
    const best = dim.better === 'lower' ? Math.min(...present) : Math.max(...present)
    out.push({ key: dim.key, label: dim.label, unit: dim.unit, cells, best, count: present.length })
  }
  return out
})

/** 只有该行的最优值、且这行不止一个型号有数据时才高亮 */
function isBest(value: number | null, row: Row): boolean {
  return value !== null && row.count > 1 && value === row.best
}
</script>

<template>
  <section v-if="items.length" class="compare">
    <header class="compare-head">
      <h3>参数对比</h3>
      <span class="muted">共 {{ items.length }} 款 · 高亮为该项最优</span>
    </header>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th class="dim">参数</th>
            <th v-for="c in columns" :key="c.id">{{ c.name }}</th>
          </tr>
        </thead>
        <tbody>
          <tr class="price-row">
            <td class="dim">参考价</td>
            <td v-for="c in columns" :key="c.id">{{ c.price }}</td>
          </tr>
          <tr v-for="row in rows" :key="row.key">
            <td class="dim">{{ row.label }}</td>
            <td
              v-for="(v, i) in row.cells"
              :key="i"
              :class="{ best: isBest(v, row) }"
            >
              {{ v === null ? '—' : v }}<small v-if="v !== null" class="unit">{{ row.unit }}</small>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>

<style scoped>
.compare {
  margin-top: 18px;
}

.compare-head {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin-bottom: 8px;
}

.compare-head h3 {
  margin: 0;
  font-size: 14px;
  font-weight: 700;
}

.table-wrap {
  overflow-x: auto;
  border: 1px solid var(--dg-border);
  border-radius: 12px;
  background: var(--dg-card);
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

th,
td {
  padding: 9px 12px;
  text-align: left;
  white-space: nowrap;
  border-bottom: 1px solid var(--dg-border);
}

thead th {
  background: #fafafb;
  font-weight: 600;
  color: var(--dg-text-2);
}

tbody tr:last-child td {
  border-bottom: none;
}

.dim {
  color: var(--dg-text-3);
  font-weight: 500;
}

.price-row td {
  font-weight: 700;
  color: var(--dg-text);
}

td.best {
  color: var(--dg-primary);
  font-weight: 700;
  background: var(--el-color-primary-light-9);
}

.unit {
  color: var(--dg-text-3);
  font-weight: 400;
  margin-left: 1px;
}
</style>
