-- ============================================================
-- digital-guide-agent / 数据库初始化（当前完整结构，可重复执行）
-- PostgreSQL 15+ + pgvector
-- 用法：psql -U postgres -d digital_guide -f db/schema.sql
--
-- 两个 schema：
--   biz  业务数据（商品目录 / 账号 / 购物车 / 订单），Java 读写
--   ai   智能客服运行时（知识库分块 / 会话记忆 / 链路埋点），Java 读写
--
-- 表/字段注释用 COMMENT ON 写在每张表后面，IDEA 的 Database 面板会直接显示。
-- 历史遗留的 ai.conversations / ai.messages / ai.tool_calls / ai.kb_documents /
-- ai.kb_chunks 和 biz.review / biz.favorite / biz.browse_history 已废弃，
-- 用 db/migration_cleanup_legacy.sql 删掉，这里不再创建。
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- 知识库正文模糊检索（gin_trgm_ops）

CREATE SCHEMA IF NOT EXISTS biz;
CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------
-- 账号
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.users (
    id            bigserial PRIMARY KEY,
    username      varchar(64)  NOT NULL UNIQUE,
    password_hash varchar(128) NOT NULL,
    nickname      varchar(64),
    created_at    timestamptz  NOT NULL DEFAULT now()
);

COMMENT ON TABLE biz.users IS '账号：登录后购物车/订单/客服记忆都归到这个人';
COMMENT ON COLUMN biz.users.id IS '主键';
COMMENT ON COLUMN biz.users.username IS '登录名，唯一；未登录用户走 a:{sessionId} 的匿名记忆，不落这张表';
COMMENT ON COLUMN biz.users.password_hash IS 'SHA-256(明文密码) 的十六进制，无盐；生产环境应换 BCrypt/Argon2';
COMMENT ON COLUMN biz.users.nickname IS '昵称，可为空';
COMMENT ON COLUMN biz.users.created_at IS '注册时间';

-- ------------------------------------------------------------
-- 品牌 / 类目
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.brand (
    id        bigserial PRIMARY KEY,
    name      varchar(64) NOT NULL UNIQUE,
    name_en   varchar(64),
    country   varchar(32),
    logo_url  text
);

COMMENT ON TABLE biz.brand IS '品牌：9 家（华为/小米/红米/OPPO/一加/vivo/iQOO/荣耀/苹果），前端品牌筛选与配色按 name 走';
COMMENT ON COLUMN biz.brand.id IS '主键';
COMMENT ON COLUMN biz.brand.name IS '中文品牌名，唯一；商品唯一键是 (brand_id, model)';
COMMENT ON COLUMN biz.brand.name_en IS '英文名，展示用，可为空';
COMMENT ON COLUMN biz.brand.country IS '国别，展示用，可为空';
COMMENT ON COLUMN biz.brand.logo_url IS '品牌 logo 地址；目前前端用不到（列表里用色块标签）';

CREATE TABLE IF NOT EXISTS biz.category (
    id          bigserial PRIMARY KEY,
    code        varchar(32)  NOT NULL UNIQUE,
    name        varchar(32)  NOT NULL,
    spec_schema jsonb        NOT NULL DEFAULT '{}'::jsonb,
    sort        int          NOT NULL DEFAULT 0
);

COMMENT ON TABLE biz.category IS '类目：目前只有 phone。spec_schema 是打分权重的唯一真相，代码里的 DEFAULT_SPEC_SCHEMA 只是兜底';
COMMENT ON COLUMN biz.category.id IS '主键';
COMMENT ON COLUMN biz.category.code IS '类目编码，也就是 product.category_id 指向的那个业务键：phone';
COMMENT ON COLUMN biz.category.name IS '类目中文名';
COMMENT ON COLUMN biz.category.spec_schema IS '每个参数的定义，形如 {"battery_mah":{"label":"电池容量","unit":"mAh","better":"higher","weight":1.0}}；改权重只改这里';
COMMENT ON COLUMN biz.category.sort IS '前端类目排序，小的在前';

-- ------------------------------------------------------------
-- 商品
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.product (
    id               bigserial PRIMARY KEY,
    brand_id         bigint       NOT NULL REFERENCES biz.brand(id),
    category_id      bigint       NOT NULL REFERENCES biz.category(id),
    model            varchar(128) NOT NULL,
    title            varchar(200),
    launch_date      date,
    price_ref        numeric(10,2),
    price_source     varchar(32),
    price_updated_at timestamptz,
    specs            jsonb        NOT NULL DEFAULT '{}'::jsonb,
    highlights       jsonb        NOT NULL DEFAULT '[]'::jsonb,
    image_url        text,
    data_source      varchar(64),
    status           varchar(16)  NOT NULL DEFAULT 'ON_SALE',
    created_at       timestamptz  NOT NULL DEFAULT now(),
    UNIQUE (brand_id, model)
);
CREATE INDEX IF NOT EXISTS idx_product_cate ON biz.product(category_id, price_ref);

COMMENT ON TABLE biz.product IS '商品主表：138 款手机，初始数据来自 db/seed_products.sql（数据管道脚本不随仓库发布）';
COMMENT ON COLUMN biz.product.id IS '主键；seed 会 DELETE 重建，所以自增 id 不稳定，对外用 source_id 或 (brand_id, model)';
COMMENT ON COLUMN biz.product.brand_id IS '品牌 FK；与 model 组成唯一约束，重复机型插不进来';
COMMENT ON COLUMN biz.product.category_id IS '类目 FK';
COMMENT ON COLUMN biz.product.model IS '对外型号全称，如「iPhone 18 Pro」';
COMMENT ON COLUMN biz.product.title IS '带容量的展示标题，如「苹果iPhone 18 Pro（256GB）」';
COMMENT ON COLUMN biz.product.launch_date IS '上市日期；有的机型页面没写，为空';
COMMENT ON COLUMN biz.product.price_ref IS '参考价 = 最低配起售价，不是实时价；改价先跑 tools/fix_variants.py';
COMMENT ON COLUMN biz.product.price_source IS '价格来源，如 zol_base_variant / 京东·天猫(参考)';
COMMENT ON COLUMN biz.product.price_updated_at IS '价格最后一次人工核对的时间';
COMMENT ON COLUMN biz.product.specs IS '{"display":{原始参数},"metrics":{打分用数值},"source_id":"ZOL商品号","image_thumb":"本地缩略图"}；打分只读 metrics，不要读 display';
COMMENT ON COLUMN biz.product.highlights IS '卖点标签数组，如 ["续航","影像"]，前端展示用';
COMMENT ON COLUMN biz.product.image_url IS '主图，本地静态文件 /img/products/{source_id}.webp（web-vite/public 下，不再用 ZOL 外链）';
COMMENT ON COLUMN biz.product.data_source IS '数据来源：zol / manual';
COMMENT ON COLUMN biz.product.status IS 'ON_SALE 在售；OFF_SALE 下架（列表与推荐都会过滤）';
COMMENT ON COLUMN biz.product.created_at IS '入库时间';

CREATE TABLE IF NOT EXISTS biz.product_sku (
    id         bigserial PRIMARY KEY,
    product_id bigint NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    storage    varchar(32),
    color      varchar(32),
    price_ref  numeric(10,2),
    stock      int NOT NULL DEFAULT 0,
    UNIQUE (product_id, storage, color)
);

COMMENT ON TABLE biz.product_sku IS '商品规格/库存：目前和 product 是 1:1 的伪规格（每款手机一行），下单扣库存就扣这张表';
COMMENT ON COLUMN biz.product_sku.id IS '主键';
COMMENT ON COLUMN biz.product_sku.product_id IS '商品 FK，级联删除';
COMMENT ON COLUMN biz.product_sku.storage IS '容量/版本，如 256GB；没有版本信息时为空串';
COMMENT ON COLUMN biz.product_sku.color IS '颜色，目前都为空';
COMMENT ON COLUMN biz.product_sku.price_ref IS '该规格参考价';
COMMENT ON COLUMN biz.product_sku.stock IS '库存；下单用条件更新 stock = stock - n WHERE stock >= n，扣不动就整单回滚';

-- ------------------------------------------------------------
-- 购物车 / 订单
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.cart_item (
    id             bigserial PRIMARY KEY,
    user_id        bigint NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    product_id     bigint NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    qty            int NOT NULL DEFAULT 1 CHECK (qty > 0 AND qty <= 99),
    price_snapshot numeric(10,2) NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, product_id)
);
CREATE INDEX IF NOT EXISTS idx_cart_user ON biz.cart_item(user_id);

COMMENT ON TABLE biz.cart_item IS '购物车：登录用户才有；agent 的 viewCart / recommendFromCart 也读这张表';
COMMENT ON COLUMN biz.cart_item.id IS '主键，也是 PUT/DELETE /api/cart/{id} 里的那个 id';
COMMENT ON COLUMN biz.cart_item.user_id IS '归属用户 FK；越权访问按这个字段判 403';
COMMENT ON COLUMN biz.cart_item.product_id IS '商品 FK，同一用户同一商品只有一行（重复加是累加 qty）';
COMMENT ON COLUMN biz.cart_item.qty IS '数量，1~99；重复加入走 LEAST(qty+n, 99)';
COMMENT ON COLUMN biz.cart_item.price_snapshot IS '加入时的单价快照，用来提示「价格已变动」；实际结算仍取当前价';
COMMENT ON COLUMN biz.cart_item.created_at IS '加入时间';
COMMENT ON COLUMN biz.cart_item.updated_at IS '最后修改时间';

CREATE TABLE IF NOT EXISTS biz.orders (
    id           bigserial PRIMARY KEY,
    order_no     varchar(32)  NOT NULL UNIQUE,
    user_id      bigint       NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    status       varchar(16)  NOT NULL DEFAULT 'PAID'
                 CHECK (status IN ('CREATED','PAID','CANCELLED')),
    total_amount numeric(10,2) NOT NULL,
    idem_key     varchar(64),
    created_at   timestamptz  NOT NULL DEFAULT now(),
    paid_at      timestamptz
);
CREATE INDEX IF NOT EXISTS idx_orders_user ON biz.orders(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uk_orders_idem ON biz.orders(idem_key) WHERE idem_key IS NOT NULL;

COMMENT ON TABLE biz.orders IS '订单头：演示项目直接落 PAID，没有支付网关';
COMMENT ON COLUMN biz.orders.id IS '主键';
COMMENT ON COLUMN biz.orders.order_no IS '对外单号（时间戳+随机），唯一';
COMMENT ON COLUMN biz.orders.user_id IS '下单用户 FK；/api/orders 只返回自己的';
COMMENT ON COLUMN biz.orders.status IS 'CREATED 待支付 / PAID 已支付 / CANCELLED 已取消';
COMMENT ON COLUMN biz.orders.total_amount IS '下单时的合计金额（服务端算，不信任前端）';
COMMENT ON COLUMN biz.orders.idem_key IS '幂等键：购物车下单是前端 UUID，agent 确认下单复用 confirmId；唯一索引防重复落单';
COMMENT ON COLUMN biz.orders.created_at IS '创建时间';
COMMENT ON COLUMN biz.orders.paid_at IS '支付时间，演示项目与创建时间基本一致';

CREATE TABLE IF NOT EXISTS biz.order_item (
    id             bigserial PRIMARY KEY,
    order_id       bigint NOT NULL REFERENCES biz.orders(id) ON DELETE CASCADE,
    product_id     bigint NOT NULL REFERENCES biz.product(id),
    model_snapshot varchar(128) NOT NULL,
    price_snapshot numeric(10,2) NOT NULL,
    qty            int NOT NULL DEFAULT 1 CHECK (qty > 0)
);
CREATE INDEX IF NOT EXISTS idx_order_item_order ON biz.order_item(order_id);

COMMENT ON TABLE biz.order_item IS '订单明细：下单瞬间把型号和单价抄一份，商品后来改价/下架都不影响历史订单';
COMMENT ON COLUMN biz.order_item.id IS '主键';
COMMENT ON COLUMN biz.order_item.order_id IS '订单头 FK，级联删除';
COMMENT ON COLUMN biz.order_item.product_id IS '商品 FK，不做级联（商品删了订单明细也要留住）';
COMMENT ON COLUMN biz.order_item.model_snapshot IS '下单时的型号快照';
COMMENT ON COLUMN biz.order_item.price_snapshot IS '下单时的单价快照';
COMMENT ON COLUMN biz.order_item.qty IS '购买数量';

-- ------------------------------------------------------------
-- ai：知识库 / 会话记忆 / 链路埋点
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai.kb_chunk (
    id         bigserial PRIMARY KEY,
    doc_title  text NOT NULL,
    heading    text,
    content    text NOT NULL,
    embedding  vector(1024),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_kb_chunk_title ON ai.kb_chunk(doc_title);
CREATE INDEX IF NOT EXISTS idx_kb_chunk_embedding ON ai.kb_chunk USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_kb_chunk_content_trgm ON ai.kb_chunk USING gin (content gin_trgm_ops);

COMMENT ON TABLE ai.kb_chunk IS '知识库分块：9 篇选购指南按小节切块，每块一条 bge-m3 向量；RAG 双路召回就是查这张表';
COMMENT ON COLUMN ai.kb_chunk.id IS '主键';
COMMENT ON COLUMN ai.kb_chunk.doc_title IS '文档标题；入库按它整篇替换（DELETE 后重插），所以重跑 ingest 不会重复';
COMMENT ON COLUMN ai.kb_chunk.heading IS '所属小节标题，回答里的「来源」角标用它';
COMMENT ON COLUMN ai.kb_chunk.content IS '正文；pg_trgm 模糊检索也查这一列';
COMMENT ON COLUMN ai.kb_chunk.embedding IS 'bge-m3 向量，1024 维；HNSW + cosine，不要换成 L2';
COMMENT ON COLUMN ai.kb_chunk.created_at IS '入库时间';

CREATE TABLE IF NOT EXISTS ai.chat_session (
    session_id text PRIMARY KEY,
    summary    text,
    slots      jsonb,
    turns      int NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE ai.chat_session IS '会话记忆：按用户归属，登录是 u:{userId}、匿名是 a:{sessionId}；Redis 里冷数据 30 分钟过期，落库的是长期那份';
COMMENT ON COLUMN ai.chat_session.session_id IS '会话主键，形如 u:12 / a:4f2c...；身份只从 ChatState.userId 来，不能用 ThreadLocal';
COMMENT ON COLUMN ai.chat_session.summary IS '滚动摘要：滑动窗口外的旧对话压缩成这段文字';
COMMENT ON COLUMN ai.chat_session.slots IS '最近一次 Intent 的 JSON；用户只说「再便宜点」时靠它继承预算和偏好';
COMMENT ON COLUMN ai.chat_session.turns IS '已发生的轮数，决定何时触发摘要';
COMMENT ON COLUMN ai.chat_session.updated_at IS '最后更新时间';

CREATE TABLE IF NOT EXISTS ai.chat_message (
    id         bigserial PRIMARY KEY,
    session_id text NOT NULL,
    role       text NOT NULL,
    content    text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chat_message_session ON ai.chat_message(session_id, id);

COMMENT ON TABLE ai.chat_message IS '会话原始消息：只是短期上下文，超出窗口的部分压缩进 chat_session.summary 后会删掉';
COMMENT ON COLUMN ai.chat_message.id IS '主键，也用作同会话内的顺序';
COMMENT ON COLUMN ai.chat_message.session_id IS '所属会话，对应 chat_session.session_id（不建外键，随手清理不阻塞）';
COMMENT ON COLUMN ai.chat_message.role IS 'user / assistant';
COMMENT ON COLUMN ai.chat_message.content IS '消息正文';
COMMENT ON COLUMN ai.chat_message.created_at IS '时间';

CREATE TABLE IF NOT EXISTS ai.trace (
    id              bigserial PRIMARY KEY,
    created_at      timestamptz NOT NULL DEFAULT now(),
    session_id      text,
    question        text,
    category        text,
    candidates      int,
    kb_hits         int,
    latency_ms      int,
    timing          jsonb,
    guard_violation text,
    error           text
);
CREATE INDEX IF NOT EXISTS idx_trace_session ON ai.trace(session_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trace_created_at ON ai.trace(created_at DESC);

COMMENT ON TABLE ai.trace IS '链路埋点：每轮对话一条，用来回答「慢在哪、检索命中几条、有没有被护栏拦」';
COMMENT ON COLUMN ai.trace.id IS '主键';
COMMENT ON COLUMN ai.trace.created_at IS '本轮开始时间';
COMMENT ON COLUMN ai.trace.session_id IS '会话 id，和 chat_session 同口径';
COMMENT ON COLUMN ai.trace.question IS '用户原始问题';
COMMENT ON COLUMN ai.trace.category IS '分流结果：phone（确定流水线）/ knowledge（RAG）/ followup（工具模式）';
COMMENT ON COLUMN ai.trace.candidates IS '候选商品条数（0 表示硬条件全过滤掉了）';
COMMENT ON COLUMN ai.trace.kb_hits IS '知识库召回条数';
COMMENT ON COLUMN ai.trace.latency_ms IS '整轮耗时（毫秒），只用于定位，不要拿去当压测结论';
COMMENT ON COLUMN ai.trace.timing IS '各节点耗时（毫秒），形如 {"parse":1240,"retrieve":80}';
COMMENT ON COLUMN ai.trace.guard_violation IS '幻觉护栏抓到的候选外型号/价格，为空表示这一轮干净';
COMMENT ON COLUMN ai.trace.error IS '异常摘要，正常轮次为空';
