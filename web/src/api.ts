/**
 * Java 后端接口封装（TypeScript 版）。
 *
 * 约定：所有接口返回 {code, msg, data}，code !== 0 视为业务失败。
 * 走同源相对路径，由 server.mjs 反向代理到 :8080，因此没有跨域问题。
 */
import type { PageResult, ProductDetail, ProductView } from './types.js'

const TIMEOUT = 8000

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
  try {
    const resp = await fetch(path, {
      method,
      headers: body ? { 'Content-Type': 'application/json' } : undefined,
      body: body ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    })
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
