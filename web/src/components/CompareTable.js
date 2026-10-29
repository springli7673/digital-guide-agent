/**
 * 参数对比表。
 * 行由 SPEC_SCHEMA 决定（和后端类目权重同源），某一行所有候选都缺数据就整行不显示，
 * 每行把最优值高亮出来。
 */
import { SPEC_SCHEMA } from '../spec.js'

const CompareTable = {
  name: 'CompareTable',
  props: {
    items: { type: Array, default: () => [] },
  },
  computed: {
    columns() {
      return this.items.map((it) => ({
        id: it.id,
        name: `${it.brand} ${it.model}`,
        price: it.priceRef === null || it.priceRef === undefined
          ? '暂无报价'
          : '¥' + Number(it.priceRef).toLocaleString('zh-CN'),
      }))
    },
    rows() {
      const out = []
      for (const dim of SPEC_SCHEMA) {
        const cells = this.items.map((it) => {
          const v = it.metrics?.[dim.key]
          return v === undefined || v === null || v === '' ? null : Number(v)
        })
        const present = cells.filter((c) => c !== null)
        if (!present.length) continue
        const best = dim.better === 'lower' ? Math.min(...present) : Math.max(...present)
        out.push({ key: dim.key, label: dim.label, unit: dim.unit, cells, best, count: present.length })
      }
      return out
    },
  },
  methods: {
    /** 只有该行的最优值、且这行不止一个型号有数据时才高亮 */
    isBest(value, row) {
      return value !== null && row.count > 1 && value === row.best
    },
  },
  template: `
    <section class="compare" v-if="items.length">
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
              <td v-for="(v, i) in row.cells" :key="i"
                  :class="{ best: isBest(v, row) }">
                {{ v === null ? '—' : v }}<small v-if="v !== null" class="unit">{{ row.unit }}</small>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  `,
}

export default CompareTable
