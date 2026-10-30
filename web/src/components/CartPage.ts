/** 购物车页：数量增减、删除、合计、结算 */
import { computed } from '../vue.js'
import {
  buyNow,
  changeQty,
  clearLastOrder,
  isLoggedIn,
  refreshCart,
  removeItem,
  shop,
} from '../shopState.js'
import { setView } from '../store.js'

const CartPage = {
  name: 'CartPage',
  setup() {
    const items = computed(() => (shop.cart ? shop.cart.items : []))
    const total = computed(() => (shop.cart ? shop.cart.total : 0))
    const totalQty = computed(() => (shop.cart ? shop.cart.totalQty : 0))
    const empty = computed(() => items.value.length === 0)
    const loggedIn = computed(() => isLoggedIn())

    const totalText = computed(() => '¥' + Number(total.value).toLocaleString('zh-CN'))
    const orderText = computed(() => {
      const order = shop.lastOrder
      if (!order) return ''
      return '下单成功：' + order.orderNo + '，合计 ¥' + Number(order.totalAmount).toLocaleString('zh-CN')
    })

    function dec(line) {
      if (line.qty <= 1) return
      changeQty(line.cartId, line.qty - 1)
    }

    function inc(line) {
      if (line.qty >= 99) return
      changeQty(line.cartId, line.qty + 1)
    }

    function goShop() {
      setView('shop')
    }

    function goLogin() {
      setView('login')
    }

    function checkout() {
      clearLastOrder()
      buyNow()
    }

    return {
      shop, items, totalText, totalQty, empty, loggedIn, orderText,
      refreshCart, removeItem, dec, inc, goShop, goLogin, checkout,
    }
  },
  template: `
    <section class="cart-page">
      <div class="cart-head">
        <h2>购物车</h2>
        <span class="cart-count" v-if="!empty">{{ totalQty }} 件</span>
      </div>

      <div class="cart-empty" v-if="!loggedIn">
        <p>登录后才能用购物车。</p>
        <button class="btn-primary" @click="goLogin">去登录</button>
      </div>

      <div class="cart-empty" v-else-if="empty">
        <p>购物车是空的。</p>
        <button class="btn-primary" @click="goShop">去逛逛</button>
      </div>

      <template v-else>
        <ul class="cart-list">
          <li class="cart-row" v-for="line in items" :key="line.cartId">
            <div class="cart-thumb">
              <img v-if="line.imageUrl" :src="line.imageUrl" :alt="line.model" />
              <span v-else>{{ line.brand }}</span>
            </div>
            <div class="cart-info">
              <p class="cart-model">{{ line.brand }} {{ line.model }}</p>
              <p class="cart-price">
                ¥{{ Number(line.price).toLocaleString('zh-CN') }}
                <em v-if="line.priceChanged">价格有变动</em>
              </p>
            </div>
            <div class="cart-qty">
              <button @click="dec(line)" :disabled="line.qty <= 1">−</button>
              <span>{{ line.qty }}</span>
              <button @click="inc(line)" :disabled="line.qty >= 99">+</button>
            </div>
            <div class="cart-subtotal">¥{{ Number(line.subtotal).toLocaleString('zh-CN') }}</div>
            <button class="cart-del" @click="removeItem(line.cartId)">删除</button>
          </li>
        </ul>

        <div class="cart-foot">
          <span class="cart-total">合计 {{ totalText }}</span>
          <button class="btn-primary" @click="checkout" :disabled="shop.busy">
            {{ shop.busy ? '提交中…' : '结算' }}
          </button>
        </div>
      </template>

      <p class="cart-ok" v-if="orderText">{{ orderText }}</p>
      <p class="cart-error" v-if="shop.error">{{ shop.error }}</p>
    </section>
  `,
}

export default CartPage
