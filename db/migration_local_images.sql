-- 商品图本地化：把 ZOL 图床外链换成本地静态图 /img/products/{source_id}.webp
--
-- 前置：先跑 python tools/fetch_images.py，图要落在 web-vite/public/img/products/
-- 幂等：只动还指向 zol-img.com.cn 的行，重跑无副作用
-- 执行：psql -U postgres -d digital_guide -f db/migration_local_images.sql

BEGIN;

UPDATE biz.product
SET image_url = '/img/products/' || (specs ->> 'source_id') || '.webp',
    specs = jsonb_set(
        specs,
        '{image_thumb}',
        to_jsonb('/img/products/' || (specs ->> 'source_id') || '.webp'),
        true
    )
WHERE specs ->> 'source_id' IS NOT NULL
  AND image_url LIKE '%zol-img.com.cn%';

COMMIT;
