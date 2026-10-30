/**
 * 品牌主色。只用于标签和强调色，不改变按钮层级。
 * 颜色取各品牌视觉识别色的近似值，饱和度压一档，避免在浅色界面里跳。
 */
export interface BrandStyle {
  color: string
  bg: string
}

const MAP: Record<string, BrandStyle> = {
  华为: { color: '#c8102e', bg: '#fdecee' },
  小米: { color: '#ff6900', bg: '#fff2e8' },
  红米: { color: '#e8541e', bg: '#fdf0ea' },
  OPPO: { color: '#0f9d58', bg: '#eaf7f0' },
  一加: { color: '#d9232e', bg: '#fdeceb' },
  vivo: { color: '#3b5bdb', bg: '#edf0ff' },
  iQOO: { color: '#1f6feb', bg: '#eaf2ff' },
  荣耀: { color: '#0a84ff', bg: '#e9f3ff' },
  苹果: { color: '#3a3a3c', bg: '#f0f0f2' },
}

const FALLBACK: BrandStyle = { color: '#6b7280', bg: '#f3f4f6' }

export function brandStyle(brand: string): BrandStyle {
  return MAP[brand] || FALLBACK
}
