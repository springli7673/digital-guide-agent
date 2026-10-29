/**
 * 前后端共享的数据结构。
 *
 * 形状不是猜的：`ProductView` / `ProductDetail` 对应 Java 的 `ProductView` 与
 * `/api/products/{id}` 的返回；`Intent` / `Recommendation` / `Clarify` 对应 SSE 事件里的
 * payload（见 backend 的 `ai/web/AiChatController` 与 `ai/graph/*`）。
 */

export interface PageResult<T> {
  total: number
  page: number
  size: number
  list: T[]
}

export interface ProductView {
  id: number
  brand: string
  model: string
  title?: string
  priceRef: number | null
  imageUrl?: string
  launchDate?: string | null
  highlights?: string[]
}

/** 打分用的数值维度，键与 biz.category.spec_schema 一致 */
export interface Metrics {
  [key: string]: number | undefined
}

export interface ProductDetail extends ProductView {
  specs?: {
    display?: Record<string, string>
    metrics?: Metrics
    image_thumb?: string
    source?: string
    source_id?: string
    url?: string
  }
  skus?: { storage: string; color: string; priceRef: number; stock: number }[]
}

/** candidates 事件里的一项，由后端打分产生 */
export interface Recommendation {
  id: number
  brand: string
  model: string
  priceRef: number | null
  imageUrl?: string
  score: number
  reasons: string[]
  metrics: Metrics
  highlights: string[]
}

export interface Pref {
  key: string
  label: string
  priority: 'must' | 'nice'
}

export interface Intent {
  category: string
  categoryLabel: string
  budget: { min: number | null; max: number | null } | null
  prefs: Pref[]
  brands: string[]
  usage: string
}

export interface Clarify {
  question: string
  options: string[]
}

export interface Status {
  stage: string
  text: string
}

export interface ChatMessage {
  id: number
  role: 'user' | 'assistant'
  text: string
  streaming: boolean
  intent?: Intent | null
  clarify?: Clarify | null
  error?: string | null
  latency?: number | null
}

/** SSE 事件名，与后端逐个对应 */
export type ChatEventName =
  | 'status'
  | 'intent'
  | 'candidates'
  | 'clarify'
  | 'token'
  | 'done'
  | 'error'

/** 事件名 → payload 形状 */
export interface ChatEventPayload {
  status: Status
  intent: Intent
  candidates: { total: number; items: Recommendation[] }
  clarify: Clarify
  token: { text: string }
  done: { latencyMs: number }
  error: { msg: string }
}

export interface AppState {
  view: 'shop' | 'chat'
  messages: ChatMessage[]
  candidates: Recommendation[]
  candidateTotal: number
  selected: number[]
  status: Status | null
  busy: boolean
  backend: { java: boolean; total: number }
  fatalError: string
  clarifyCount: number
}

/** 对比表的维度定义，与后端 spec_schema 同序 */
export interface SpecDim {
  key: string
  label: string
  unit: string
  better: 'higher' | 'lower'
  weight: number
}
