# 前端迁移说明（Vite + SFC）

旧版是「零依赖 + 全局构建 Vue」：没有 npm、没有 SFC、没有 HMR。
这一份是**企业标准工程**，业务一行没改，只换了工程形态。

## 技术栈

| 层 | 选型 |
|---|---|
| 构建 | Vite 5 |
| 框架 | Vue 3.5（`<script setup>` + SFC + TS） |
| UI | Element Plus 2.8（主色改成小米橙 `#ff6900`） |
| 路由 | Vue Router 4（history 模式） |
| 状态 | Pinia（`shopStore` / `chatStore` 两个仓库） |

## 为什么分成两个 store

| 仓库 | 管什么 | 换用户时 |
|---|---|---|
| `shopStore` | 登录态、购物车、待确认下单 | **清空** |
| `chatStore` | 消息、候选、流式状态、勾选 | 保留 |

生命周期不同，塞一个仓库里迟早要写 `reset` 时漏掉一半字段。

## 路由

| 路径 | 页面 | 说明 |
|---|---|---|
| `/mall` | 手机商城 | 默认重定向到这里 |
| `/cart` | 购物车 | 未登录时页面内给"去登录"，**不做路由守卫** |
| `/chat` | 智能客服 | 推荐链路 + 工具链路 |
| `/login` | 登录 / 注册 | 同一个表单切换模式 |

为什么 `/cart` 不加守卫：直接重定向会让用户丢掉"我刚才在看哪"的上下文，
页面内提示更好。

## 代理（关键）

```ts
proxy: {
  '/api':     { target: 'http://127.0.0.1:8080', changeOrigin: true },
  '/v1':      { target: 'http://127.0.0.1:8080', changeOrigin: true },
  '/healthz': { target: 'http://127.0.0.1:8080', changeOrigin: true },
}
```

`/v1/chat` 是 **POST + SSE**：
- **不要开 `compress`**，压缩会把 chunk 攒起来，打字机效果就没了；
- **不要给代理设 timeout**，一轮回答可能几十秒。

## SSE 实现要点（没有改）

- 不能用 `EventSource`：它只支持 GET，而这个接口要 POST + JSON body；
- 用 `fetch` 拿 `ReadableStream`，手写 SSE 解析（`src/api/agent.ts`）；
- **残帧必须留在 buffer 里**（`decoder.decode(value, { stream: true })`），
  否则中文字符被切在 chunk 边界上就是乱码。

## 启动

```bash
# 1. 后端（先起来，否则代理会 502）
#    IDEA 里跑 DigitalGuideApplication，需要 DEEPSEEK_API_KEY + REDIS_PASSWORD=123456

# 2. 前端
cd web            # 或迁移后的目录
npm install       # 首次需要联网
npm run dev       # http://localhost:5174

# 生产构建
npm run build     # 产出 dist/，可交给 nginx 托管
npm run preview   # 本地预览 dist
```

端口是 **5174**：旧的零依赖前端还占着 5173，两者可以并存一段时间。

## 目录结构

```
src/
  main.ts                 挂载 + Pinia + Router + Element Plus
  App.vue                 外壳：侧边菜单 + 待确认下单横幅 + <router-view>
  router/index.ts         4 条路由
  stores/
    shopStore.ts          登录 / 购物车 / 待确认
    chatStore.ts          消息 / 候选 / 流式 / 勾选
  api/
    client.ts             所有 HTTP 接口（token 自动附带）
    agent.ts              SSE 解析（逻辑与旧版逐字一致）
  components/
    ProductCard.vue       商城卡片（加购 / 立即购买）
    RecommendCard.vue     推荐卡片（点击切换对比）
    CompareTable.vue      参数对比表（最优值高亮）
    MessageBubble.vue     消息气泡（意图标签 / 追问 / 耗时）
    StreamingStatus.vue   流式进度（四阶段）
  views/
    MallView.vue          品牌筛选 + 网格 + 分页
    CartView.vue          表格 + 数量 + 结算
    ChatView.vue          左对话 / 右推荐
    LoginView.vue         登录 / 注册
  brandColors.ts          九个品牌的主色
  spec.ts                 对比表维度（与后端 spec_schema 对齐）
  types.ts                前后端共享的数据形状
  styles/main.css         主题变量 + 通用块
```

## 迁移时保留的行为（逐条核对过）

- [x] 商城：品牌筛选、分页（15 条/页）、卡片补详情拿 metrics 与主图
- [x] 加购：未登录先记意图，登录后自动重放
- [x] 购物车：增减、删除、合计、结算、价格变动提示
- [x] 聊天：示例提示词、clarify 选项点击即发、意图标签、耗时显示
- [x] 候选：勾选参与对比、按分数排序、对比表高亮最优、缺失行整行不显示
- [x] 流式：`status / intent / candidates / clarify / token / done / error` 七种事件
- [x] 待确认下单：agent 提议 → 外壳横幅 → 用户确认才扣库存
- [x] 登录：token 存 localStorage，`/api/**` 与 `/v1/chat` 都带 `Authorization`

## 和旧版的取舍差异

| | 旧版（零依赖） | 新版（Vite） |
|---|---|---|
| 依赖 | 0 | ~180 个包（含 vite/element-plus） |
| 构建 | 80–250 ms | 首次 ~6 s，HMR 毫秒级 |
| 类型检查 | 无 | `npm run build` 会先跑 `vue-tsc --noEmit` |
| 模板 | 字符串，无高亮 | SFC，有高亮与类型提示 |
| 上手 | 反直觉 | 团队标准 |

**旧版没有删**，跑在 5173；确认新版没问题后可以整目录删除。
