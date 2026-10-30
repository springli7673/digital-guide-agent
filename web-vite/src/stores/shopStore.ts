/**
 * 商城仓库：登录态、购物车、待确认下单。
 *
 * 为什么和 chatStore 分开：生命周期完全不同——
 * 换用户时要清的是购物车，不是聊天记录。
 */
import { defineStore } from 'pinia'
import * as api from '@/api/client'
import type { Cart, Order, PendingAction, UserProfile } from '@/api/client'

interface ShopState {
  user: UserProfile | null
  cart: Cart | null
  pending: PendingAction | null
  /** 最近一次下单成功的结果，用于显示"下单成功" */
  lastOrder: Order | null
  busy: boolean
  error: string
  /** 未登录时点加购：记下要做什么，登录后自动重放 */
  pendingIntent: { productId: number; qty: number } | null
}

export const useShopStore = defineStore('shop', {
  state: (): ShopState => ({
    user: null,
    cart: null,
    pending: null,
    lastOrder: null,
    busy: false,
    error: '',
    pendingIntent: null,
  }),

  getters: {
    loggedIn: (state) => state.user !== null,
    cartCount: (state) => state.cart?.totalQty ?? 0,
    cartTotal: (state) => state.cart?.total ?? 0,
  },

  actions: {
    /** 启动时尝试用已存的 token 恢复登录态（失败就当没登录，不打扰用户） */
    async restoreSession(): Promise<void> {
      if (!api.getToken()) return
      try {
        this.user = await api.me()
        await this.refreshCart()
      } catch {
        this.user = null
      }
    },

    async login(username: string, password: string): Promise<void> {
      this.error = ''
      this.busy = true
      try {
        const resp = await api.login(username, password)
        api.setToken(resp.token)
        this.user = await api.me()
        await this.refreshCart()
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
        throw e
      } finally {
        this.busy = false
      }
    },

    async register(username: string, password: string, nickname: string): Promise<void> {
      this.error = ''
      this.busy = true
      try {
        const resp = await api.register(username, password, nickname)
        api.setToken(resp.token)
        this.user = await api.me()
        await this.refreshCart()
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
        throw e
      } finally {
        this.busy = false
      }
    },

    async logout(): Promise<void> {
      try {
        await api.logout()
      } catch {
        // 服务端删不掉也不影响本地登出
      }
      api.setToken('')
      this.user = null
      this.cart = null
      this.pending = null
      this.lastOrder = null
    },

    async refreshCart(): Promise<void> {
      if (!api.getToken()) return
      try {
        this.cart = await api.getCart()
      } catch {
        this.cart = null
      }
    },

    /**
     * 加购物车。
     * 未登录时不报错，而是把意图记下来，等用户登录后自动重放——
     * 否则用户点一下加购就被弹去登录，回来还得再点一次。
     */
    async addToCart(productId: number, qty = 1): Promise<boolean> {
      this.error = ''
      if (!this.loggedIn) {
        this.pendingIntent = { productId, qty }
        this.error = '加购物车需要先登录'
        return false
      }
      try {
        this.cart = await api.addToCart(productId, qty)
        return true
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
        return false
      }
    },

    /** 登录成功后调用：把登录前攒下的那个加购动作补上 */
    async replayPendingIntent(): Promise<void> {
      const intent = this.pendingIntent
      if (!intent) return
      this.pendingIntent = null
      try {
        this.cart = await api.addToCart(intent.productId, intent.qty)
      } catch {
        // 重放失败就算了，用户看到购物车为空自然会再点
      }
    },

    async changeQty(cartId: number, qty: number): Promise<void> {
      try {
        this.cart = await api.updateCartQty(cartId, qty)
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
      }
    },

    async removeItem(cartId: number): Promise<void> {
      try {
        this.cart = await api.removeCartItem(cartId)
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
      }
    },

    async clearCart(): Promise<void> {
      try {
        this.cart = await api.clearCart()
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
      }
    },

    /** 结算：直接下单（幂等键每次点生成一次） */
    async checkout(): Promise<Order | null> {
      this.error = ''
      this.lastOrder = null
      if (!this.loggedIn) {
        this.error = '下单需要先登录'
        return null
      }
      this.busy = true
      try {
        const idem = 'web-' + Date.now() + '-' + Math.random().toString(16).slice(2, 8)
        this.lastOrder = await api.placeOrder(idem)
        await this.refreshCart()
        return this.lastOrder
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
        return null
      } finally {
        this.busy = false
      }
    },

    /** 聊天结束后查一次待确认动作 */
    async loadPending(): Promise<void> {
      if (!this.loggedIn) {
        this.pending = null
        return
      }
      try {
        this.pending = await api.getPending()
      } catch {
        this.pending = null
      }
    },

    /** 用户点"确认下单"——agent 提议之后唯一真正写单的入口 */
    async confirmPending(): Promise<Order | null> {
      if (!this.pending) return null
      this.error = ''
      this.busy = true
      try {
        this.lastOrder = await api.confirmOrder(this.pending.confirmId)
        this.pending = null
        await this.refreshCart()
        return this.lastOrder
      } catch (e) {
        this.error = e instanceof Error ? e.message : String(e)
        return null
      } finally {
        this.busy = false
      }
    },

    dismissPending(): void {
      this.pending = null
    },

    clearLastOrder(): void {
      this.lastOrder = null
    },
  },
})
