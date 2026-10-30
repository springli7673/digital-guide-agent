/**
 * Java 后端接口封装（TypeScript 版）。
 *
 * 约定：所有接口返回 {code, msg, data}，code !== 0 视为业务失败。
 * 走同源相对路径，由 server.mjs 反向代理到 :8080，因此没有跨域问题。
 *
 * 鉴权：token 存在 localStorage，请求时自动带 Authorization。
 * 为什么不用 httpOnly cookie：前端是静态托管、后端是另一个端口，
 * 跨源带 cookie 要额外配 SameSite/credentials，为了这点收益不值得。
 */
import type { PageResult, ProductDetail, ProductView } from './types.js'

const TIMEOUT = 8000
const TOKEN_KEY = 'dg_token'

let token = (typeof localStorage !== 'undefined' && localStorage.getItem(TOKEN_KEY)) || ''

export function getToken(): string {
  return token
}

export function setToken(next: string): void {
  token = next || ''
  if (typeof localStorage === 'undefined') return
  if (token) localStorage.setItem(TOKEN_KEY, token)
  else localStorage.removeItem(TOKEN_KEY)
}

interface Envelope<T> {
  code: number
  msg?: string
  data: T
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  timeout?: number
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, timeout = TIMEOUT } = options
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), timeout)
  const headers: Record<string, string> = {}
  if (body) headers['Content-Type'] = 'application/json'
  if (token) headers['Authorization'] = 'Bearer ' + token
  try {
    const resp = await fetch(path, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    })
    if (resp.status === 401) {
      // token 失效：清掉本地状态，让界面回到未登录
      setToken('')
      throw new Error('未登录或登录已过期')
    }
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
    const payload = (await resp.json()) as Envelope<T>
    if (payload && typeof payload.code === 'number' && payload.code !== 0) {
      throw new Error(payload.msg || '接口返回业务错误')
    }
    return payload.data
  } finally {
    clearTimeout(timer)
  }
}

// ------------------------------------------------------------------ 商品

export interface ProductQuery {
  category?: string
  brand?: string
  keyword?: string
  minPrice?: number
  maxPrice?: number
  page?: number
  size?: number
}

/** 商品分页查询：{category, brand, keyword, minPrice, maxPrice, page, size} */
export function listProducts(params: ProductQuery = {}): Promise<PageResult<ProductView>> {
  const qs = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && value !== '') qs.set(key, String(value))
  }
  return request<PageResult<ProductView>>(`/api/products?${qs.toString()}`)
}

/** 商品详情：含 specs.display / specs.metrics / skus */
export function getProduct(id: number): Promise<ProductDetail> {
  return request<ProductDetail>(`/api/products/${id}`)
}

// ------------------------------------------------------------------ 账号

export interface LoginResp {
  token: string
  userId: number
  nickname: string
}

export interface UserProfile {
  id: number
  username: string
  nickname: string
  createdAt: string
}

export function login(username: string, password: string): Promise<LoginResp> {
  return request<LoginResp>('/api/auth/login', { method: 'POST', body: { username, password } })
}

export function register(username: string, password: string, nickname?: string): Promise<LoginResp> {
  return request<LoginResp>('/api/auth/register', {
    method: 'POST',
    body: { username, password, nickname },
  })
}

export function me(): Promise<UserProfile> {
  return request<UserProfile>('/api/auth/me')
}

export function logout(): Promise<void> {
  return request<void>('/api/auth/logout', { method: 'POST' })
}

// ------------------------------------------------------------------ 购物车

export interface CartLine {
  cartId: number
  productId: number
  brand: string
  model: string
  imageUrl: string
  price: number
  qty: number
  subtotal: number
  priceChanged: boolean
}

export interface Cart {
  items: CartLine[]
  total: number
  totalQty: number
}

export function getCart(): Promise<Cart> {
  return request<Cart>('/api/cart')
}

export function addToCart(productId: number, qty = 1): Promise<Cart> {
  return request<Cart>('/api/cart', { method: 'POST', body: { productId, qty } })
}

export function updateCartQty(cartId: number, qty: number): Promise<Cart> {
  return request<Cart>(`/api/cart/${cartId}`, { method: 'PUT', body: { qty } })
}

export function removeCartItem(cartId: number): Promise<Cart> {
  return request<Cart>(`/api/cart/${cartId}`, { method: 'DELETE' })
}

export function clearCart(): Promise<Cart> {
  return request<Cart>('/api/cart', { method: 'DELETE' })
}

// ------------------------------------------------------------------ 订单

export interface OrderLine {
  model: string
  price: number
  qty: number
}

export interface Order {
  orderNo: string
  status: string
  totalAmount: number
  createdAt: string
  items: OrderLine[]
}

export interface PendingAction {
  confirmId: string
  type: string
  summary: string
  total: number
  itemCount: number
}

/** 直接下单（前端"立即购买"走这里，幂等键由前端生成一次） */
export function placeOrder(idemKey: string): Promise<Order> {
  return request<Order>('/api/orders', { method: 'POST', body: { idemKey } })
}

/** 聊天结束后查一次：有值就渲染"确认下单"按钮 */
export function getPending(): Promise<PendingAction | null> {
  return request<PendingAction | null>('/api/orders/pending')
}

/** agent 提议后，用户点确认才真正下单 */
export function confirmOrder(confirmId: string): Promise<Order> {
  return request<Order>('/api/orders/confirm', { method: 'POST', body: { confirmId } })
}

export function myOrders(): Promise<Order[]> {
  return request<Order[]>('/api/orders')
}
