/**
 * 零依赖开发服务器：静态托管 + 反向代理。
 *
 *   node server.mjs            → http://127.0.0.1:5173
 *
 * 为什么不用 Vite：这台机器的沙箱只能走 HTTP，装不了 npm 依赖。
 * 这个文件同时解决了跨域——前端一律用同源相对路径，
 * /api/**、/v1/**、/healthz 全部转给 Java :8080（Agent 已并入 Java 进程）。
 * 以后要换 Vite，把 vite.config.ts 的 proxy 配成一样的三条即可。
 */

import http from 'node:http'
import { createReadStream, existsSync } from 'node:fs'
import { stat } from 'node:fs/promises'
import { extname, join, normalize, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = fileURLToPath(new URL('.', import.meta.url))
// 源码是 src/*.ts，页面加载 public/ 下的产物；忘了构建时给一条明确提示
if (!existsSync(join(ROOT, 'public', 'main.js'))) {
  console.error('[web] 缺少 public/main.js，先跑 node build.mjs（或 node build.mjs --watch）')
}

const PORT = Number(process.env.PORT || 5173)
const JAVA = process.env.JAVA_BASE || 'http://127.0.0.1:8080'
// 默认空：/v1 与 /healthz 跟 /api 一样走 Java。
// 想对照旧的 Python 服务，就设 AGENT_BASE=http://127.0.0.1:8000
const AGENT_URL = process.env.AGENT_BASE || ''

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
}

/** 哪些前缀转发到哪个后端 */
function resolveTarget(pathname) {
  // Agent 已经并入 Java 进程，/v1/** 和 /healthz 现在也归 :8080 管。
  // AGENT 常量保留，方便临时切回旧的 Python 服务做对照。
  if (pathname.startsWith('/api/')) return JAVA
  if (pathname.startsWith('/v1/') || pathname === '/healthz') return AGENT_URL || JAVA
  return null
}

function proxy(req, res, base) {
  const target = new URL(req.url, base)
  const headers = { ...req.headers }
  headers.host = target.host
  headers['accept-encoding'] = 'identity' // 不引入压缩，省掉解压逻辑

  const upstream = http.request(
    {
      protocol: target.protocol,
      hostname: target.hostname,
      port: target.port,
      path: target.pathname + target.search,
      method: req.method,
      headers,
    },
    (upRes) => {
      res.writeHead(upRes.statusCode || 502, upRes.headers)
      upRes.pipe(res) // SSE 靠这里边收边发，不要缓冲
    }
  )

  upstream.on('error', (err) => {
    if (res.headersSent) {
      res.end()
      return
    }
    res.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' })
    res.end(JSON.stringify({ code: 502, msg: `${base} 不可达：${err.message}`, data: null }))
  })

  req.pipe(upstream)
}

async function serveStatic(pathname, res) {
  const rel = decodeURIComponent(pathname === '/' ? '/index.html' : pathname)
  const filePath = normalize(join(ROOT, rel))
  if (!filePath.startsWith(ROOT.endsWith(sep) ? ROOT : ROOT + sep)) {
    res.writeHead(403).end('forbidden')
    return
  }
  try {
    const info = await stat(filePath)
    if (!info.isFile()) throw new Error('not a file')
    res.writeHead(200, {
      'Content-Type': MIME[extname(filePath).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-cache',
    })
    createReadStream(filePath).pipe(res)
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' })
    res.end('404 ' + rel)
  }
}

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, 'http://local')
    const base = resolveTarget(pathname)
    if (base) return proxy(req, res, base)
    return serveStatic(pathname, res)
  })
  .listen(PORT, '127.0.0.1', () => {
    console.log(`[web] http://127.0.0.1:${PORT}`)
    console.log(`[web] /api/** -> ${JAVA}`)
    console.log(`[web] /api/**, /v1/**, /healthz -> ${AGENT_URL || JAVA}`)
  })
