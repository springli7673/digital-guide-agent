/** 手机类目的评分维度，与 biz.category.spec_schema 保持一致；对比表按这个顺序出列 */
export const SPEC_SCHEMA = [
  { key: 'battery_mah', label: '电池容量', unit: 'mAh', better: 'higher', weight: 1.0 },
  { key: 'charge_w', label: '充电功率', unit: 'W', better: 'higher', weight: 0.7 },
  { key: 'image_score', label: '影像梯队', unit: '分', better: 'higher', weight: 1.0 },
  { key: 'dxo_camera', label: 'DXO 影像', unit: '分', better: 'higher', weight: 0.5 },
  { key: 'rear_mp', label: '后置主摄', unit: '万像素', better: 'higher', weight: 0.4 },
  { key: 'cpu_score', label: '处理器', unit: '分', better: 'higher', weight: 0.8 },
  { key: 'weight_g', label: '重量', unit: 'g', better: 'lower', weight: 0.5 },
  { key: 'refresh_hz', label: '刷新率', unit: 'Hz', better: 'higher', weight: 0.4 },
  { key: 'screen_inch', label: '屏幕尺寸', unit: '英寸', better: 'higher', weight: 0.3 },
  { key: 'ram', label: '运行内存', unit: 'GB', better: 'higher', weight: 0.6 },
]
