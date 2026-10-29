-- 合并重复机型：保留最低配版本，删除其余
-- 由 tools/merge_duplicates.py 生成，可重复执行（幂等）
--
-- biz.product_sku / biz.review 都是 ON DELETE CASCADE，删商品会连带删掉，不用手工清理。
--
-- ⚠️ 顺序很重要：必须先 DELETE 再 UPDATE。biz.product 上有唯一约束
--    (brand_id, model)，先改名会和待删除的那条撞上，整批回滚。
-- 执行：psql -U postgres -d digital_guide -f db/merge_duplicates.sql

BEGIN;

DELETE FROM biz.product WHERE specs->>'source_id' = '2141420';  -- iPhone Air 512GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2141421';  -- iPhone Air 1TB
DELETE FROM biz.product WHERE specs->>'source_id' = '2161776';  -- X300s16GB/+512GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2164025';  -- Pura 90 12GB+512GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2164026';  -- Pura 90 16GB+512GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2161467';  -- 畅享90 Pro Max 256GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2161468';  -- 畅享90 Pro Max 512GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2161469';  -- 畅享90 Plus 256GB
DELETE FROM biz.product WHERE specs->>'source_id' = '2161471';  -- 畅享 90 256GB

UPDATE biz.product SET model = 'iPhone Air' WHERE specs->>'source_id' = '2139686';
UPDATE biz.product SET model = 'X300s' WHERE specs->>'source_id' = '2161777';
UPDATE biz.product SET model = 'Pura 90' WHERE specs->>'source_id' = '2162693';
UPDATE biz.product SET model = '畅享90 Pro Max' WHERE specs->>'source_id' = '2160696';
UPDATE biz.product SET model = '畅享90 Plus' WHERE specs->>'source_id' = '2160695';
UPDATE biz.product SET model = '畅享 90' WHERE specs->>'source_id' = '2161470';

COMMIT;
