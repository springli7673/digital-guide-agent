/**
 * Java 后端接口封装。
 *
 * 约定：所有接口返回 {code, msg, data}，code !== 0 视为业务失败。
 * 走同源相对路径，由 server.mjs 反向代理到 :8080，因此没有跨域问题。
 */

const TIMEOUT = 8000

async function request(path, { method = 'GET', body, timeout = TIMEOUT } = {}) {
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
    const payload = await resp.json()
    if (payload && typeof payload.code === 'number' && payload.code !== 0) {
      throw new Error(payload.msg || '接口返回业务错误')
    }
    return payload.data
  } finally {
    clearTimeout(timer)
  }
}

/** 商品分页查询：{category, brand, keyword, minPrice, maxPrice, page, size} */
export function listProducts(params = {}) {
  const qs = new URLSearchParams()
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') qs.set(k, v)
  }
  return request(`/api/products?${qs.toString()}`)
}

/** 商品详情：含 specs.display / specs.metrics / skus */
export function getProduct(id) {
  return request(`/api/products/${id}`)
}
