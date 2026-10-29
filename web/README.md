# web · 数码导购 Agent 前端

Vue 3（免构建）+ 零依赖 Node 静态服务器。

## 怎么跑

```bash
cd web
node server.mjs          # → http://127.0.0.1:5173
```

前提：Java `:8080` 已启动。Python `:8000` 没起也能跑（只会显示“Agent 未连接”）。

演示时直接访问 `http://127.0.0.1:5173/?demo=1`，会自动跑一遍示例问题，省去手打。

## 为什么没有 npm / Vite

目标机器上 HTTPS 出网被拦（npm registry 走 HTTPS），`npm install` 装不上任何依赖。
所以这里用 Vue 3 的**全局构建版**（`vendor/vue.global.prod.js`，已入库，147 KB），
配 `<script type="module">` 直接跑，不需要打包。

代价与收益：

- 代价：组件是 `defineComponent` + 模板字符串，不是 `.vue` 单文件；
- 收益：`git clone` 之后 `node server.mjs` 就能开，没有任何安装步骤。

想换成 Vite 也很轻：把 `src/**` 挪进 `src/`，`.js` 改成 `.vue`，配三条 proxy（见下表），
其余逻辑一行不用改。

## 端口与代理

`server.mjs` 同时干掉了跨域，前端一律用同源相对路径：

| 前端路径 | 转发到 | 用途 |
|---|---|---|
| `/api/**` | `http://127.0.0.1:8080` | Java 商品查询 |
| `/v1/**` | `http://127.0.0.1:8000` | Python Agent（`/v1/chat`、`/v1/kb/ingest`） |
| `/healthz` | `http://127.0.0.1:8000` | Python 健康检查 |

可用环境变量覆盖：`PORT`、`JAVA_BASE`、`AGENT_BASE`。

## 目录

```
web/
├── server.mjs                 零依赖静态服务器 + 反向代理
├── index.html
├── vendor/vue.global.prod.js  Vue 3.4.21（含运行时编译器）
└── src/
    ├── main.js                挂载
    ├── vue.js                 从全局构建里取 API
    ├── api.js                 Java 接口封装（拆 R<T>、超时、错误）
    ├── agent.js               ★ 对接 /v1/chat 的 SSE 解析
├── spec.js                对比表用的参数维度（与类目权重同源）
    ├── store.js               会话状态 + send() 编排
    ├── style.css
    └── components/
        ├── App.js             布局：左聊天 右对比
        ├── MessageBubble.js   气泡 + 意图回显 + 追问选项
        ├── ProductCard.js     推荐卡片
        ├── CompareTable.js    参数对比表
        └── StreamingStatus.js 阶段进度
```

## 现在跑的是什么

前端只有一条链路：`POST /v1/chat`（SSE 流）。原先的 mock 模式已删除，参考：

- **真的**：商品查询、详情、预算硬过滤、参数归一化加权打分 —— 全部走 Java 接口 + 真实库数据；
- **假的**：需求解析（正则规则）和话术组织（模板拼接）。

这么设计的目的是让“数据链路”先真起来。接真 Agent 时只替换两处：`parseIntent` 和 `buildAnswer`
—— 也就是 `agent/app/graph/nodes.py` 里的 `parse` 与 `answer` 节点。

Agent 没启动时，气泡里会显示「连不上 Agent 服务（:8000）」——不会再静默转圈。

## SSE 事件协议（前后端必须一致）

改动要同步 `agent/app/api/routes.py`：

| event | data | 前端行为 |
|---|---|---|
| `status` | `{stage, text}` | 显示阶段进度（parsing/searching/scoring/answering） |
| `intent` | `{category, categoryLabel, budget:{min,max}, prefs:[{key,label}], brands:[]}` | 气泡里的意图标签 |
| `candidates` | `{total, items:[Recommendation]}` | **渲染卡片与对比表的唯一数据源** |
| `clarify` | `{question, options:[]}` | 可点击追问选项 |
| `token` | `{text}` | 追加到当前气泡 |
| `done` | `{latencyMs}` | 收尾 |
| `error` | `{msg}` | 红色错误块 |

`Recommendation` 结构：

```json
{
  "id": 2, "brand": "荣耀", "model": "WIN Turbo2", "priceRef": 3199.00,
  "score": 92,
  "reasons": ["电池容量 12070mAh，这批里唯一最高"],
  "metrics": {"battery_mah": 12070, "rear_mp": 5000, "charge_w": 90, "weight_g": 235}
}
```

**硬性约定**：型号、价格、参数只从 `candidates` 事件取，绝不去正则解析 LLM 的文本。
这样模型再怎么胡说，页面上也不会出现库里没有的型号或价格。

## 打分规则

`agent.js` 的 `SPEC_SCHEMA` 与 `biz.category.spec_schema` 同源（手机类目）：

| 维度 | 权重 | 方向 |
|---|---|---|
| 电池容量 | 1.0 | 越高越好 |
| 后置主摄 | 1.0 | 越高越好 |
| 充电功率 | 0.7 | 越高越好 |
| 运行内存 | 0.6 | 越高越好 |
| 重量 | 0.5 | **越低越好** |
| 刷新率 | 0.4 | 越高越好 |
| 屏幕尺寸 | 0.3 | 越高越好 |

命中用户偏好（续航 / 拍照 / 快充 / 轻薄 / 屏幕 / 游戏）的维度权重再乘 1.4~2.0。
打分是**候选集内 min-max 归一化**，所以分数只表示“这批里排第几”，不是绝对评分——
页面上也这么标注了。缺字段的维度直接跳过，不当 0 算（HANDOFF 第 5 节的要求）。

## 已知限制

1. 库内只有手机 25 款，问耳机/相机/充电宝会明确说“数据还没入库”，不做假推荐；
2. 无商品图，卡片用文字排版；
3. 价格是电商参考价（`price_ref`），页面标“参考价”；
4. 无登录态，`/api/products/**` 本来就在 Java 侧白名单里。

## 后续可做

- [ ] 换成真 `/v1/chat`（`mode: 'real'`），删掉 `parseIntent` 的正则；
- [ ] 迁移到 Vite + `.vue` 单文件（网络允许时）；
- [ ] 多轮追问：把上一轮 `intent` 合并进下一轮（现在每轮独立解析）；
- [ ] 商品详情弹层 + SKU 选择。
