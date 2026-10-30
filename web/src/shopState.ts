/**
 * 商城侧状态与动作（登录 / 购物车 / 待确认下单）。
 *
 * 为什么单独一个 reactive 对象而不是塞进 store.state：
 * 会话状态（聊天）和商城状态（购物车）生命周期完全不同——
 * 换用户时要清的是购物车，不是聊天记录。分开更好维护。
 */
import { reactive } from './vue.js'
import * as api from './api.js'
import type { Cart, Order, PendingAction, UserProfile } from './api.js'

export interface ShopState {
  user: UserProfile | null
  cart: Cart | null
  pending: PendingAction | null
  /** 最近一次下单成功的结果，用于显示"购买成功" */
  lastOrder: Order | null
  busy: boolean
  error: string
  /** 未登录时点加购：记下要做什么，登录后自动重放 */
  pendingIntent: { productId: number; qty: number } | null
}

export const shop = reactive<ShopState>({
  user: null,
  cart: null,
  pending: null,
  lastOrder: null,
  busy: false,
  error: '',
  pendingIntent: null,
})

export function isLoggedIn(): boolean {
  return shop.user !== null
}

/** 启动时尝试用已存的 token 恢复登录态（失败就当没登录，不打扰用户） */
export async function restoreSession(): Promise<void> {
  if (!api.getToken()) return
  try {
    shop.user = await api.me()
    await refreshCart()
  } catch {
    shop.user = null
  }
}

export async function doLogin(username: string, password: string): Promise<void> {
  shop.error = ''
  shop.busy = true
  try {
    const resp = await api.login(username, password)
    api.setToken(resp.token)
    shop.user = await api.me()
    await refreshCart()
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
    throw e
  } finally {
    shop.busy = false
  }
}

export async function doRegister(username: string, password: string, nickname: string): Promise<void> {
  shop.error = ''
  shop.busy = true
  try {
    const resp = await api.register(username, password, nickname)
    api.setToken(resp.token)
    shop.user = await api.me()
    await refreshCart()
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
    throw e
  } finally {
    shop.busy = false
  }
}

export async function doLogout(): Promise<void> {
  try {
    await api.logout()
  } catch {
    // 服务端删不掉也不影响本地登出
  }
  api.setToken('')
  shop.user = null
  shop.cart = null
  shop.pending = null
  shop.lastOrder = null
}

export async function refreshCart(): Promise<void> {
  if (!isLoggedIn()) return
  try {
    shop.cart = await api.getCart()
  } catch {
    shop.cart = null
  }
}

/**
 * 加购物车。
 * 未登录时**不报错**，而是把意图记下来，等用户登录后自动重放——
 * 否则用户点一下加购就被弹去登录，回来还得再点一次。
 */
export async function addToCart(productId: number, qty = 1): Promise<void> {
  shop.error = ''
  if (!isLoggedIn()) {
    shop.pendingIntent = { productId, qty }
    shop.error = '加购物车需要先登录'
    return
  }
  try {
    shop.cart = await api.addToCart(productId, qty)
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
  }
}

/** 登录成功后调用：把登录前攒下的那个加购动作补上 */
export async function replayPendingIntent(): Promise<void> {
  const intent = shop.pendingIntent
  if (!intent) return
  shop.pendingIntent = null
  try {
    shop.cart = await api.addToCart(intent.productId, intent.qty)
  } catch {
    // 重放失败就算了，用户看到购物车为空自然会再点
  }
}

export async function changeQty(cartId: number, qty: number): Promise<void> {
  try {
    shop.cart = await api.updateCartQty(cartId, qty)
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
  }
}

export async function removeItem(cartId: number): Promise<void> {
  try {
    shop.cart = await api.removeCartItem(cartId)
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
  }
}

/** 立即购买：直接下单（幂等键每次点生成一次） */
export async function buyNow(): Promise<void> {
  shop.error = ''
  shop.lastOrder = null
  if (!isLoggedIn()) {
    shop.error = '下单需要先登录'
    return
  }
  shop.busy = true
  try {
    const idem = 'web-' + Date.now() + '-' + Math.random().toString(16).slice(2, 8)
    shop.lastOrder = await api.placeOrder(idem)
    await refreshCart()
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
  } finally {
    shop.busy = false
  }
}

/** 聊天结束后查一次待确认动作 */
export async function loadPending(): Promise<void> {
  if (!isLoggedIn()) {
    shop.pending = null
    return
  }
  try {
    shop.pending = await api.getPending()
  } catch {
    shop.pending = null
  }
}

/** 用户点"确认下单"——这是 agent 提议之后唯一真正写单的入口 */
export async function confirmPending(): Promise<void> {
  if (!shop.pending) return
  shop.error = ''
  shop.busy = true
  try {
    shop.lastOrder = await api.confirmOrder(shop.pending.confirmId)
    shop.pending = null
    await refreshCart()
  } catch (e) {
    shop.error = e instanceof Error ? e.message : String(e)
  } finally {
    shop.busy = false
  }
}

export function dismissPending(): void {
  shop.pending = null
}

export function clearLastOrder(): void {
  shop.lastOrder = null
}
