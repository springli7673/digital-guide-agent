-- ============================================================================
-- 购物车 / 订单：把上一版按 sku_id 建的表改成按 product_id
--
-- 原因：探针显示 138 商品 ↔ 138 SKU，每个商品只有一条 SKU（伪变体），
-- 按 sku_id 建模只会多一层失败路径。表当前是空的，直接重建最干净。
--
-- 价格铁律：金额只认 biz.product.price_ref。
-- product_sku.price_ref 里还有 86 条是顶配价（历史遗留），一律不读。
-- ============================================================================

BEGIN;

DROP TABLE IF EXISTS biz.cart_item;
CREATE TABLE biz.cart_item (
    id             bigserial PRIMARY KEY,
    user_id        bigint        NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    product_id     bigint        NOT NULL REFERENCES biz.product(id) ON DELETE CASCADE,
    qty            int           NOT NULL DEFAULT 1 CHECK (qty > 0 AND qty <= 99),
    -- 加购时的价格快照：只用来提示"价格变了"，不参与结算计算
    price_snapshot numeric(10,2) NOT NULL,
    created_at     timestamptz   NOT NULL DEFAULT now(),
    updated_at     timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT uk_cart_user_product UNIQUE (user_id, product_id)
);
CREATE INDEX IF NOT EXISTS idx_cart_user ON biz.cart_item (user_id);

DROP TABLE IF EXISTS biz.order_item;
DROP TABLE IF EXISTS biz.orders;

CREATE TABLE biz.orders (
    id           bigserial PRIMARY KEY,
    order_no     varchar(32)   NOT NULL UNIQUE,
    user_id      bigint        NOT NULL REFERENCES biz.users(id) ON DELETE CASCADE,
    status       varchar(16)   NOT NULL DEFAULT 'PAID',
    total_amount numeric(10,2) NOT NULL,
    idem_key     varchar(64),
    created_at   timestamptz   NOT NULL DEFAULT now(),
    paid_at      timestamptz,
    CONSTRAINT ck_orders_status CHECK (status IN ('CREATED', 'PAID', 'CANCELLED'))
);
-- 幂等：同一个 idem_key 只能落一单。应用层先查一次是快路径，这里才是真正的兜底。
CREATE UNIQUE INDEX uk_orders_idem ON biz.orders (idem_key) WHERE idem_key IS NOT NULL;
CREATE INDEX idx_orders_user ON biz.orders (user_id, created_at DESC);

CREATE TABLE biz.order_item (
    id             bigserial PRIMARY KEY,
    order_id       bigint        NOT NULL REFERENCES biz.orders(id) ON DELETE CASCADE,
    product_id     bigint        NOT NULL REFERENCES biz.product(id),
    model_snapshot varchar(128)  NOT NULL,
    price_snapshot numeric(10,2) NOT NULL,
    qty            int           NOT NULL DEFAULT 1 CHECK (qty > 0)
);
CREATE INDEX idx_order_item_order ON biz.order_item (order_id);

COMMIT;
