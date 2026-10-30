/**
 * 参数对比表要展示的行与顺序。
 *
 * 和后端 `biz.category.spec_schema` 的维度保持一致（权重在后端，这里只管展示）。
 * `better: 'lower'` 表示数值越小越好（重量），其余越大越好。
 */
export interface SpecDim {
  key: string
  label: string
  unit: string
  better: 'higher' | 'lower'
}

export const SPEC_SCHEMA: SpecDim[] = [
  { key: 'priceRef', label: '参考价', unit: '元', better: 'lower' },
  { key: 'image_score', label: '影像梯队', unit: '', better: 'higher' },
  { key: 'dxo_camera', label: 'DXO 影像', unit: '分', better: 'higher' },
  { key: 'rear_mp', label: '主摄', unit: '万', better: 'higher' },
  { key: 'cpu_score', label: '处理器', unit: '', better: 'higher' },
  { key: 'ram', label: '运行内存', unit: 'GB', better: 'higher' },
  { key: 'rom', label: '存储', unit: 'GB', better: 'higher' },
  { key: 'battery_mah', label: '电池', unit: 'mAh', better: 'higher' },
  { key: 'charge_w', label: '快充', unit: 'W', better: 'higher' },
  { key: 'screen_inch', label: '屏幕', unit: '英寸', better: 'higher' },
  { key: 'refresh_hz', label: '刷新率', unit: 'Hz', better: 'higher' },
  { key: 'weight_g', label: '重量', unit: 'g', better: 'lower' },
]
