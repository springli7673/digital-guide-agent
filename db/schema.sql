-- ============================================================
-- digital-guide-agent / 数据库初始化
-- PostgreSQL 15+ + pgvector
-- 用法：psql -U postgres -d digital_guide -f db/schema.sql
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS biz;   -- 业务数据，Java 读写
CREATE SCHEMA IF NOT EXISTS ai;    -- 知识库与会话，Python 读写

-- ------------------------------------------------------------
-- 用户（演示用）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.users (
    id            bigserial PRIMARY KEY,
    username      varchar(64)  NOT NULL UNIQUE,
    password_hash varchar(128) NOT NULL,
    nickname      varchar(64),
    created_at    timestamptz  NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 品牌 / 类目
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.brand (
    id        bigserial PRIMARY KEY,
    name      varchar(64) NOT NULL UNIQUE,       -- 小米、华为、索尼
    name_en   varchar(64),
    country   varchar(32),
    logo_url  text
);

-- spec_schema 定义该类目有哪些参数、单位、方向、权重
CREATE TABLE IF NOT EXISTS biz.category (
    id          bigserial PRIMARY KEY,
    code        varchar(32)  NOT NULL UNIQUE,    -- phone / earbuds / camera / powerbank
    name        varchar(32)  NOT NULL,
    spec_schema jsonb        NOT NULL DEFAULT '{}'::jsonb,
    sort        int          NOT NULL DEFAULT 0
);

-- ------------------------------------------------------------
-- 商品
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.product (
    id               bigserial PRIMARY KEY,
    brand_id         bigint       NOT NULL REFERENCES biz.brand(id),
    category_id      bigint       NOT NULL REFERENCES biz.category(id),
    model            varchar(128) NOT NULL,      -- 对外展示的型号全称
    title            varchar(200),
    launch_date      date,
    price_ref        numeric(10,2),              -- 参考价，不是实时价
    price_source     varchar(32),                -- 京东 / 天猫 / 官网
    price_updated_at timestamptz,
    specs            jsonb        NOT NULL DEFAULT '{}'::jsonb,
    highlights       jsonb        NOT NULL DEFAULT '[]'::jsonb,  -- 卖点标签数组
    image_url        text,
    data_source      varchar(64),                -- zol / manual
    status           varchar(16)  NOT NULL DEFAULT 'ON_SALE',
    created_at       timestamptz  NOT NULL DEFAULT now(),
    UNIQUE (brand_id, model)
);
CREATE INDEX IF NOT EXISTS idx_product_cate ON biz.product(category_id, price_ref);

-- 同一型号的不同存储/颜色
CREATE TABLE IF NOT EXISTS biz.product_sku (
    id         bigserial PRIMARY KEY,
    product_id bigint NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    storage    varchar(32),                      -- 256GB / 空
    color      varchar(32),
    price_ref  numeric(10,2),
    stock      int NOT NULL DEFAULT 0,
    UNIQUE (product_id, storage, color)
);

-- ------------------------------------------------------------
-- 口碑（也是 RAG 语料）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz.review (
    id          bigserial PRIMARY KEY,
    product_id  bigint NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    rating      numeric(2,1) CHECK (rating >= 0 AND rating <= 5),
    content     text NOT NULL,
    tags        jsonb NOT NULL DEFAULT '[]'::jsonb,
    source      varchar(32),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_review_product ON biz.review(product_id);

-- ------------------------------------------------------------
-- ai：知识库 / 会话 / 工具日志
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai.kb_documents (
    id         bigserial PRIMARY KEY,
    title      text NOT NULL,
    source     text,
    category   text,
    version    int  NOT NULL DEFAULT 1,
    status     varchar(16) NOT NULL DEFAULT 'READY',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai.kb_chunks (
    id          bigserial PRIMARY KEY,
    doc_id      bigint NOT NULL REFERENCES ai.kb_documents(id) ON DELETE CASCADE,
    chunk_index int    NOT NULL,
    content     text   NOT NULL,
    metadata    jsonb,
    embedding   vector(1024),
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chunks_doc ON ai.kb_chunks(doc_id);
CREATE INDEX IF NOT EXISTS idx_chunks_emb ON ai.kb_chunks
    USING hnsw (embedding vector_cosine_ops);

CREATE TABLE IF NOT EXISTS ai.conversations (
    id         uuid PRIMARY KEY,
    user_id    bigint NOT NULL,
    title      text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai.messages (
    id              bigserial PRIMARY KEY,
    conversation_id uuid   NOT NULL,
    role            varchar(16) NOT NULL,
    content         text   NOT NULL,
    citations       jsonb,
    latency_ms      int,
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_messages_conv ON ai.messages(conversation_id, id);

CREATE TABLE IF NOT EXISTS ai.tool_calls (
    id              bigserial PRIMARY KEY,
    conversation_id uuid,
    tool_name       varchar(64) NOT NULL,
    args            jsonb,
    result          jsonb,
    success         boolean,
    cost_ms         int,
    created_at      timestamptz NOT NULL DEFAULT now()
);
