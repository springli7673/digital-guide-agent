<script setup lang="ts">
/**
 * 手机商城页：品牌筛选 + 商品网格 + 分页。
 *
 * 列表接口只返回基础字段，卡片上要显示电池/主摄/主图就得再查详情，
 * 所以对当前页的商品并发拉一次详情（本地接口很快）。
 */
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getProduct, listProducts } from '@/api/client'
import ProductCard from '@/components/ProductCard.vue'
import { useShopStore } from '@/stores/shopStore'
import type { ShopItem } from '@/types'

const PAGE_SIZE = 15
// 只上这九个品牌；实际有没有货由后端返回决定
const BRANDS = ['全部', '华为', '小米', '红米', 'OPPO', '一加', 'vivo', 'iQOO', '荣耀', '苹果']

const shop = useShopStore()
const router = useRouter()

const brand = ref('全部')
const pageNo = ref(1)
const total = ref(0)
const items = ref<ShopItem[]>([])
const loading = ref(false)
const error = ref('')

const showEmpty = computed(() => !loading.value && !error.value && items.value.length === 0)

async function load(): Promise<void> {
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
      const specs = (details[i] && details[i]!.specs) || {}
      return {
        ...p,
        metrics: specs.metrics || {},
        imageThumb: specs.image_thumb || '',
        imageUrl: (details[i] && details[i]!.imageUrl) || p.imageUrl || '',
      } as ShopItem
    })
  } catch (e) {
    error.value = `加载失败：${e instanceof Error ? e.message : String(e)}`
    items.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

/**
 * 切换品牌。
 *
 * 注意：这里**不能**再判断 `brand.value === name` 然后提前 return ——
 * `v-model` 已经把 brand 更新成新值了，再比一次永远相等，于是永远不重新请求。
 * （之前的 bug 就是这么来的：高亮变了，列表没变。）
 * `@change` 本身只在新旧值不同时触发，不需要额外的去重判断。
 */
function onBrandChange(name: string | number | boolean | undefined): void {
  brand.value = String(name ?? '全部')
  pageNo.value = 1
  void load()
}

function go(page: number): void {
  if (page < 1 || page === pageNo.value) return
  pageNo.value = page
  load()
}

async function onAdd(id: number): Promise<void> {
  const ok = await shop.addToCart(id, 1)
  if (ok) ElMessage.success('已加入购物车')
  else ElMessage.warning(shop.error || '加入失败')
}

function onBuy(id: number): void {
  // 不在卡片上直接扣库存：先加购，再跳购物车结算
  void shop.addToCart(id, 1)
  void router.push('/cart')
}

onMounted(load)
</script>

<template>
  <div class="mall">
    <el-radio-group v-model="brand" class="brandbar" @change="onBrandChange">
      <el-radio-button v-for="b in BRANDS" :key="b" :value="b">{{ b }}</el-radio-button>
    </el-radio-group>

    <div class="page-head">
      <h2>手机商城</h2>
      <span v-if="!loading" class="muted">共 {{ total }} 款在售 · 价格为电商参考价</span>
      <span v-else class="muted">加载中…</span>
    </div>

    <el-alert v-if="error" :title="error" type="error" :closable="false" class="err" />

    <div v-loading="loading" class="grid">
      <ProductCard
        v-for="it in items"
        :key="it.id"
        :item="it"
        @add="onAdd"
        @buy="onBuy"
      />
    </div>

    <el-empty v-if="showEmpty" description="这个品牌暂时没有在售机型。" />

    <div v-if="total > PAGE_SIZE" class="pager">
      <el-pagination
        layout="prev, pager, next, total"
        :total="total"
        :page-size="PAGE_SIZE"
        :current-page="pageNo"
        background
        @current-change="go"
      />
    </div>
  </div>
</template>

<style scoped>
.brandbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 18px;
}

.brandbar :deep(.el-radio-button__inner) {
  border: 1px solid var(--dg-border);
  border-radius: 8px;
  box-shadow: none;
  color: var(--dg-text-2);
  transition: all var(--dg-transition);
}

.brandbar :deep(.el-radio-button__inner:hover) {
  color: var(--dg-primary);
  border-color: var(--el-color-primary-light-5);
}

.brandbar :deep(.el-radio-button.is-active .el-radio-button__inner) {
  background: var(--dg-primary);
  border-color: var(--dg-primary);
  color: #fff;
  box-shadow: none;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
  gap: 16px;
  min-height: 120px;
}

.err {
  margin-bottom: 12px;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
</style>
