/**
 * 手机商城页：品牌栏（header）+ 商品网格（main）+ 分页。
 *
 * 列表接口只返回基础字段，卡片上要显示电池/主摄/主图就得再查详情，
 * 所以对当前页的商品并发拉一次详情。本地接口很快；
 * 正经做法是让后端在列表里带上 metrics 和 image_thumb（见 web/README 待办）。
 */
import { computed, onMounted, ref } from '../vue.js'
import { getProduct, listProducts } from '../api.js'
import ProductTile from './ProductTile.js'

const PAGE_SIZE = 15
// 只上这九个品牌；实际有没有货由后端返回决定
const BRANDS = ['全部', '华为', '小米', '红米', 'OPPO', '一加', 'vivo', 'iQOO', '荣耀', '苹果']

const ShopPage = {
  name: 'ShopPage',
  components: { ProductTile },
  setup() {
    const brand = ref('全部')
    const pageNo = ref(1)
    const total = ref(0)
    const items = ref([])
    const loading = ref(false)
    const error = ref('')

    const pages = computed(() => Math.max(1, Math.ceil(total.value / PAGE_SIZE)))
    // 没有结果且不在加载中，才显示空态（模板里避免写 && 之类的组合条件）
    const showEmpty = computed(() => !loading.value && !error.value)

    /** 页码条：页数多时折叠成 1 … 4 5 6 … 42 */
    const pageList = computed(() => {
      const count = pages.value
      const cur = pageNo.value
      if (count <= 7) {
        return Array.from({ length: count }, (_, i) => i + 1)
      }
      const out = [1]
      const start = Math.max(2, cur - 1)
      const end = Math.min(count - 1, cur + 1)
      if (start > 2) out.push('...')
      for (let i = start; i <= end; i++) out.push(i)
      if (end < count - 1) out.push('...')
      out.push(count)
      return out
    })

    async function load() {
      loading.value = true
      error.value = ''
      try {
        const page = await listProducts({
          category: 'phone',
          brand: brand.value === '全部' ? '' : brand.value,
          page: pageNo.value,
          size: PAGE_SIZE,
        })
        total.value = page.total || 0
        const list = page.list || []
        // 详情用来补 metrics 和主图，失败就退化成没有参数/没有图，不影响列表展示
        const details = await Promise.all(list.map((p) => getProduct(p.id).catch(() => null)))
        items.value = list.map((p, i) => {
          const detail = details[i]
          const specs = (detail && detail.specs) || {}
          return {
            ...p,
            metrics: specs.metrics || {},
            imageThumb: specs.image_thumb || '',
            imageUrl: (detail && detail.imageUrl) || p.imageUrl || '',
          }
        })
      } catch (e) {
        error.value = `加载失败：${e.message}`
        items.value = []
        total.value = 0
      } finally {
        loading.value = false
      }
    }

    function pick(name) {
      if (brand.value === name) return
      brand.value = name
      pageNo.value = 1
      load()
    }

    function go(page) {
      if (typeof page !== 'number') return
      if (page < 1 || page > pages.value || page === pageNo.value) return
      pageNo.value = page
      load()
    }

    onMounted(load)

    return { brand, pageNo, total, items, loading, error, showEmpty, pages, pageList, brands: BRANDS, pick, go }
  },
  template: `
    <div class="page">
      <header class="brandbar">
        <button
          v-for="b in brands"
          :key="b"
          class="brand-chip"
          :class="{ on: brand === b }"
          @click="pick(b)"
        >{{ b }}</button>
      </header>

      <main class="page-main">
        <div class="page-head">
          <h2>手机商城</h2>
          <span class="muted" v-if="!loading">共 {{ total }} 款在售 · 价格为电商参考价</span>
          <span class="muted" v-else>加载中…</span>
        </div>

        <p class="page-error" v-if="error">{{ error }}</p>

        <div class="grid" v-if="items.length">
          <ProductTile v-for="it in items" :key="it.id" :item="it" />
        </div>
        <p class="page-empty" v-else-if="showEmpty">这个品牌暂时没有在售机型。</p>

        <div class="pager" v-if="pages > 1">
          <button class="pg" :disabled="pageNo === 1" @click="go(pageNo - 1)">上一页</button>
          <button
            v-for="(p, i) in pageList"
            :key="i"
            class="pg"
            :class="{ on: p === pageNo, dots: p === '...' }"
            :disabled="p === '...'"
            @click="go(p)"
          >{{ p }}</button>
          <button class="pg" :disabled="pageNo === pages" @click="go(pageNo + 1)">下一页</button>
          <span class="pg-info">第 {{ pageNo }} / {{ pages }} 页</span>
        </div>
      </main>
    </div>
  `,
}

export default ShopPage
