-- ============================================================================
-- 电商侧数据模型：购物车 / 收藏 / 浏览历史 / 订单
--
-- 全部 IF NOT EXISTS，可重复执行。执行顺序无要求（都是新表）。
-- 约定：
--   * 金额一律 numeric(10,2)，不要用 float
--   * 时间一律 timestamptz（带时区，和现有表一致）
--   * 所有"用户私有数据"都有 user_id + 唯一约束，靠数据库兜住重复
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------- 购物车（批 2）
-- 唯一约束 (user_id, sku_id)：同一个 SKU 在购物车里只可能有一条，
-- 重复加购走 UPDATE qty = qty + n，而不是 INSERT，靠数据库兜住并发重复加购。
CREATE TABLE IF NOT EXISTS biz.cart_item (
    id         bigserial PRIMARY KEY,
    user_id    bigint      NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    sku_id     bigint      NOT NULL REFERENCES biz.product_sku(id) ON DELETE CASCADE,
    qty        int         NOT NULL DEFAULT 1 CHECK (qty > 0 AND qty <= 99),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uk_cart_user_sku UNIQUE (user_id, sku_id)
);
CREATE INDEX IF NOT EXISTS idx_cart_user ON biz.cart_item (user_id);

-- ---------------------------------------------------------------- 收藏（批 2）
-- price_at_favorite 是"收藏那一刻的价格快照"。
-- 有这个字段才能算"你收藏的 K80 现在比收藏时降了 300"，否则只能报当前价。
CREATE TABLE IF NOT EXISTS biz.favorite (
    id                bigserial PRIMARY KEY,
    user_id           bigint        NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    product_id        bigint        NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    price_at_favorite numeric(10,2),
    created_at        timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT uk_fav_user_product UNIQUE (user_id, product_id)
);
CREATE INDEX IF NOT EXISTS idx_fav_user ON biz.favorite (user_id, created_at DESC);

-- ---------------------------------------------------------------- 浏览历史（批 2）
-- 同一商品只留一条，用 viewed_at 排序；重复浏览走 upsert 累加 view_count。
-- 不保留全部流水，是为了让"最近看过什么"这类查询永远只扫很少的行。
CREATE TABLE IF NOT EXISTS biz.browse_history (
    id         bigserial PRIMARY KEY,
    user_id    bigint      NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    product_id bigint      NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    view_count int         NOT NULL DEFAULT 1,
    viewed_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uk_history_user_product UNIQUE (user_id, product_id)
);
CREATE INDEX IF NOT EXISTS idx_history_user ON biz.browse_history (user_id, viewed_at DESC);

-- ---------------------------------------------------------------- 订单（批 3）
-- 状态机：CREATED → PAID → (已完成) / CANCELLED
--   * 只有 CREATED 能取消；取消时按 order_item 回补库存
--   * idem_key 由客户端生成，唯一索引兜住"重复提交"（重试/连点/网络重发）
--   * total_amount 是下单那一刻算出来的，不随后续调价变化
CREATE TABLE IF NOT EXISTS biz.orders (
    id           bigserial PRIMARY KEY,
    order_no     varchar(32)   NOT NULL UNIQUE,
    user_id      bigint        NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    status       varchar(16)   NOT NULL DEFAULT 'CREATED',
    total_amount numeric(10,2) NOT NULL,
    idem_key     varchar(64),
    created_at   timestamptz   NOT NULL DEFAULT now(),
    paid_at      timestamptz,
    cancelled_at timestamptz,
    CONSTRAINT ck_orders_status CHECK (status IN ('CREATED', 'PAID', 'CANCELLED'))
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_orders_idem ON biz.orders (idem_key) WHERE idem_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_user ON biz.orders (user_id, created_at DESC);

-- 订单行保存"下单那一刻"的型号与价格快照：
-- 商品改名或调价后，历史订单必须还能原样显示，不能跟着变。
CREATE TABLE IF NOT EXISTS biz.order_item (
    id             bigserial PRIMARY KEY,
    order_id       bigint        NOT NULL REFERENCES biz.orders(id) ON DELETE CASCADE,
    sku_id         bigint        NOT NULL REFERENCES biz.product_sku(id),
    product_id     bigint        NOT NULL REFERENCES biz.product(id),
    model_snapshot varchar(128)  NOT NULL,
    price_snapshot numeric(10,2) NOT NULL,
    qty            int           NOT NULL DEFAULT 1 CHECK (qty > 0)
);
CREATE INDEX IF NOT EXISTS idx_order_item_order ON biz.order_item (order_id);

COMMIT;
