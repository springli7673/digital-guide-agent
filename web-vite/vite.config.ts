import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/**
 * 后端是 Java 单体（:8080），前端 dev server 只做三件事：
 * 托管静态资源、代理接口、以及把 /v1/chat 的 SSE 原样透传。
 *
 * 注意 SSE 的两个代理细节（否则流式会"卡住"）：
 *  1. 不要开 compress —— 压缩会把 chunk 攒起来，打字机效果就没了；
 *  2. 不要改 timeout —— 一轮回答可能几十秒。
 * dev server 默认对 /v1 走 http-proxy，不改写响应体，所以是安全的。
 */
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5174, // 老的零依赖前端还占着 5173，并存一段时间
    strictPort: false,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/v1': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/healthz': { target: 'http://127.0.0.1:8080', changeOrigin: true },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
})
