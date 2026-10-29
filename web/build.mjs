/**
 * 零依赖 TypeScript 构建：把 src/**.ts 剥掉类型后输出到 public/。
 *
 * 为什么不用 tsc / vite：这台机器装不上 npm 包（registry 不可达），而这个前端从一开始
 * 就是"免构建、直接 http 打开就能跑"。Node 22+ 内置了 `module.stripTypeScriptTypes`，
 * 正好只做一件事——把类型语法删掉，其余原样保留。
 *
 * 代价要说清楚：**它不做类型检查**。`npm run typecheck` 需要真正的 `tsc`
 * （见 package.json 的 devDependencies），网络能通时可以跑一次做校验。
 *
 *   node build.mjs          一次构建
 *   node build.mjs --watch  改文件自动重新构建（简易轮询，不依赖 fs.watch）
 */
import { stripTypeScriptTypes } from 'node:module'
import {
  mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync,
} from 'node:fs'
import { dirname, extname, join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = dirname(fileURLToPath(import.meta.url))
const SRC = join(ROOT, 'src')
const OUT = join(ROOT, 'public')

const watch = process.argv.includes('--watch')

/** 递归列出 src 下的文件 */
function walk(dir) {
  const out = []
  for (const name of readdirSync(dir)) {
    const full = join(dir, name)
    if (statSync(full).isDirectory()) out.push(...walk(full))
    else out.push(full)
  }
  return out
}

/** 剥类型。strip 模式遇到 enum/namespace 这类需要改写语义的语法会报错，那时退回 transform */
function toJavaScript(file, code) {
  try {
    return stripTypeScriptTypes(code, { mode: 'strip' })
  } catch (error) {
    try {
      const out = stripTypeScriptTypes(code, { mode: 'transform' })
      console.warn(`  warn  ${relative(SRC, file)} 用了需要 transform 的语法，已自动降级`)
      return out
    } catch {
      throw new Error(`${relative(SRC, file)} 无法转换成 JS：${error.message}`)
    }
  }
}

function build() {
  const started = Date.now()
  rmSync(OUT, { recursive: true, force: true })
  mkdirSync(OUT, { recursive: true })

  let ts = 0
  let assets = 0
  const failures = []

  for (const file of walk(SRC)) {
    const rel = relative(SRC, file)
    const ext = extname(file)

    if (ext === '.ts') {
      const target = join(OUT, rel.replace(/\.ts$/, '.js'))
      try {
        const js = toJavaScript(file, readFileSync(file, 'utf8'))
        mkdirSync(dirname(target), { recursive: true })
        writeFileSync(target, js, 'utf8')
        ts++
      } catch (error) {
        failures.push(error.message)
      }
    } else if (ext === '.css' || ext === '.svg' || ext === '.json') {
      // 静态资源原样拷过去，页面只需要引用 public/ 一处
      const target = join(OUT, rel)
      mkdirSync(dirname(target), { recursive: true })
      writeFileSync(target, readFileSync(file))
      assets++
    }
  }

  const ms = Date.now() - started
  if (failures.length) {
    console.error(`\n构建失败（${failures.length} 个文件）：`)
    for (const message of failures) console.error('  ' + message)
    process.exitCode = 1
    return
  }
  console.log(`built ${ts} ts → public/  (${assets} assets, ${ms}ms)`)
}

build()

if (watch) {
  // 简易轮询：stamp 变了就重建。不用 fs.watch 是因为它在 Windows 上偶尔会漏事件
  let stamp = Date.now()
  setInterval(() => {
    const latest = Math.max(
      ...walk(SRC).map((f) => statSync(f).mtimeMs),
    )
    if (latest > stamp) {
      stamp = latest
      console.log('\nchange detected, rebuilding…')
      build()
    }
  }, 400)
  console.log('watching src/ — ctrl-c 退出')
}
