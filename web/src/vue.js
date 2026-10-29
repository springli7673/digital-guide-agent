/**
 * 从全局构建版里取出需要的 API。
 * 用全局版（非 npm 包）是为了让这个前端零依赖、免安装、直接 http 打开就能跑。
 */
const {
  createApp,
  reactive,
  ref,
  computed,
  watch,
  onMounted,
  onUnmounted,
  nextTick,
} = window.Vue

export {
  createApp,
  reactive,
  ref,
  computed,
  watch,
  onMounted,
  onUnmounted,
  nextTick,
}
