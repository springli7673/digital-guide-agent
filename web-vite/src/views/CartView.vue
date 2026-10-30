<script setup lang="ts">
/** 购物车页：数量增减、删除、合计、结算；未登录给出明确入口 */
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useShopStore } from '@/stores/shopStore'
import type { CartLine } from '@/api/client'

const shop = useShopStore()
const router = useRouter()

const items = computed<CartLine[]>(() => shop.cart?.items ?? [])
const empty = computed(() => items.value.length === 0)
const totalText = computed(() => '¥' + Number(shop.cartTotal).toLocaleString('zh-CN'))

const orderText = computed(() => {
  const order = shop.lastOrder
  if (!order) return ''
  return `下单成功：${order.orderNo}，合计 ¥${Number(order.totalAmount).toLocaleString('zh-CN')}`
})

function dec(line: CartLine): void {
  if (line.qty <= 1) return
  void shop.changeQty(line.cartId, line.qty - 1)
}

function inc(line: CartLine): void {
  if (line.qty >= 99) return
  void shop.changeQty(line.cartId, line.qty + 1)
}

async function onRemove(id: number): Promise<void> {
  await shop.removeItem(id)
  ElMessage.success('已删除')
}

async function onCheckout(): Promise<void> {
  shop.clearLastOrder()
  const order = await shop.checkout()
  if (order) ElMessage.success(`下单成功：${order.orderNo}`)
  else if (shop.error) ElMessage.error(shop.error)
}
</script>

<template>
  <div class="cart">
    <div class="page-head">
      <h2>购物车</h2>
      <span v-if="!empty" class="muted">{{ shop.cartCount }} 件</span>
    </div>

    <el-alert v-if="!shop.loggedIn" type="info" :closable="false" class="tip">
      <template #title>
        <div class="tip-row">
          <span>登录后才能用购物车。</span>
          <el-button type="primary" size="small" @click="router.push('/login')">去登录</el-button>
        </div>
      </template>
    </el-alert>

    <template v-else>
      <el-empty v-if="empty" description="购物车是空的。">
        <el-button type="primary" @click="router.push('/mall')">去逛逛</el-button>
      </el-empty>

      <template v-else>
        <el-table :data="items" class="table" row-key="cartId">
          <el-table-column label="商品" min-width="260">
            <template #default="{ row }">
              <div class="cell-goods">
                <div class="thumb">
                  <img v-if="row.imageUrl" :src="row.imageUrl" :alt="row.model" />
                  <span v-else>{{ row.brand }}</span>
                </div>
                <div>
                  <p class="model">{{ row.brand }} {{ row.model }}</p>
                  <p class="price">
                    ¥{{ Number(row.price).toLocaleString('zh-CN') }}
                    <em v-if="row.priceChanged">价格有变动</em>
                  </p>
                </div>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="数量" width="150">
            <template #default="{ row }">
              <el-input-number
                :model-value="row.qty"
                :min="1"
                :max="99"
                size="small"
                controls-position="right"
                @change="(v: number) => shop.changeQty(row.cartId, v)"
              />
            </template>
          </el-table-column>

          <el-table-column label="小计" width="140" align="right">
            <template #default="{ row }">
              <span class="subtotal">¥{{ Number(row.subtotal).toLocaleString('zh-CN') }}</span>
            </template>
          </el-table-column>

          <el-table-column label="操作" width="90" align="center">
            <template #default="{ row }">
              <el-button link type="danger" size="small" @click="onRemove(row.cartId)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div class="foot">
          <span class="total">合计 {{ totalText }}</span>
          <el-button type="primary" size="large" :loading="shop.busy" @click="onCheckout">
            结算
          </el-button>
        </div>
      </template>
    </template>

    <el-alert v-if="orderText" :title="orderText" type="success" :closable="false" class="ok" />
    <el-alert v-if="shop.error" :title="shop.error" type="error" :closable="false" class="ok" />
  </div>
</template>

<style scoped>
.tip,
.ok {
  margin-bottom: 14px;
}

.tip-row {
  display: flex;
  align-items: center;
  gap: 14px;
}

.table {
  border-radius: var(--dg-radius);
  overflow: hidden;
  box-shadow: var(--dg-shadow);
}

.cell-goods {
  display: flex;
  align-items: center;
  gap: 12px;
}

.thumb {
  width: 54px;
  height: 54px;
  border-radius: 8px;
  background: #fafafb;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex: none;
  font-size: 12px;
  color: var(--dg-text-3);
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.model {
  margin: 0 0 4px;
  font-size: 14px;
  font-weight: 600;
}

.price {
  margin: 0;
  font-size: 13px;
  color: var(--dg-primary);
}

.price em {
  font-style: normal;
  font-size: 11px;
  color: #f0a020;
  margin-left: 6px;
}

.subtotal {
  font-weight: 700;
}

.foot {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 18px;
  margin-top: 18px;
}

.total {
  font-size: 16px;
  font-weight: 700;
  color: var(--dg-primary);
}
</style>
