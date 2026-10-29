/**
 * Vue 的薄封装（TypeScript 版）。
 *
 * 用的是 Vue 全局构建版（`vendor/vue.global.prod.js`），没有 npm 包，所以也没有官方类型。
 * 这里手写一层声明把用到的 API 标上类型：`ref('')` 出来就是 `Ref<string>`。
 * 只声明这个前端真正用到的那几个 API。
 */

export interface Ref<T> {
  value: T
}

interface VueGlobal {
  createApp: (component: unknown) => {
    config: { errorHandler: unknown }
    mount: (selector: string) => unknown
  }
  reactive: <T extends object>(target: T) => T
  ref: <T>(value: T) => Ref<T>
  computed: <T>(getter: () => T) => Ref<T>
  watch: (source: unknown, callback: () => void) => void
  onMounted: (hook: () => void) => void
  onUnmounted: (hook: () => void) => void
  nextTick: (fn?: () => void) => Promise<void>
}

const Vue = (window as unknown as { Vue?: VueGlobal }).Vue

if (!Vue) {
  // 全局构建没加载时所有 API 都是 undefined，报错很难找，这里给一条明确的
  throw new Error('Vue 全局构建未加载：确认 index.html 里 vendor/vue.global.prod.js 在 main.js 之前')
}

export const createApp = Vue.createApp
export const reactive = Vue.reactive
export const ref = Vue.ref
export const computed = Vue.computed
export const watch = Vue.watch
export const onMounted = Vue.onMounted
export const onUnmounted = Vue.onUnmounted
export const nextTick = Vue.nextTick
