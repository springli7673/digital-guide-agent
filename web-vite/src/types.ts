/** 后端返回的商品视图（列表用） */
export interface ProductView {
  id: number
  brand: string
  model: string
  title?: string
  priceRef: number | null
  imageUrl?: string
  launchDate?: string
  specs?: Record<string, unknown>
  highlights?: string[]
}

export interface PageResult<T> {
  total: number
  page: number
  size: number
  list: T[]
}

/** 商品详情（含 specs.display / specs.metrics / skus） */
export interface ProductDetail extends ProductView {
  specs?: {
    display?: Record<string, unknown>
    metrics?: SpecMetrics
    image_thumb?: string
    source_id?: string
  }
  skus?: Array<{ id: number; storage?: string; color?: string; priceRef?: number; stock?: number }>
}

export interface SpecMetrics {
  battery_mah?: number
  charge_w?: number
  weight_g?: number
  screen_inch?: number
  refresh_hz?: number
  ram?: number
  rom?: number
  rear_mp?: number
  image_score?: number
  cpu_score?: number
  dxo_camera?: number
  [key: string]: number | undefined
}

/** 商城卡片：列表字段 + 详情里补出来的参数与主图 */
export interface ShopItem extends ProductView {
  metrics: SpecMetrics
  imageThumb: string
}

/** 意图回显（聊天气泡上那些小标签） */
export interface IntentView {
  categoryLabel: string
  budget?: { min?: number; max?: number }
  prefs?: Array<{ key: string; label: string }>
  brands?: string[]
}

/** 候选（推荐卡片 + 对比表共用） */
export interface Candidate {
  id: number
  brand: string
  model: string
  priceRef: number | null
  imageUrl?: string
  score: number
  reasons: string[]
  metrics: SpecMetrics
}

export interface ClarifyPayload {
  question: string
  options: string[]
}

export interface ChatMessage {
  id: number
  role: 'user' | 'assistant'
  text: string
  streaming: boolean
  intent?: IntentView | null
  clarify?: ClarifyPayload | null
  error?: string | null
  latency?: number | null
}

export interface StatusPayload {
  stage: string
  text: string
}

export interface CandidatesPayload {
  items: Candidate[]
  total: number
}

export interface DonePayload {
  latencyMs: number
  sources?: Array<{ n: number; label: string; score: number }>
}

export interface ErrorPayload {
  msg: string
}

export interface TokenPayload {
  text: string
}

export type ChatEventName =
  | 'status'
  | 'intent'
  | 'candidates'
  | 'clarify'
  | 'token'
  | 'done'
  | 'error'

export interface ChatEventPayload {
  status: StatusPayload
  intent: IntentView
  candidates: CandidatesPayload
  clarify: ClarifyPayload
  token: TokenPayload
  done: DonePayload
  error: ErrorPayload
}
