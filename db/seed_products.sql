-- 由 tools/export_sql.py 自动生成，可重复执行（每次全量重建商品目录）
-- 商品 147 款，生成时间 2026-10-27T18:34:02
BEGIN;

-- 1. 类目（权重配置）
INSERT INTO biz.category(code, name, spec_schema, sort)
VALUES ('phone', '手机', $json${"battery_mah": {"label": "电池容量", "unit": "mAh", "better": "higher", "weight": 1.0}, "charge_w": {"label": "充电功率", "unit": "W", "better": "higher", "weight": 0.7}, "weight_g": {"label": "重量", "unit": "g", "better": "lower", "weight": 0.5}, "image_score": {"label": "影像梯队", "unit": "分", "better": "higher", "weight": 1.0}, "dxo_camera": {"label": "DXO 影像", "unit": "分", "better": "higher", "weight": 0.5}, "rear_mp": {"label": "后置主摄", "unit": "万像素", "better": "higher", "weight": 0.4}, "cpu_score": {"label": "处理器", "unit": "分", "better": "higher", "weight": 0.8}, "ram": {"label": "运行内存", "unit": "GB", "better": "higher", "weight": 0.6}, "refresh_hz": {"label": "刷新率", "unit": "Hz", "better": "higher", "weight": 0.4}, "screen_inch": {"label": "屏幕尺寸", "unit": "英寸", "better": "higher", "weight": 0.3}}$json$::jsonb, 1)
ON CONFLICT (code) DO UPDATE SET spec_schema = EXCLUDED.spec_schema;

-- 2. 全量重建商品目录（先清空，保证与 products.json 一致）
DELETE FROM biz.product_sku WHERE product_id IN (SELECT id FROM biz.product);
DELETE FROM biz.review WHERE product_id IN (SELECT id FROM biz.product);
DELETE FROM biz.product;
DELETE FROM biz.brand;

-- 3. 商品
-- 苹果 iPhone Duo
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone Duo', '苹果iPhone Duo（1TB）',
       DATE '2026-10-16',
       21499,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/927/ceusM4bLJvA6M.png',
       $json${"display": {"rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "7.6英寸", "launch": "2026年10月16日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟，IP68", "rear_camera": "融合式主摄", "front_camera": "Center Stage 前置摄像头", "cpu_source": "同价位估算"}, "metrics": {"screen_inch": 7.6, "rom": 1024.0, "image_score": 40.0, "cpu_score": 360}, "source": "zol", "source_id": "2177484", "url": "https://detail.zol.com.cn/cell_phone/index2177484.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/927/ceusM4bLJvA6M.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '1TB', 21499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone Duo'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 18 Pro Max
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 18 Pro Max', '苹果iPhone 18 Pro Max（2TB）',
       NULL,
       21499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/929/ceTQIpjIb8Eg.jpg',
       $json${"display": {"rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.9英寸", "resolution": "2868x1320像素", "refresh_hz": "120Hz", "weight_g": "231g", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟，IP68", "rear_camera": "460ppi", "front_camera": "Center Stage 前置摄像头", "cpu_source": "同价位估算"}, "metrics": {"weight_g": 231.0, "screen_inch": 6.9, "refresh_hz": 120.0, "rom": 256.0, "image_score": 100.0, "cpu_score": 420}, "source": "zol", "source_id": "2177488", "url": "https://detail.zol.com.cn/cell_phone/index2177488.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/929/ceTQIpjIb8Eg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '2TB', 21499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 18 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 18 Pro
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 18 Pro', '苹果iPhone 18 Pro（2TB）',
       DATE '2026-09-18',
       20499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/919/cewnUwqgMGCa.jpg',
       $json${"display": {"cpu": "苹果 A20 Pro ， 手机性能排行", "rom": "2TB 41万张照片 17.1万首歌曲", "screen_inch": "6.3英寸", "resolution": "2622x1206px", "refresh_hz": "120Hz", "charge_w": "60w", "weight_g": "211g", "launch": "2026年9月18日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟，IP68", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 后置摄像头3：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a20pro"}, "metrics": {"charge_w": 60.0, "weight_g": 211.0, "screen_inch": 6.3, "refresh_hz": 120.0, "rom": 2048.0, "rear_mp": 4800.0, "cpu_score": 420, "dxo_camera": 172.0, "image_score": 85.0}, "source": "zol", "source_id": "2177482", "url": "https://detail.zol.com.cn/cell_phone/index2177482.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/919/cewnUwqgMGCa.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '2TB', 20499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 18 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate XT 2 非凡大师
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate XT 2 非凡大师', '华为Mate XT 2 非凡大师（16GB/256GB）',
       DATE '2026-09-07',
       19999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/276_800x600/692/ceo3f9SWfl8zo.jpg',
       $json${"display": {"cpu": "麒麟 9050 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "10.2英寸", "resolution": "2232x3184像素", "refresh_hz": "90Hz", "battery_mah": "5600mAh 大电池", "charge_w": "66w", "weight_g": "299g", "launch": "2026年9月7日", "nfc": "支持NFC：读卡器模式、点对点模式、卡模拟模式（华为钱包支付，SIM 卡支付，HCE 支付）", "waterproof": "IP58、IP59", "rear_camera": "382ppi", "front_camera": "内屏前置摄像头", "cpu_tier_name": "麒麟9050pro"}, "metrics": {"battery_mah": 5600.0, "charge_w": 66.0, "weight_g": 299.0, "screen_inch": 10.2, "refresh_hz": 90.0, "ram": 16.0, "rom": 256.0, "cpu_score": 225, "image_score": 70.0}, "source": "zol", "source_id": "2177211", "url": "https://detail.zol.com.cn/cell_phone/index2177211.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/276_320x240/692/ceo3f9SWfl8zo.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/256GB', 19999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate XT 2 非凡大师'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 90 RS 非凡大师
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 90 RS 非凡大师', '华为Mate 90 RS 非凡大师（16GB/2TB）',
       DATE '2026-10-01',
       18999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/835/ce5pZf02FYUgA.png',
       $json${"display": {"cpu": "麒麟 9050 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "2TB 41万张照片 17.1万首歌曲", "screen_inch": "6.9英寸", "resolution": "2848x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6800mAh 大电池", "charge_w": "100w（20V/5A）", "weight_g": "248g", "launch": "2026年10月1日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：2亿像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9050pro"}, "metrics": {"battery_mah": 6800.0, "charge_w": 100.0, "weight_g": 248.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 2048.0, "rear_mp": 5000.0, "cpu_score": 225, "image_score": 100.0}, "source": "zol", "source_id": "2179252", "url": "https://detail.zol.com.cn/cell_phone/index2179252.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/835/ce5pZf02FYUgA.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/2TB', 18999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 90 RS 非凡大师'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 17 Pro Max
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 17 Pro Max', '苹果iPhone 17 Pro Max（2TB）',
       DATE '2025-09-19',
       17999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/273_800x600/480/ceVflFVrLFLH6.jpg',
       $json${"display": {"cpu": "苹果 A19 Pro ， 手机性能排行", "rom": "2TB 41万张照片 17.1万首歌曲", "screen_inch": "6.9英寸", "resolution": "2868x1320px", "refresh_hz": "120Hz", "weight_g": "231g", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟，IP68", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 后置摄像头3：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19pro"}, "metrics": {"weight_g": 231.0, "screen_inch": 6.9, "refresh_hz": 120.0, "rom": 2048.0, "rear_mp": 4800.0, "cpu_score": 360, "dxo_camera": 151.0, "image_score": 70.0}, "source": "zol", "source_id": "2141419", "url": "https://detail.zol.com.cn/cell_phone/index2141419.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/273_320x240/480/ceVflFVrLFLH6.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '2TB', 17999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 17 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 18 Fold
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '18 Fold', '小米18 Fold(16GB/1TB/陶瓷特别版)',
       DATE '2026-09-07',
       15999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/463/ceeOVI0MiDzTA.png',
       $json${"display": {"cpu": "玄戒 O3 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：7.58英寸 副：5.38英寸", "resolution": "主：2364x1672px 副：1712x1168px", "refresh_hz": "120Hz", "battery_mah": "6000mAh 大电池", "charge_w": "67W 小米澎湃有线秒充", "weight_g": "219g", "os": "Xiaomi HyperOS 4", "launch": "2026年9月7日", "nfc": "支持NFC", "waterproof": "IPX8", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：1600万像素", "cpu_tier_name": "玄戒o3"}, "metrics": {"battery_mah": 6000.0, "charge_w": 67.0, "weight_g": 219.0, "screen_inch": 7.58, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 200, "image_score": 70.0}, "source": "zol", "source_id": "2177243", "url": "https://detail.zol.com.cn/cell_phone/index2177243.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/463/ceeOVI0MiDzTA.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/陶瓷特别版', 15999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '18 Fold'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura X Max
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura X Max', '华为Pura X Max(16GB/1TB/典藏版)',
       DATE '2026-04-20',
       13999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/987/ceMZpR1N7UVCs.png',
       $json${"display": {"cpu": "海思 麒麟9030 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：7.7英寸 副：5.4英寸", "resolution": "主：2584x1828px 副：1848x1264px", "refresh_hz": "120Hz", "battery_mah": "5300mAh 大电池", "charge_w": "66w", "weight_g": "229g", "os": "HarmonyOS 6.1", "launch": "2026年04月20日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP58，IP59）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1250万像素 后置摄像头3：5000万像素 前置摄像头1：800万像素 前置摄像头2：800万像素", "cpu_tier_name": "麒麟9030pro"}, "metrics": {"battery_mah": 5300.0, "charge_w": 66.0, "weight_g": 229.0, "screen_inch": 7.7, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 195, "image_score": 70.0}, "source": "zol", "source_id": "2163927", "url": "https://detail.zol.com.cn/cell_phone/index2163927.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/987/ceMZpR1N7UVCs.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/典藏版', 13999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura X Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 16 Pro Max
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 16 Pro Max', '苹果iPhone 16 Pro Max（1TB）',
       DATE '2024-09-20',
       13999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/269_800x600/554/ce5kCxbsxgjDc.jpg',
       $json${"display": {"cpu": "苹果 A18 Pro ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2868x1320px", "refresh_hz": "120Hz", "weight_g": "227g", "launch": "2024年9月20日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 后置摄像头3：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a18pro"}, "metrics": {"weight_g": 227.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 8.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 305, "dxo_camera": 161.0, "image_score": 70.0}, "source": "zol", "source_id": "2105475", "url": "https://detail.zol.com.cn/cell_phone/index2105475.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/269_320x240/554/ce5kCxbsxgjDc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '1TB', 13999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 16 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 15 Pro Max
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 15 Pro Max', '苹果iPhone 15 Pro Max（1TB）',
       DATE '2023-09-22',
       13999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/268_800x600/417/cejVFmipY9YZw.png',
       $json${"display": {"cpu": "苹果 A17 Pro ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.7英寸", "resolution": "2796x1290px", "refresh_hz": "120Hz", "charge_w": "27w", "weight_g": "221g", "os": "iOS 17", "launch": "2023年09月22日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：1200万像素 后置摄像头3：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a17pro"}, "metrics": {"charge_w": 27.0, "weight_g": 221.0, "screen_inch": 6.7, "refresh_hz": 120.0, "ram": 8.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 205, "dxo_camera": 154.0, "image_score": 55.0}, "source": "zol", "source_id": "1896187", "url": "https://detail.zol.com.cn/cell_phone/index1896187.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/268_320x240/417/cejVFmipY9YZw.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '1TB', 13999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 15 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 90 Pro Max 典藏版
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 90 Pro Max 典藏版', '华为Mate 90 Pro Max 典藏版（16GB+1TB）',
       DATE '2026-10-01',
       12999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/554/cehTd0bHwsqxY.png',
       $json${"display": {"cpu": "麒麟 9050 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2848x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6800mAh 大电池", "charge_w": "100w（20V/5A）", "weight_g": "235g", "launch": "2026年10月1日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：2亿像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9050pro"}, "metrics": {"battery_mah": 6800.0, "charge_w": 100.0, "weight_g": 235.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 225, "image_score": 100.0}, "source": "zol", "source_id": "2179254", "url": "https://detail.zol.com.cn/cell_phone/index2179254.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/554/cehTd0bHwsqxY.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB+1TB', 12999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 90 Pro Max 典藏版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 17 Pro
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 17 Pro', '苹果iPhone 17 Pro（1TB）',
       DATE '2025-09-19',
       12999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/273_800x600/466/ceeLWUMuuae.jpg',
       $json${"display": {"cpu": "苹果 A19 Pro ， 手机性能排行", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.3英寸", "resolution": "2622x1206px", "refresh_hz": "120Hz", "weight_g": "204g", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟，IP68", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 后置摄像头3：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19pro"}, "metrics": {"weight_g": 204.0, "screen_inch": 6.3, "refresh_hz": 120.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 360, "dxo_camera": 168.0, "image_score": 70.0}, "source": "zol", "source_id": "2141416", "url": "https://detail.zol.com.cn/cell_phone/index2141416.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/273_320x240/466/ceeLWUMuuae.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '1TB', 12999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 17 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Robot Phone
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Robot Phone', '荣耀Robot Phone（16GB/1TB）',
       DATE '2026-08-12',
       12999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/276_800x600/996/ceMurMa75h5GU.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.31英寸", "resolution": "2640x1216px", "refresh_hz": "120Hz", "battery_mah": "7060mAh 大电池", "charge_w": "120w", "weight_g": "248g", "os": "MagicOS 10", "launch": "2026年8月12日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP54）", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7060.0, "charge_w": 120.0, "weight_g": 248.0, "screen_inch": 6.31, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 40.0}, "source": "zol", "source_id": "2174819", "url": "https://detail.zol.com.cn/cell_phone/index2174819.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/276_320x240/996/ceMurMa75h5GU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 12999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Robot Phone'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 16 Pro
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 16 Pro', '苹果iPhone 16 Pro（1TB）',
       DATE '2024-09-20',
       12999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/269_800x600/722/ce2WjFXcpwQTs.jpg',
       $json${"display": {"cpu": "苹果 A18 Pro ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.3英寸", "resolution": "2622x1206px", "refresh_hz": "120Hz", "weight_g": "199g", "launch": "2024年9月20日", "nfc": "支持NFC", "waterproof": "支持，在6米深的水下停留时间最长可达30分钟", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 后置摄像头3：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a18pro"}, "metrics": {"weight_g": 199.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 8.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 305, "dxo_camera": 157.0, "image_score": 70.0}, "source": "zol", "source_id": "2105471", "url": "https://detail.zol.com.cn/cell_phone/index2105471.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/269_320x240/722/ce2WjFXcpwQTs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '1TB', 12999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 16 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone Air 1TB
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone Air 1TB', 'Apple（苹果）iPhone Air 1TB',
       DATE '2025-09-19',
       11999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/273_800x600/566/ceWUT0JAJFQnw.jpg',
       $json${"display": {"cpu": "苹果 A19 Pro ， 手机性能排行", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.5英寸", "resolution": "2736x1260px", "refresh_hz": "120Hz", "charge_w": "20w", "weight_g": "165g", "os": "iOS 26", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19pro"}, "metrics": {"charge_w": 20.0, "weight_g": 165.0, "screen_inch": 6.5, "refresh_hz": 120.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 360, "image_score": 40.0}, "source": "zol", "source_id": "2141421", "url": "https://detail.zol.com.cn/cell_phone/index2141421.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/273_320x240/566/ceWUT0JAJFQnw.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 11999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone Air 1TB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find N6
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find N6', 'OPPO Find N6(16GB/1TB/卫星版)',
       DATE '2026-03-20',
       11999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/274_800x600/611/cei7FtrME4Fkc.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：8.12英寸 副：6.62英寸", "resolution": "主：2480x2248px 副：2616x1140px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6000mAh 大电池", "charge_w": "80w", "weight_g": "225g", "os": "ColorOS 16", "launch": "2026年3月20日", "nfc": "支持NFC", "waterproof": "IP59&IP58&IP56满级防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：2000万像素 前置摄像头2：2000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 6000.0, "charge_w": 80.0, "weight_g": 225.0, "screen_inch": 8.12, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2160878", "url": "https://detail.zol.com.cn/cell_phone/index2160878.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/274_320x240/611/cei7FtrME4Fkc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/卫星版', 11999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find N6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Magic V6
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Magic V6', '荣耀Magic V6(16GB/1TB)',
       DATE '2026-03-10',
       11999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/274_800x600/80/ceDSAICPmtr8A.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：7.95英寸 副：6.52英寸", "resolution": "主：2352x2172px 副：2420x1080px", "refresh_hz": "120Hz", "battery_mah": "7150mAh 大电池", "charge_w": "120w", "weight_g": "224g", "os": "MagicOS 10.0", "launch": "2026年3月10日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68&IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：6400万像素 前置摄像头1：2000万像素 前置摄像头2：2000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7150.0, "charge_w": 120.0, "weight_g": 224.0, "screen_inch": 7.95, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 70.0}, "source": "zol", "source_id": "2158946", "url": "https://detail.zol.com.cn/cell_phone/index2158946.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/274_320x240/80/ceDSAICPmtr8A.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 11999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Magic V6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X Fold6
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X Fold6', 'vivo X Fold6(16GB/1TB/折叠专业影像套装)',
       NULL,
       11299,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/15/ceHknhdl73mlQ.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500超能版 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "主：8.02英寸 副：6.51英寸", "resolution": "2504x2312px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "80w", "weight_g": "228g", "os": "OriginOS 6 Fold", "nfc": "支持NFC", "waterproof": "IPX8&IPX9级抗水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：2000万像素 前置摄像头2：2000万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 7000.0, "charge_w": 80.0, "weight_g": 228.0, "screen_inch": 8.02, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 70.0}, "source": "zol", "source_id": "2170558", "url": "https://detail.zol.com.cn/cell_phone/index2170558.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/15/ceHknhdl73mlQ.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/折叠专业影像套装', 11299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X Fold6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 18 Pro Max
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '18 Pro Max', '小米18 Pro Max(16GB/1TB)',
       DATE '2026-09-23',
       10199,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/268/ceNQdBAmwVjYI.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：6.9英寸 副：2.9英寸", "resolution": "主：2624x1208px 副：976x596px", "refresh_hz": "120Hz", "battery_mah": "8500mAh 大电池", "charge_w": "100w", "weight_g": "235g", "os": "Xiaomi HyperOS 4", "launch": "2026年09月23日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen6"}, "metrics": {"battery_mah": 8500.0, "charge_w": 100.0, "weight_g": 235.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 390, "image_score": 100.0}, "source": "zol", "source_id": "2178755", "url": "https://detail.zol.com.cn/cell_phone/index2178755.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/268/ceNQdBAmwVjYI.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 10199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '18 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 90 Pro
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 90 Pro', '华为Mate 90 Pro(16GB/1TB)',
       DATE '2026-10-01',
       9999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/662/ceypDgmPedt32.png',
       $json${"display": {"cpu": "海思 麒麟 9035 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.75英寸", "resolution": "2832x1280px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6600mAh 大电池", "charge_w": "100w（20V/5A）", "weight_g": "222g", "os": "HarmonyOS 7.0", "launch": "2026年10月01日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：5000万像素 后置摄像头4：150万像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9035"}, "metrics": {"battery_mah": 6600.0, "charge_w": 100.0, "weight_g": 222.0, "screen_inch": 6.75, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 200, "image_score": 70.0}, "source": "zol", "source_id": "2179259", "url": "https://detail.zol.com.cn/cell_phone/index2179259.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/662/ceypDgmPedt32.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 90 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 18 Pro
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '18 Pro', '小米18 Pro（16GB/1TB/特别版）',
       DATE '2026-09-23',
       9999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/73/ceqUxWoAcBKQ.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：6.4英寸 副：2.7英寸", "resolution": "主：2436x1120px 副：912x596px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "203g", "os": "Xiaomi HyperOS 4", "launch": "2026年09月23日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen6"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 203.0, "screen_inch": 6.4, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 390, "image_score": 70.0}, "source": "zol", "source_id": "2178750", "url": "https://detail.zol.com.cn/cell_phone/index2178750.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/73/ceqUxWoAcBKQ.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/特别版', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '18 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 90 Pro Max
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 90 Pro Max', '华为Mate 90 Pro Max（16GB/512GB）',
       DATE '2026-10-01',
       9999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/276_800x600/904/cexWe26e9ALpk.png',
       $json${"display": {"cpu": "麒麟 9050 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.9英寸", "resolution": "2848x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6800mAh 大电池", "charge_w": "100w（20V/5A）", "weight_g": "234g", "launch": "2026年10月1日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：2亿像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9050pro"}, "metrics": {"battery_mah": 6800.0, "charge_w": 100.0, "weight_g": 234.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 225, "image_score": 85.0}, "source": "zol", "source_id": "2179253", "url": "https://detail.zol.com.cn/cell_phone/index2179253.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/276_320x240/904/cexWe26e9ALpk.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 90 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone Air 512GB
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone Air 512GB', 'Apple（苹果）iPhone Air 512GB',
       DATE '2025-09-19',
       9999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/273_800x600/566/ceWUT0JAJFQnw.jpg',
       $json${"display": {"cpu": "苹果 A19 Pro ， 手机性能排行", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.5英寸", "resolution": "2736x1260px", "refresh_hz": "120Hz", "charge_w": "20w", "weight_g": "165g", "os": "iOS 26", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19pro"}, "metrics": {"charge_w": 20.0, "weight_g": 165.0, "screen_inch": 6.5, "refresh_hz": 120.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 360, "image_score": 40.0}, "source": "zol", "source_id": "2141420", "url": "https://detail.zol.com.cn/cell_phone/index2141420.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/273_320x240/566/ceWUT0JAJFQnw.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone Air 512GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 16 Plus
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 16 Plus', '苹果iPhone 16 Plus（512GB）',
       DATE '2024-09-20',
       9999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/269_800x600/529/cefaehkn19oEA.jpg',
       $json${"display": {"cpu": "苹果 A18 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.7英寸", "resolution": "2796x1290px", "weight_g": "199g", "os": "iOS 18", "launch": "2024年9月20日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a18"}, "metrics": {"weight_g": 199.0, "screen_inch": 6.7, "ram": 8.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 250, "image_score": 40.0}, "source": "zol", "source_id": "2105473", "url": "https://detail.zol.com.cn/cell_phone/index2105473.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/269_320x240/529/cefaehkn19oEA.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 16 Plus'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 15 Plus
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 15 Plus', '苹果iPhone 15 Plus（512GB）',
       DATE '2023-09-22',
       9999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/268_800x600/480/ceEW8YjGZbEo.png',
       $json${"display": {"cpu": "苹果 A16 ， 手机性能排行", "ram": "6GB 游戏运行良好", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.7英寸", "resolution": "2796x1290px", "battery_mah": "3279mAh 小电池", "weight_g": "201g", "os": "iOS 17", "launch": "2023年09月22日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a16"}, "metrics": {"battery_mah": 3279.0, "weight_g": 201.0, "screen_inch": 6.7, "ram": 6.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 165, "dxo_camera": 145.0, "image_score": 40.0}, "source": "zol", "source_id": "1896289", "url": "https://detail.zol.com.cn/cell_phone/index1896289.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/268_320x240/480/ceEW8YjGZbEo.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 9999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 15 Plus'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 80 Pro Max 风驰版
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 80 Pro Max 风驰版', 'HUAWEI Mate 80 Pro Max 风驰版(16GB/1TB)',
       DATE '2026-03-23',
       9499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/693/ceYAsbGVNtYDU.png',
       $json${"display": {"cpu": "海思 麒麟9030 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2848x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6000mAh 大电池", "charge_w": "100w（20V/5A）", "weight_g": "239g", "launch": "2026年3月23日", "nfc": "支持NFC", "waterproof": "IP69&IP68等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：5000万像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9030pro"}, "metrics": {"battery_mah": 6000.0, "charge_w": 100.0, "weight_g": 239.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 195, "image_score": 70.0}, "source": "zol", "source_id": "2161459", "url": "https://detail.zol.com.cn/cell_phone/index2161459.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/693/ceYAsbGVNtYDU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 9499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 80 Pro Max 风驰版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find X10 Pro Max
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find X10 Pro Max', 'OPPO Find X10 Pro Max(16GB/1TB)',
       DATE '2026-09-22',
       8999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/649/ce2JvOVTuhKi6.png',
       $json${"display": {"cpu": "联发科 天玑 9600 Pro ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "144Hz", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "235g", "os": "ColorOS 17", "launch": "2026年9月22日", "nfc": "支持NFC", "waterproof": "IP66 &IP68 &IP69防水防尘", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：2亿像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9600pro"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 235.0, "screen_inch": 6.78, "refresh_hz": 144.0, "ram": 16.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 400, "image_score": 100.0}, "source": "zol", "source_id": "2178475", "url": "https://detail.zol.com.cn/cell_phone/index2178475.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/649/ce2JvOVTuhKi6.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 8999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find X10 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 15
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 15', '苹果iPhone 15（512GB）',
       DATE '2023-09-22',
       8999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/268_800x600/518/cesmnW8HBMrMI.png',
       $json${"display": {"cpu": "苹果 A16 ， 手机性能排行", "ram": "6GB 游戏运行良好", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.1英寸", "resolution": "2556x1179px", "battery_mah": "3279mAh 小电池", "weight_g": "171g", "os": "iOS 17", "launch": "2023年09月22日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a16"}, "metrics": {"battery_mah": 3279.0, "weight_g": 171.0, "screen_inch": 6.1, "ram": 6.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 165, "dxo_camera": 145.0, "image_score": 40.0}, "source": "zol", "source_id": "1896189", "url": "https://detail.zol.com.cn/cell_phone/index1896189.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/268_320x240/518/cesmnW8HBMrMI.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 8999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 15'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 MIX FOLD 4
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'MIX FOLD 4', '小米MIX FOLD 4(12GB/256GB)',
       DATE '2024-07-19',
       8999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/268_800x600/486/ceIxiDcI0DloY.jpg',
       $json${"display": {"cpu": "高通骁龙8 Gen3 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "主：7.98英寸 副：6.56英寸", "resolution": "主：2488x2224px 副：2520x1080px", "refresh_hz": "120Hz", "battery_mah": "5100mAh 大电池", "charge_w": "67W 小米澎湃有线秒充，手机支持 QC4 / QC3+ / QC3.0 / QC2.0 / PD3.0 / PD2.0 快充协议+MI FC 2.0 快充", "weight_g": "龙胆蓝、白色、黑色：226g 龙鳞纤维版：228g", "os": "Xiaomi HyperOS", "launch": "2024年7月19日", "nfc": "支持NFC", "waterproof": "IPX8", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：1000万像素 后置摄像头4：1200万像素 前置摄像头1：1600万像素 前置摄像头2：1600万像素", "cpu_tier_name": "骁龙8gen3"}, "metrics": {"battery_mah": 5100.0, "charge_w": 67.0, "weight_g": 226.0, "screen_inch": 7.98, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 210, "image_score": 70.0}, "source": "zol", "source_id": "2086684", "url": "https://detail.zol.com.cn/cell_phone/index2086684.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/268_320x240/486/ceIxiDcI0DloY.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 8999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = 'MIX FOLD 4'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 16
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '16', '一加16（16GB/1TB）',
       DATE '2026-10-12',
       8499,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/111/cej0Kp4eoWZmA.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "165Hz", "battery_mah": "9000mAh 大电池", "charge_w": "100w", "weight_g": "220g", "os": "ColorOS 17", "launch": "2026年10月12日", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69/IP69K满级防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen6"}, "metrics": {"battery_mah": 9000.0, "charge_w": 100.0, "weight_g": 220.0, "screen_inch": 6.78, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 390, "image_score": 55.0}, "source": "zol", "source_id": "2180390", "url": "https://detail.zol.com.cn/cell_phone/index2180390.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/111/cej0Kp4eoWZmA.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = '16'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO 16
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '16', 'iQOO 16（16GB/1TB）',
       DATE '2026-09-29',
       8499,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/276_800x600/778/ceYdRRXaVPrug.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.85英寸", "resolution": "3168x1440px", "refresh_hz": "165Hz", "battery_mah": "8400mAh 大电池", "charge_w": "100w", "weight_g": "222.5g", "os": "OriginOS 7", "launch": "2026年9月29日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen6"}, "metrics": {"battery_mah": 8400.0, "charge_w": 100.0, "screen_inch": 6.85, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 390, "image_score": 55.0}, "source": "zol", "source_id": "2179083", "url": "https://detail.zol.com.cn/cell_phone/index2179083.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/276_320x240/778/ceYdRRXaVPrug.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = '16'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Mate 90
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Mate 90', 'HUAWEI Mate 90（12GB/1TB）',
       DATE '2026-10-01',
       8499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/613/ceaHc1JXj0Mk6.png',
       $json${"display": {"cpu": "海思 麒麟 9030 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.75英寸", "resolution": "2832x1280px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6600mAh 大电池", "charge_w": "支持 66w（11V/6A）", "weight_g": "217g", "os": "HarmonyOS 7.0", "launch": "2026年10月01日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：5000万像素 后置摄像头4：150万像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9030"}, "metrics": {"battery_mah": 6600.0, "charge_w": 66.0, "weight_g": 217.0, "screen_inch": 6.75, "refresh_hz": 120.0, "ram": 12.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 165, "image_score": 55.0}, "source": "zol", "source_id": "2179256", "url": "https://detail.zol.com.cn/cell_phone/index2179256.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/613/ceaHc1JXj0Mk6.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Mate 90'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X500 Pro
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X500 Pro', 'vivo X500 Pro(12GB/1TB)',
       DATE '2026-09-21',
       8499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/7/ceFAWQVmsw1ig.jpg',
       $json${"display": {"cpu": "联发科 天玑 9600 Pro ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.36英寸", "resolution": "2660x1216px", "refresh_hz": "144Hz", "battery_mah": "6510mAh 大电池", "charge_w": "90w", "weight_g": "192g", "os": "OriginOS 7", "launch": "2026年9月21日", "nfc": "支持NFC", "waterproof": "IP68+IP69等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：6400万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9600pro"}, "metrics": {"battery_mah": 6510.0, "charge_w": 90.0, "weight_g": 192.0, "screen_inch": 6.36, "refresh_hz": 144.0, "ram": 12.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 400, "image_score": 85.0}, "source": "zol", "source_id": "2178565", "url": "https://detail.zol.com.cn/cell_phone/index2178565.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/7/ceFAWQVmsw1ig.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X500 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Magic9 Pro Max
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Magic9 Pro Max', '荣耀Magic9 Pro Max（16GB/1TB）',
       DATE '2026-09-28',
       8499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/51/ce77f8GOnDo6g.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Extreme Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.8英寸", "resolution": "2868x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "8800mAh 大电池", "charge_w": "100w", "weight_g": "233g", "os": "MagicOS 11", "launch": "2026年9月28日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69及IP69K）", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5500万像素", "cpu_tier_name": "骁龙8eliteextremegen6"}, "metrics": {"battery_mah": 8800.0, "charge_w": 100.0, "weight_g": 233.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 400, "image_score": 100.0}, "source": "zol", "source_id": "2178984", "url": "https://detail.zol.com.cn/cell_phone/index2178984.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/51/ce77f8GOnDo6g.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Magic9 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura X View
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura X View', '华为Pura X View(12GB/1TB)',
       DATE '2026-08-28',
       8499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/847/ce9iQhSY18O8E.png',
       $json${"display": {"cpu": "海思 麒麟 9030S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "主：6.39英寸 副：3.5英寸", "resolution": "主：2232x1320px 副：980x980px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "66w", "weight_g": "201g", "os": "HarmonyOS 5.0.1", "launch": "2026年08月28日", "nfc": "支持NFC ，支持读卡器模式，卡模拟模式（华为钱包支付，SIM卡支付，HCE支付）", "waterproof": "IPX8 级别", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：800万像素 后置摄像头4：150万像素 前置摄像头1：1070万像素", "cpu_tier_name": "麒麟9030s"}, "metrics": {"battery_mah": 7000.0, "charge_w": 66.0, "weight_g": 201.0, "screen_inch": 6.39, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 160, "image_score": 55.0}, "source": "zol", "source_id": "2175632", "url": "https://detail.zol.com.cn/cell_phone/index2175632.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/847/ce9iQhSY18O8E.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura X View'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17 Ultra
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17 Ultra', '小米17 Ultra(16GB/1TB)',
       DATE '2025-12-25',
       8499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/274_800x600/61/ce6GSWSDEymso.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2608x1200px", "refresh_hz": "120Hz", "battery_mah": "6800mAh 大电池", "charge_w": "90w", "weight_g": "223.4g", "os": "Xiaomi HyperOS 3", "launch": "2025年12月25日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 6800.0, "charge_w": 90.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "dxo_camera": 166.0, "image_score": 85.0}, "source": "zol", "source_id": "2152335", "url": "https://detail.zol.com.cn/cell_phone/index2152335.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/274_320x240/61/ce6GSWSDEymso.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 8499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 WIN2
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'WIN2', '荣耀WIN2（16GB/1TB）',
       DATE '2026-10-21',
       7999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/634/cejmaYOnguNU.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen6 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.89英寸", "resolution": "3104x1440px", "refresh_hz": "185Hz", "battery_mah": "10100mAh 大电池", "charge_w": "100w", "weight_g": "237g", "os": "MagicOS 11", "launch": "2026年10月21日", "nfc": "支持NFC", "waterproof": "支持IP68&IP69&IP69K防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen6"}, "metrics": {"battery_mah": 10100.0, "charge_w": 100.0, "weight_g": 237.0, "screen_inch": 6.89, "refresh_hz": 185.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 390, "image_score": 40.0}, "source": "zol", "source_id": "2181341", "url": "https://detail.zol.com.cn/cell_phone/index2181341.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/634/cejmaYOnguNU.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'WIN2'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 17
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 17', '苹果iPhone 17（512GB）',
       DATE '2025-09-19',
       7999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/273_800x600/652/cexwLpRhw8a4o.png',
       $json${"display": {"cpu": "苹果 A19 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.3英寸", "resolution": "2622x1206px", "refresh_hz": "120Hz", "charge_w": "40w", "weight_g": "177g", "os": "iOS 26", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19"}, "metrics": {"charge_w": 40.0, "weight_g": 177.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 8.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 345, "dxo_camera": 157.0, "image_score": 55.0}, "source": "zol", "source_id": "2141414", "url": "https://detail.zol.com.cn/cell_phone/index2141414.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/273_320x240/652/cexwLpRhw8a4o.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 17'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone Air 256GB
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone Air 256GB', 'Apple（苹果）iPhone Air 256GB',
       DATE '2025-09-19',
       7999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/273_800x600/566/ceWUT0JAJFQnw.jpg',
       $json${"display": {"cpu": "苹果 A19 Pro ， 手机性能排行", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.5英寸", "resolution": "2736x1260px", "refresh_hz": "120Hz", "charge_w": "20w", "weight_g": "165g", "os": "iOS 26", "launch": "2025年9月19日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 前置摄像头1：1800万像素", "cpu_tier_name": "a19pro"}, "metrics": {"charge_w": 20.0, "weight_g": 165.0, "screen_inch": 6.5, "refresh_hz": 120.0, "rom": 1024.0, "rear_mp": 4800.0, "cpu_score": 360, "image_score": 40.0}, "source": "zol", "source_id": "2139686", "url": "https://detail.zol.com.cn/cell_phone/index2139686.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/273_320x240/566/ceWUT0JAJFQnw.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone Air 256GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X300s
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X300s', 'vivo X300s(16GB/1TB摄影师套装)',
       DATE '2026-03-30',
       7999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/284/cex1Iara3h7c.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500+ ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.78英寸", "resolution": "2800x1260px", "refresh_hz": "144Hz", "battery_mah": "7100mAh 大电池", "charge_w": "90w", "weight_g": "226g", "os": "OriginOS 6", "launch": "2026年3月30日", "nfc": "支持NFC", "waterproof": "IP68+IP69等级", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9500+"}, "metrics": {"battery_mah": 7100.0, "charge_w": 90.0, "weight_g": 226.0, "screen_inch": 6.78, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 300, "image_score": 55.0}, "source": "zol", "source_id": "2161777", "url": "https://detail.zol.com.cn/cell_phone/index2161777.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/284/cex1Iara3h7c.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB摄影师套装', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X300s'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 16
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 16', '苹果iPhone 16（512GB）',
       DATE '2024-09-20',
       7999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/269_800x600/496/ceqTLEVaV4ZLo.jpg',
       $json${"display": {"cpu": "苹果 A18 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.1英寸", "resolution": "2556x1179px", "weight_g": "170g", "os": "iOS 18", "launch": "2024年9月20日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：1200万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a18"}, "metrics": {"weight_g": 170.0, "screen_inch": 6.1, "ram": 8.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 250, "dxo_camera": 147.0, "image_score": 55.0}, "source": "zol", "source_id": "2105468", "url": "https://detail.zol.com.cn/cell_phone/index2105468.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/269_320x240/496/ceqTLEVaV4ZLo.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 16'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 15 Ultra
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15 Ultra', '小米15 Ultra(16GB/1TB/双卫星版)',
       DATE '2025-03-03',
       7999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/271_800x600/77/ceFfTVaYQQTPg.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.73英寸", "resolution": "3200x1440px", "refresh_hz": "120Hz", "battery_mah": "6000mAh 大电池", "charge_w": "90w", "weight_g": "226g", "os": "Xiaomi HyperOS 2", "launch": "2025年03月03日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 后置摄像头4：20000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 6000.0, "charge_w": 90.0, "weight_g": 226.0, "screen_inch": 6.73, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 285, "dxo_camera": 159.0, "image_score": 85.0}, "source": "zol", "source_id": "2121959", "url": "https://detail.zol.com.cn/cell_phone/index2121959.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/271_320x240/77/ceFfTVaYQQTPg.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/双卫星版', 7999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '15 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO 15 Ultra
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15 Ultra', 'iQOO 15 Ultra （24GB/1TB）',
       DATE '2026-02-04',
       7699,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/274_800x600/53/cerft8GGiIOhU.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "24GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.85英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "7400mAh 大电池", "charge_w": "100w", "weight_g": "227g", "os": "OriginOS 6", "launch": "2026年2月4日", "nfc": "支持NFC（多功能）", "waterproof": "IP68&IP69防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7400.0, "charge_w": 100.0, "weight_g": 227.0, "screen_inch": 6.85, "refresh_hz": 144.0, "ram": 24.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 85.0}, "source": "zol", "source_id": "2156331", "url": "https://detail.zol.com.cn/cell_phone/index2156331.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/274_320x240/53/cerft8GGiIOhU.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '24GB/1TB', 7699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = '15 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura 90 Pro
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura 90 Pro', '华为Pura 90 Pro(16GB/1TB)',
       DATE '2026-04-20',
       7499,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/888/ceDzclcPvxbo.png',
       $json${"display": {"cpu": "海思 麒麟 9030S ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.6英寸", "resolution": "2760x1256px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6000mAh 大电池", "charge_w": "66w", "os": "HarmonyOS 6.1", "launch": "2026年4月20日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1250万像素 后置摄像头3：5000万像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9030s"}, "metrics": {"battery_mah": 6000.0, "charge_w": 66.0, "screen_inch": 6.6, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 160, "image_score": 70.0}, "source": "zol", "source_id": "2163933", "url": "https://detail.zol.com.cn/cell_phone/index2163933.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/888/ceDzclcPvxbo.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 7499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura 90 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find X10
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find X10', 'OPPO Find X10(16GB/1TB)',
       DATE '2026-09-24',
       7499,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/627/ce2wqqMeMDr2E.png',
       $json${"display": {"cpu": "联发科 天玑 9600M ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.59英寸", "resolution": "2768x1272px", "refresh_hz": "普通模式120Hz，部分游戏模式144Hz", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "216g", "os": "ColorOS 17", "launch": "2026-09-24", "nfc": "支持NFC", "waterproof": "P66 & IP68 & IP69 超强防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9600m"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 216.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 335, "image_score": 85.0}, "source": "zol", "source_id": "2178468", "url": "https://detail.zol.com.cn/cell_phone/index2178468.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/627/ce2wqqMeMDr2E.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 7499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find X10'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find X9 Ultra
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find X9 Ultra', 'OPPO Find X9 Ultra(12GB/256GB)',
       DATE '2026-04-21',
       7499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/1/ceBglt9N35UI.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.82英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "7050mAh 大电池", "charge_w": "100w", "weight_g": "236g", "os": "ColorOS 16", "launch": "2026年4月21日", "nfc": "支持NFC", "waterproof": "支持IP66&IP68&IP69满级防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：2亿像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7050.0, "charge_w": 100.0, "weight_g": 236.0, "screen_inch": 6.82, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "dxo_camera": 170.0, "image_score": 85.0}, "source": "zol", "source_id": "2163011", "url": "https://detail.zol.com.cn/cell_phone/index2163011.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/1/ceBglt9N35UI.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 7499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find X9 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 16e
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 16e', '苹果iPhone 16e（512GB）',
       DATE '2025-02-28',
       7499,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/271_800x600/902/ceLpJwxbzvxg2.jpg',
       $json${"display": {"cpu": "苹果 A18 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.1英寸", "resolution": "2532x1170px", "refresh_hz": "60Hz", "charge_w": "30w", "weight_g": "167g", "launch": "2025年2月28日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a18"}, "metrics": {"charge_w": 30.0, "weight_g": 167.0, "screen_inch": 6.1, "refresh_hz": 60.0, "ram": 8.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 250, "image_score": 40.0}, "source": "zol", "source_id": "2121125", "url": "https://detail.zol.com.cn/cell_phone/index2121125.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/271_320x240/902/ceLpJwxbzvxg2.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 7499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 16e'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura X
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura X', 'HUAWEI Pura X(12GB/256GB)',
       DATE '2025-03-30',
       7499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/271_800x600/809/ceiYnWHEnj1Yk.png',
       $json${"display": {"ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "主：6.3英寸 副：3.5英寸", "resolution": "主：2120x1320px 副：980x980px", "refresh_hz": "120Hz", "battery_mah": "4720mAh 大电池", "charge_w": "66w", "weight_g": "193.7g", "os": "HarmonyOS 5.0.1", "launch": "2025年03月30日", "nfc": "支持NFC ，支持读卡器模式，卡模拟模式（华为钱包支付，SIM卡支付，HCE支付）", "waterproof": "IPX8 级别", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：800万像素 后置摄像头4：150万像素 前置摄像头1：1070万像素", "cpu_source": "同价位估算"}, "metrics": {"battery_mah": 4720.0, "charge_w": 66.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "image_score": 55.0, "cpu_score": 166}, "source": "zol", "source_id": "2123956", "url": "https://detail.zol.com.cn/cell_phone/index2123956.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/271_320x240/809/ceiYnWHEnj1Yk.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 7499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura X'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 MIX Flip 2
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'MIX Flip 2', '小米MIX Flip 2（16GB/1TB）',
       DATE '2025-06-26',
       7299,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/272_800x600/385/ceqYHrTvhj3Vg.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：6.86英寸 副：4.01英寸", "resolution": "主：2912x1224px 副：1392x1208px", "refresh_hz": "120Hz", "battery_mah": "5165mAh 大电池", "charge_w": "67w小米澎湃有线秒充", "weight_g": "199g", "os": "Xiaomi HyperOS 2", "launch": "2025年6月26日", "nfc": "支持NFC（多功能）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 5165.0, "charge_w": 67.0, "weight_g": 199.0, "screen_inch": 6.86, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 55.0}, "source": "zol", "source_id": "2131589", "url": "https://detail.zol.com.cn/cell_phone/index2131589.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/272_320x240/385/ceqYHrTvhj3Vg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 7299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = 'MIX Flip 2'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X500 Pro Max
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X500 Pro Max', 'vivo X500 Pro Max(12GB/256GB)',
       DATE '2026-09-21',
       6999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/276_800x600/554/ceKr9CQ71fhs.jpg',
       $json${"display": {"cpu": "联发科 天玑 9600 Pro ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.85英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "8000mAh 大电池", "charge_w": "90w", "weight_g": "192g", "os": "OriginOS 7", "launch": "2026年9月21日", "nfc": "支持NFC", "waterproof": "IP68+IP69等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9600pro"}, "metrics": {"battery_mah": 8000.0, "charge_w": 90.0, "weight_g": 192.0, "screen_inch": 6.85, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 400, "image_score": 100.0}, "source": "zol", "source_id": "2178313", "url": "https://detail.zol.com.cn/cell_phone/index2178313.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/276_320x240/554/ceKr9CQ71fhs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 6999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X500 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X500
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X500', 'vivo X500（12GB/1TB）',
       DATE '2025-09-21',
       6999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/453/ce6Pd3Ztp7thA.jpg',
       $json${"display": {"cpu": "联发科 天玑 9600M ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.59英寸", "resolution": "2750x1260px", "refresh_hz": "144Hz", "battery_mah": "7500mAh 大电池", "charge_w": "90w", "weight_g": "211g", "os": "OriginOS 7", "launch": "2025年9月21日", "nfc": "支持NFC", "waterproof": "IP68+IP69级防尘抗水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：6400万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9600m"}, "metrics": {"battery_mah": 7500.0, "charge_w": 90.0, "weight_g": 211.0, "screen_inch": 6.59, "refresh_hz": 144.0, "ram": 12.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 335, "image_score": 70.0}, "source": "zol", "source_id": "2178563", "url": "https://detail.zol.com.cn/cell_phone/index2178563.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/453/ce6Pd3Ztp7thA.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/1TB', 6999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X500'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X300 Ultra
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X300 Ultra', 'vivo X300 Ultra(12GB/256GB)',
       DATE '2026-03-30',
       6999,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/203/ceKMkMwo764qo.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.82英寸", "resolution": "3168x1440px", "refresh_hz": "120Hz", "battery_mah": "6600mAh 大电池", "charge_w": "100w", "weight_g": "232g", "os": "OriginOS 6", "launch": "2026年3月30日", "nfc": "支持NFC", "waterproof": "IP68+IP69等级", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：2亿像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 6600.0, "charge_w": 100.0, "weight_g": 232.0, "screen_inch": 6.82, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "dxo_camera": 170.0, "image_score": 85.0}, "source": "zol", "source_id": "2161145", "url": "https://detail.zol.com.cn/cell_phone/index2161145.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/203/ceKMkMwo764qo.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 6999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X300 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Magic9
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Magic9', '荣耀Magic9(16GB/1TB)',
       DATE '2026-09-28',
       6999,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/41/ceU515YVyj58k.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.37英寸", "resolution": "2664x1236px", "refresh_hz": "120Hz（1-120）", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "209g", "os": "MagicOS 11", "launch": "2026年9月28日", "nfc": "支持NFC", "waterproof": "IP68和IP69等级", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5500万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 209.0, "screen_inch": 6.37, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2178511", "url": "https://detail.zol.com.cn/cell_phone/index2178511.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/41/ceU515YVyj58k.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 6999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Magic9'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17 Pro Max
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17 Pro Max', '小米17 Pro Max（16GB/1TB）',
       DATE '2025-09-25',
       6999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/273_800x600/359/cezxKsWHgncM6.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：6.9英寸 副：2.9英寸", "resolution": "主：2608x1200px 副：976x596px", "refresh_hz": "120Hz", "battery_mah": "7500mAh 大电池", "charge_w": "100w", "weight_g": "219g", "os": "Xiaomi HyperOS 3", "launch": "2025年09月25日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7500.0, "charge_w": 100.0, "weight_g": 219.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "dxo_camera": 159.0, "image_score": 85.0}, "source": "zol", "source_id": "2143203", "url": "https://detail.zol.com.cn/cell_phone/index2143203.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/273_320x240/359/cezxKsWHgncM6.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 6999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 17e
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 17e', '苹果iPhone 17e（512GB）',
       DATE '2026-03-11',
       6499,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/274_800x600/996/ce9Bd4TAO1dU.png',
       $json${"display": {"cpu": "苹果 A19 ， 手机性能排行", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.1英寸", "resolution": "2532x1170px", "refresh_hz": "60Hz", "weight_g": "170g", "os": "iOS 26", "launch": "2026年3月11日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 前置摄像头1：1200万像素", "cpu_tier_name": "a19"}, "metrics": {"weight_g": 170.0, "screen_inch": 6.1, "refresh_hz": 60.0, "rom": 512.0, "rear_mp": 4800.0, "cpu_score": 345, "image_score": 40.0}, "source": "zol", "source_id": "2159097", "url": "https://detail.zol.com.cn/cell_phone/index2159097.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/274_320x240/996/ce9Bd4TAO1dU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 6499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 17e'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura 90 Pro Max
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura 90 Pro Max', '华为Pura 90 Pro Max(12GB/256GB)',
       DATE '2026-04-20',
       6499,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/866/cetLDfxXCitE.png',
       $json${"display": {"cpu": "海思 麒麟 9030S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.9英寸", "resolution": "2880x1308px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6000mAh 大电池", "charge_w": "100w", "weight_g": "230.5g", "os": "HarmonyOS 6.1", "launch": "2026年4月20日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：4000万像素 后置摄像头3：2亿像素 前置摄像头1：1300万像素", "cpu_tier_name": "麒麟9030s"}, "metrics": {"battery_mah": 6000.0, "charge_w": 100.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 160, "image_score": 70.0}, "source": "zol", "source_id": "2162803", "url": "https://detail.zol.com.cn/cell_phone/index2162803.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/866/cetLDfxXCitE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 6499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura 90 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X100 Ultra
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X100 Ultra', 'vivo X100 Ultra(12GB/256GB)',
       DATE '2024-05-28',
       6499,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/263_800x600/264/ceHozw5ivjZCY.jpg',
       $json${"display": {"cpu": "高通 骁龙8 Gen3 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.78英寸", "resolution": "3200x1440 WQHD+px", "refresh_hz": "120Hz", "battery_mah": "5500mAh 大电池", "charge_w": "80w（11V/7.3A）", "weight_g": "229g", "os": "OriginOS 4", "launch": "2024年5月28日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：2亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8gen3"}, "metrics": {"battery_mah": 5500.0, "charge_w": 80.0, "weight_g": 229.0, "screen_inch": 6.78, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 210, "image_score": 100.0}, "source": "zol", "source_id": "2002105", "url": "https://detail.zol.com.cn/cell_phone/index2002105.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/263_320x240/264/ceHozw5ivjZCY.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 6499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X100 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K100
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K100', 'Redmi K100',
       NULL,
       5999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/576/ce15R2saaaM4o.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.59英寸", "resolution": "2510x1156px", "refresh_hz": "120Hz", "battery_mah": "7100mAh 大电池", "charge_w": "100w", "weight_g": "206g", "os": "Xiaomi HyperOS 3", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 后置摄像头3：5000万像素 前置摄像头1：2000万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 7100.0, "charge_w": 100.0, "weight_g": 206.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 40.0}, "source": "zol", "source_id": "2181679", "url": "https://detail.zol.com.cn/cell_phone/index2181679.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/576/ce15R2saaaM4o.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 5999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K100'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K100 Pro Max
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K100 Pro Max', 'Redmi K100 Pro Max(16GB/1TB)',
       DATE '2026-08-11',
       5999,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/59/ce0TxC2Rq4hbA.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2608x1200px", "refresh_hz": "185Hz", "battery_mah": "9070mAh 大电池", "charge_w": "100w", "weight_g": "238g", "os": "Xiaomi HyperOS 3", "launch": "2026年8月11日", "nfc": "支持NFC（多功能）", "waterproof": "IP68/IP69防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 9070.0, "charge_w": 100.0, "weight_g": 238.0, "screen_inch": 6.9, "refresh_hz": 185.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2174706", "url": "https://detail.zol.com.cn/cell_phone/index2174706.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/59/ce0TxC2Rq4hbA.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K100 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17 Pro
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17 Pro', '小米17 Pro（16GB/1TB）',
       DATE '2025-09-25',
       5999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/273_800x600/160/cehWo7W1VTTyE.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "主：6.3英寸 副：2.7英寸", "resolution": "主：2656x1220px 副：904x572px", "refresh_hz": "120Hz", "battery_mah": "6300mAh 大电池", "charge_w": "100w", "weight_g": "192g", "os": "Xiaomi HyperOS 3", "launch": "2025年09月25日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 6300.0, "charge_w": 100.0, "weight_g": 192.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 85.0}, "source": "zol", "source_id": "2143196", "url": "https://detail.zol.com.cn/cell_phone/index2143196.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/273_320x240/160/cehWo7W1VTTyE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo X300s16GB/+512GB
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X300s16GB/+512GB', 'vivo X300s()16GB/+512GB',
       DATE '2026-03-30',
       5999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/284/cex1Iara3h7c.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.78英寸", "resolution": "2800x1260px", "refresh_hz": "144Hz", "battery_mah": "7100mAh 大电池", "charge_w": "90w", "weight_g": "217g", "os": "OriginOS 6", "launch": "2026年3月30日", "nfc": "支持NFC", "waterproof": "IP68+IP69等级", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000亿像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 7100.0, "charge_w": 90.0, "weight_g": 217.0, "screen_inch": 6.78, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 70.0}, "source": "zol", "source_id": "2161776", "url": "https://detail.zol.com.cn/cell_phone/index2161776.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/284/cex1Iara3h7c.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 5999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'X300s16GB/+512GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 15S Pro
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15S Pro', '小米15S Pro（16GB/1TB）',
       DATE '2025-05-22',
       5999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/272_800x600/726/ceJq1K9jwFOC6.png',
       $json${"display": {"cpu": "玄戒 O1 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.73英寸", "resolution": "3200x1440px", "refresh_hz": "120Hz", "battery_mah": "6100mAh 大电池", "charge_w": "90w", "weight_g": "216g", "os": "Xiaomi HyperOS 2", "launch": "2025年05月22日", "nfc": "支持NFC（多功能）", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "玄戒o1"}, "metrics": {"battery_mah": 6100.0, "charge_w": 90.0, "weight_g": 216.0, "screen_inch": 6.73, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 170, "image_score": 55.0}, "source": "zol", "source_id": "2128635", "url": "https://detail.zol.com.cn/cell_phone/index2128635.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/272_320x240/726/ceJq1K9jwFOC6.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '15S Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17 Max
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17 Max', '小米17 Max(16GB/512GB)',
       NULL,
       5799,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/326/ce7gQuTtESXvI.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.9英寸", "resolution": "2608x1200px", "refresh_hz": "120Hz", "battery_mah": "8000mAh 大电池", "charge_w": "100w", "weight_g": "225g", "os": "Xiaomi HyperOS 3", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 8000.0, "charge_w": 100.0, "weight_g": 225.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2166982", "url": "https://detail.zol.com.cn/cell_phone/index2166982.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/326/ce7gQuTtESXvI.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 5799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17 Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura 90 16GB+512GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura 90 16GB+512GB', '华为Pura 90 16GB+512GB',
       NULL,
       5699,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/671/cesXSRGDNG0DU.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.8英寸", "resolution": "2856x1320px", "refresh_hz": "120Hz（1-120）", "weight_g": "210g", "os": "HarmonyOS 6.1", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1250万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"weight_g": 210.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2164026", "url": "https://detail.zol.com.cn/cell_phone/index2164026.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/671/cesXSRGDNG0DU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 5699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura 90 16GB+512GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 15T
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15T', '一加15T(16GB/1TB)',
       DATE '2026-03-24',
       5699,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/290/ceCCmPYExRkg.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.32英寸", "resolution": "2640x1216px", "refresh_hz": "165Hz", "battery_mah": "7500mAh 大电池", "charge_w": "100w", "weight_g": "194g", "os": "ColorOS 16", "launch": "2026年3月24日", "nfc": "支持NFC", "waterproof": "IP69 IP69K IP68 IP66", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 前置摄像头1：1600万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7500.0, "charge_w": 100.0, "weight_g": 194.0, "screen_inch": 6.32, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 70.0}, "source": "zol", "source_id": "2161567", "url": "https://detail.zol.com.cn/cell_phone/index2161567.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/290/ceCCmPYExRkg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = '15T'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find X10 E
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find X10 E', 'OPPO Find X10 E(16GB/512GB)',
       DATE '2026-09-24',
       5499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/641/ce2cNMwhdegZg.png',
       $json${"display": {"cpu": "联发科 天玑 9500S ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2760x1256px", "refresh_hz": "120Hz", "battery_mah": "7025mAh 大电池", "charge_w": "80w", "weight_g": "203g", "os": "ColorOS 17", "launch": "2026年9月24日", "nfc": "支持NFC", "waterproof": "IP69 & IP68 & IP66 超强防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "天玑9500s"}, "metrics": {"battery_mah": 7025.0, "charge_w": 80.0, "weight_g": 203.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 295, "image_score": 55.0}, "source": "zol", "source_id": "2178471", "url": "https://detail.zol.com.cn/cell_phone/index2178471.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/641/ce2cNMwhdegZg.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 5499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find X10 E'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Magic9 超能版
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Magic9 超能版', '荣耀Magic9 超能版(16GB/512GB)',
       DATE '2026-09-28',
       5499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/67/cenhhY7TQqTek.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.81英寸", "resolution": "2788x1280px", "refresh_hz": "120Hz（1-120）", "battery_mah": "11000mAh 大电池", "charge_w": "80w", "weight_g": "227g", "os": "MagicOS 11", "launch": "2026年9月28日", "nfc": "支持NFC", "waterproof": "IP68和IP69等级", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 11000.0, "charge_w": 80.0, "weight_g": 227.0, "screen_inch": 6.81, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2178514", "url": "https://detail.zol.com.cn/cell_phone/index2178514.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/67/cenhhY7TQqTek.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 5499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Magic9 超能版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K90 Pro Max
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K90 Pro Max', 'Redmi K90 Pro Max(16GB/1TB/冠军版)',
       DATE '2025-10-23',
       5499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/273_800x600/153/ceXTZt16YEcLc.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.9英寸", "resolution": "2608x1200px", "refresh_hz": "120Hz", "battery_mah": "7560mAh 大电池", "charge_w": "100w", "weight_g": "218g", "os": "Xiaomi HyperOS 3", "launch": "2025年10月23日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7560.0, "charge_w": 100.0, "weight_g": 218.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2145500", "url": "https://detail.zol.com.cn/cell_phone/index2145500.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/273_320x240/153/ceXTZt16YEcLc.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB/冠军版', 5499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K90 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO 15
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15', 'iQOO 15(16GB/512GB/王者典藏版礼盒)',
       DATE '2025-10-20',
       5499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/273_800x600/653/cergC9gAdrmbU.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.85英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "215g", "os": "OriginOS 6", "launch": "2025年10月20日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 215.0, "screen_inch": 6.85, "refresh_hz": 144.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2145166", "url": "https://detail.zol.com.cn/cell_phone/index2145166.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/273_320x240/653/cergC9gAdrmbU.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB/王者典藏版礼盒', 5499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = '15'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Ace 6 至尊版
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Ace 6 至尊版', '一加Ace 6 至尊版(16GB/1TB)',
       DATE '2026-04-28',
       5399,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/957/ceFddVkNvqr7o.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "165Hz", "battery_mah": "8600mAh 大电池", "charge_w": "120w", "weight_g": "217g", "os": "ColorOS 15", "launch": "2026年04月28日", "nfc": "支持NFC（多功能）", "waterproof": "IP66 &IP68&IP69&IP69K防水等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 8600.0, "charge_w": 120.0, "weight_g": 217.0, "screen_inch": 6.78, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2164628", "url": "https://detail.zol.com.cn/cell_phone/index2164628.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/957/ceFddVkNvqr7o.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Ace 6 至尊版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 15
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15', '一加15（16GB/1TB）',
       DATE '2025-10-27',
       5399,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/273_800x600/212/ceH4L8VQuPJs.jpg',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "165Hz", "battery_mah": "7300mAh 大电池", "charge_w": "120w", "weight_g": "原色沙丘：211g 绝对黑、雾光紫：215g", "os": "ColorOS 16", "launch": "2025年10月27日", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69/IP69K满级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7300.0, "charge_w": 120.0, "weight_g": 211.0, "screen_inch": 6.78, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2145903", "url": "https://detail.zol.com.cn/cell_phone/index2145903.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/273_320x240/212/ceH4L8VQuPJs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 5399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = '15'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Reno16 Pro
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Reno16 Pro', 'OPPO Reno16 Pro(16GB/512GB)',
       DATE '2026-05-29',
       5299,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/923/ce3RARSRknbII.png',
       $json${"display": {"cpu": "联发科 天玑 9500s 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "120Hz（1-120）", "battery_mah": "7000mAh 大电池", "charge_w": "80w", "weight_g": "205g", "os": "ColorOS 16.0", "launch": "2026年5月29日", "nfc": "支持NFC", "waterproof": "IP69K满级防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑9500s"}, "metrics": {"battery_mah": 7000.0, "charge_w": 80.0, "weight_g": 205.0, "screen_inch": 6.78, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 295, "image_score": 55.0}, "source": "zol", "source_id": "2167300", "url": "https://detail.zol.com.cn/cell_phone/index2167300.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/923/ce3RARSRknbII.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 5299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Reno16 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Find X9s Pro
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Find X9s Pro', 'OPPO Find X9s Pro(12GB/256GB)',
       NULL,
       5299,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/154/ceUZsCLwwpMyg.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.32英寸", "resolution": "2640x1216px", "refresh_hz": "144Hz", "battery_mah": "7025mAh 大电池", "charge_w": "80w", "weight_g": "200g", "os": "ColorOS 16", "nfc": "支持NFC", "waterproof": "支持IP66&IP68&IP69满级防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：2亿像素 前置摄像头1：3200万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 7025.0, "charge_w": 80.0, "weight_g": 200.0, "screen_inch": 6.32, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 85.0}, "source": "zol", "source_id": "2162941", "url": "https://detail.zol.com.cn/cell_phone/index2162941.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/154/ceUZsCLwwpMyg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 5299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Find X9s Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 novaFlip
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'novaFlip', '华为novaFlip',
       DATE '2024-08-09',
       5288,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/269_800x600/979/cefOVIyhVB8KA.jpg',
       $json${"display": {"rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "主：6.94英寸 副：2.1英寸", "resolution": "主：2690x1136px 副：480x480px", "refresh_hz": "120Hz", "battery_mah": "4400mAh 大电池", "charge_w": "66w", "weight_g": "195g", "os": "HarmonyOS 4.2", "launch": "2024年8月9日", "nfc": "支持NFC", "waterproof": "生活防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：3200万像素", "cpu_source": "同价位估算"}, "metrics": {"battery_mah": 4400.0, "charge_w": 66.0, "weight_g": 195.0, "screen_inch": 6.94, "refresh_hz": 120.0, "rom": 256.0, "rear_mp": 5000.0, "image_score": 40.0, "cpu_score": 108}, "source": "zol", "source_id": "2100886", "url": "https://detail.zol.com.cn/cell_phone/index2100886.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/269_320x240/979/cefOVIyhVB8KA.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 5288 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'novaFlip'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura 90 12GB+512GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura 90 12GB+512GB', '华为Pura 90 12GB+512GB',
       NULL,
       5199,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/671/cesXSRGDNG0DU.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.8英寸", "resolution": "2856x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6500mAh 大电池", "charge_w": "100w", "weight_g": "210g", "os": "HarmonyOS 6.1", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1250万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"battery_mah": 6500.0, "charge_w": 100.0, "weight_g": 210.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2164025", "url": "https://detail.zol.com.cn/cell_phone/index2164025.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/671/cesXSRGDNG0DU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 5199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura 90 12GB+512GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 nova 16 Ultra
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'nova 16 Ultra', '华为nova 16 Ultra（12GB/512GB）',
       DATE '2026-06-01',
       5199,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/60/ceYrBuQ76UpFc.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.84英寸", "resolution": "2856x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "220g", "os": "HarmonyOS 6.1", "launch": "2026年06月01日", "nfc": "支持NFC", "waterproof": "IP68&IP69", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 后置摄像头4：150万像素 前置摄像头1：5000万像素 前置摄像头2：150万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 220.0, "screen_inch": 6.84, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2167871", "url": "https://detail.zol.com.cn/cell_phone/index2167871.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/60/ceYrBuQ76UpFc.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 5199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'nova 16 Ultra'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17', '小米17(16GB/512GB)',
       DATE '2025-09-27',
       4999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/273_800x600/102/ceB9aUff1dxEE.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.3英寸", "resolution": "2656x1220px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "191g", "os": "Xiaomi HyperOS 3", "launch": "2025年9月27日", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 191.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2143191", "url": "https://detail.zol.com.cn/cell_phone/index2143191.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/273_320x240/102/ceB9aUff1dxEE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 WIN RT2
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'WIN RT2', '荣耀WIN RT2（16GB/256GB）',
       DATE '2026-10-21',
       4899,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/718/ce4ySSjAhglE.png',
       $json${"display": {"cpu": "骁龙 8 Elite Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.89英寸", "resolution": "3104x1440px", "refresh_hz": "185Hz", "battery_mah": "12070mAh 大电池", "charge_w": "90w", "weight_g": "238g", "os": "MagicOS 11", "launch": "2026年10月21日", "nfc": "支持NFC", "waterproof": "支持IP68&IP69&IP69K防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 12070.0, "charge_w": 90.0, "weight_g": 238.0, "screen_inch": 6.89, "refresh_hz": 185.0, "ram": 16.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 40.0}, "source": "zol", "source_id": "2181348", "url": "https://detail.zol.com.cn/cell_phone/index2181348.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/718/ce4ySSjAhglE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/256GB', 4899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'WIN RT2'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO OPPO
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'OPPO', 'OPPO (16GB/1TB)',
       DATE '2026-05-29',
       4899,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/449/ceL2nZ8W8w7lE.png',
       $json${"display": {"cpu": "联发科 天玑 8550 SUPER ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.32英寸", "resolution": "2640x1216px", "refresh_hz": "120Hz", "battery_mah": "6700mAh 大电池", "charge_w": "80w", "weight_g": "191g", "os": "ColorOS 16.0", "launch": "2026年5月29日", "nfc": "支持NFC", "waterproof": "IP69K满级防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑8550"}, "metrics": {"battery_mah": 6700.0, "charge_w": 80.0, "weight_g": 191.0, "screen_inch": 6.32, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 155, "image_score": 40.0}, "source": "zol", "source_id": "2167291", "url": "https://detail.zol.com.cn/cell_phone/index2167291.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/449/ceL2nZ8W8w7lE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 4899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'OPPO'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17T Pro
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17T Pro', '小米17T Pro(16GB/512GB)',
       DATE '2026-06-08',
       4799,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/65/ceCRgaDEraxc.png',
       $json${"display": {"cpu": "联发科 天玑 9500 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2772x1280px", "refresh_hz": "144Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "219g", "os": "Xiaomi HyperOS 3", "launch": "2026年06月8日", "nfc": "支持NFC", "waterproof": "IP68 防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：1200万像素 前置摄像头1：3200万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 219.0, "screen_inch": 6.83, "refresh_hz": 144.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2168676", "url": "https://detail.zol.com.cn/cell_phone/index2168676.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/65/ceCRgaDEraxc.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17T Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K100 Pro
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K100 Pro', 'Redmi K100 Pro（16GB/512GB）',
       DATE '2026-08-11',
       4699,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/115/ceH5FUsPrL80U.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite Gen5 V Series ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2510x1156px", "refresh_hz": "185Hz", "battery_mah": "8580mAh 大电池", "charge_w": "100w", "weight_g": "218g", "os": "Xiaomi HyperOS 3", "launch": "2026年8月11日", "nfc": "支持NFC", "waterproof": "IP68/P69防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：800万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8elitegen5"}, "metrics": {"battery_mah": 8580.0, "charge_w": 100.0, "weight_g": 218.0, "screen_inch": 6.59, "refresh_hz": 185.0, "ram": 16.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2174709", "url": "https://detail.zol.com.cn/cell_phone/index2174709.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/115/ceH5FUsPrL80U.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K100 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 600 Pro
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '600 Pro', '荣耀600 Pro(16GB/512GB)',
       DATE '2026-05-25',
       4699,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/590/ceATuJ6c8qdZk.png',
       $json${"display": {"cpu": "联发科 天玑8550 Elite ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.57英寸", "resolution": "2728x1264px", "refresh_hz": "120Hz", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "202g", "os": "MagicOS 10.0", "launch": "2026年5月25日", "nfc": "支持NFC", "waterproof": "支持IP68&IP69&IP69K防尘防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑8550"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 202.0, "screen_inch": 6.57, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 155, "image_score": 40.0}, "source": "zol", "source_id": "2166091", "url": "https://detail.zol.com.cn/cell_phone/index2166091.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/590/ceATuJ6c8qdZk.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = '600 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 Pura 90
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Pura 90', '华为Pura 90',
       NULL,
       4699,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/671/cesXSRGDNG0DU.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.8英寸", "resolution": "2856x1320px", "refresh_hz": "120Hz（1-120）", "battery_mah": "6500mAh 大电池", "charge_w": "100w", "weight_g": "210g", "os": "HarmonyOS 6.1", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP68，IP69）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1250万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"battery_mah": 6500.0, "charge_w": 100.0, "weight_g": 210.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2162693", "url": "https://detail.zol.com.cn/cell_phone/index2162693.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/671/cesXSRGDNG0DU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 4699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'Pura 90'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 WIN Turbo2
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'WIN Turbo2', '荣耀WIN Turbo2（16GB/512GB）',
       DATE '2026-10-21',
       4499,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/652/ceIg6q3gGUGQ.jpg',
       $json${"display": {"cpu": "高通 骁龙8S Gen4 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.89英寸", "resolution": "3104x1440px", "refresh_hz": "120Hz", "battery_mah": "12070mAh 大电池", "charge_w": "90w", "weight_g": "235g", "os": "MagicOS 11", "launch": "2026年10月21日", "nfc": "支持NFC", "waterproof": "支持IP68&IP69&IP69K防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8sgen4"}, "metrics": {"battery_mah": 12070.0, "charge_w": 90.0, "weight_g": 235.0, "screen_inch": 6.89, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 205, "image_score": 40.0}, "source": "zol", "source_id": "2181346", "url": "https://detail.zol.com.cn/cell_phone/index2181346.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/652/ceIg6q3gGUGQ.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'WIN Turbo2'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Neo11 至尊版
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Neo11 至尊版', 'iQOO Neo11 至尊版(16GB/512GB)',
       NULL,
       4399,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/953/ceQBQWRgqEQQ.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500M ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "3200x1440px", "refresh_hz": "144Hz", "battery_mah": "9100mAh 大电池", "charge_w": "100w", "weight_g": "225g", "os": "OriginOS 6", "nfc": "支持NFC", "waterproof": "IP68 及 IP69 级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑9500m"}, "metrics": {"battery_mah": 9100.0, "charge_w": 100.0, "weight_g": 225.0, "screen_inch": 6.83, "refresh_hz": 144.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 300, "image_score": 55.0}, "source": "zol", "source_id": "2175417", "url": "https://detail.zol.com.cn/cell_phone/index2175417.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/953/ceQBQWRgqEQQ.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Neo11 至尊版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo S60
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'S60', 'vivo S60（16GB/512GB）',
       DATE '2026-06-03',
       4399,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/675/cevAqyzVC6orU.jpg',
       $json${"display": {"cpu": "高通 骁龙8S Gen3 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2750x1260px", "refresh_hz": "144Hz", "battery_mah": "7200mAh 大电池", "charge_w": "90w", "weight_g": "205g", "os": "OriginOS 6", "launch": "2026年06月03日", "nfc": "支持NFC（全场景）", "waterproof": "IP69+IP68级防尘抗水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：800万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8sgen3"}, "metrics": {"battery_mah": 7200.0, "charge_w": 90.0, "weight_g": 205.0, "screen_inch": 6.59, "refresh_hz": 144.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 168, "image_score": 55.0}, "source": "zol", "source_id": "2167620", "url": "https://detail.zol.com.cn/cell_phone/index2167620.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/675/cevAqyzVC6orU.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'S60'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 WIN Turbo
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'WIN Turbo', '荣耀WIN Turbo(16GB/512GB)',
       DATE '2026-05-29',
       4199,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/519/ceSpBMKIHNJ8U.jpg',
       $json${"display": {"ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.79英寸", "resolution": "2640x1200px", "refresh_hz": "120Hz", "battery_mah": "10000mAh 大电池", "weight_g": "216g", "os": "MagicOS 10", "launch": "2026年5月29日", "nfc": "支持NFC", "waterproof": "支持IP68&IP69&IP69K防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：500万像素 前置摄像头1：1600万像素", "cpu_source": "同价位估算"}, "metrics": {"battery_mah": 10000.0, "weight_g": 216.0, "screen_inch": 6.79, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "image_score": 40.0, "cpu_score": 174}, "source": "zol", "source_id": "2167618", "url": "https://detail.zol.com.cn/cell_phone/index2167618.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/519/ceSpBMKIHNJ8U.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 4199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'WIN Turbo'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo S50t
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'S50t', 'vivo S50t(16GB/512GB)',
       NULL,
       3999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/632/ceh0MReKdL7KY.jpg',
       $json${"display": {"cpu": "高通 骁龙8S Gen3 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2750x1260px", "refresh_hz": "60Hz/120Hz", "battery_mah": "6500mAh 大电池", "charge_w": "90w", "weight_g": "197g", "os": "OriginOS 6", "launch": "2026年5月", "nfc": "支持NFC", "waterproof": "IP68+IP69级防尘抗水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8sgen3"}, "metrics": {"battery_mah": 6500.0, "charge_w": 90.0, "weight_g": 197.0, "screen_inch": 6.59, "refresh_hz": 60.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 168, "image_score": 55.0}, "source": "zol", "source_id": "2167622", "url": "https://detail.zol.com.cn/cell_phone/index2167622.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/632/ceh0MReKdL7KY.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 3999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'S50t'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO K15 Pro+
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K15 Pro+', 'OPPO K15 Pro+(12GB/512GB)',
       DATE '2026-04-03',
       3999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/380/ce95fpPN1XELc.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500S ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "165Hz", "battery_mah": "8000mAh 大电池", "charge_w": "100w", "weight_g": "219g", "os": "ColorOS 15.0", "launch": "2026年4月3日", "nfc": "支持NFC（多功能）", "waterproof": "IPX9满级防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑9500s"}, "metrics": {"battery_mah": 8000.0, "charge_w": 100.0, "weight_g": 219.0, "screen_inch": 6.78, "refresh_hz": 165.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 295, "image_score": 40.0}, "source": "zol", "source_id": "2161713", "url": "https://detail.zol.com.cn/cell_phone/index2161713.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/380/ce95fpPN1XELc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'K15 Pro+'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K90
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K90', 'Redmi K90(16GB/1TB)',
       DATE '2025-10-23',
       3999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/273_800x600/38/ce3G9gn2UjeHs.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.59英寸", "refresh_hz": "120Hz", "battery_mah": "7100mAh 大电池", "charge_w": "100w", "weight_g": "206g", "os": "Xiaomi HyperOS 3", "launch": "2025年10月23日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 后置摄像头3：5000万像素 前置摄像头1：2000万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 7100.0, "charge_w": 100.0, "weight_g": 206.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 40.0}, "source": "zol", "source_id": "2145492", "url": "https://detail.zol.com.cn/cell_phone/index2145492.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/273_320x240/38/ce3G9gn2UjeHs.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 3999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K90'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 nova 16 Pro
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'nova 16 Pro', '华为nova 16 Pro（12GB/256GB/泡泡玛特Hirono小野联名款）',
       DATE '2026-06-05',
       3899,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/39/ceoI33fKVJnrI.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.84英寸", "resolution": "2856x1320px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "218g", "os": "HarmonyOS 6.1", "launch": "2026年6月5日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP65）", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 218.0, "screen_inch": 6.84, "refresh_hz": 120.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2179281", "url": "https://detail.zol.com.cn/cell_phone/index2179281.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/39/ceoI33fKVJnrI.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB/泡泡玛特Hirono小野联名款', 3899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'nova 16 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Ace 6T
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Ace 6T', '一加Ace 6T(16GB/512GB/原神神里绫华定制机)',
       NULL,
       3899,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/274_800x600/21/cenB8s1BAmrs.jpg',
       $json${"display": {"cpu": "高通 骁龙8 Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1272px", "refresh_hz": "165Hz", "battery_mah": "8300mAh 大电池", "charge_w": "100w", "weight_g": "217g", "os": "ColorOS 16", "nfc": "支持NFC", "waterproof": "IP66/68/69/69K满级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "骁龙8gen5"}, "metrics": {"battery_mah": 8300.0, "charge_w": 100.0, "weight_g": 217.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 280, "image_score": 40.0}, "source": "zol", "source_id": "2149958", "url": "https://detail.zol.com.cn/cell_phone/index2149958.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/274_320x240/21/cenB8s1BAmrs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB/原神神里绫华定制机', 3899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Ace 6T'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Ace 6
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Ace 6', '一加Ace 6(16GB/1TB)',
       DATE '2025-10-27',
       3899,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/273_800x600/270/ceGv1cznRrMp.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1272px", "refresh_hz": "165Hz", "battery_mah": "7800mAh 大电池", "charge_w": "120w", "weight_g": "213g", "os": "ColorOS 16", "launch": "2025年10月27日", "nfc": "支持NFC", "waterproof": "IP66/68/69/69K满级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 7800.0, "charge_w": 120.0, "weight_g": 213.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 40.0}, "source": "zol", "source_id": "2145907", "url": "https://detail.zol.com.cn/cell_phone/index2145907.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/273_320x240/270/ceGv1cznRrMp.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 3899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Ace 6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO 15T
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '15T', 'iQOO 15T(12GB/256GB)',
       DATE '2026-05-20',
       3799,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/769/cecX14elqi6xY.jpg',
       $json${"display": {"cpu": "联发科 天玑9500 Monster版 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.82英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "8000mAh 大电池", "charge_w": "100w", "weight_g": "216g", "os": "OriginOS 6", "launch": "2026年5月20日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 8000.0, "charge_w": 100.0, "weight_g": 216.0, "screen_inch": 6.82, "refresh_hz": 144.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 330, "image_score": 55.0}, "source": "zol", "source_id": "2166500", "url": "https://detail.zol.com.cn/cell_phone/index2166500.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/769/cecX14elqi6xY.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 3799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = '15T'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Neo11
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Neo11', 'iQOO Neo11(16GB/1TB)',
       DATE '2025-10-30',
       3799,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/273_800x600/86/ce42X12ZU1fsA.jpg',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.82英寸", "resolution": "3168x1440px", "refresh_hz": "144Hz", "battery_mah": "7500mAh 大电池", "charge_w": "100w", "weight_g": "210g", "os": "OriginOS 6", "launch": "2025年10月30日", "nfc": "支持NFC", "waterproof": "IP68&IP69", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 7500.0, "charge_w": 100.0, "weight_g": 210.0, "screen_inch": 6.82, "refresh_hz": 144.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 55.0}, "source": "zol", "source_id": "2146218", "url": "https://detail.zol.com.cn/cell_phone/index2146218.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/273_320x240/86/ce42X12ZU1fsA.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 3799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Neo11'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 600 超级版
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '600 超级版', '荣耀600 超级版(12GB/512GB)',
       DATE '2025-05-29',
       3699,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/455/ceHy9NSGC3TH2.jpg',
       $json${"display": {"cpu": "高通 骁龙7 Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.57英寸", "resolution": "2728x1264px", "refresh_hz": "120Hz", "battery_mah": "8600mAh 大电池", "charge_w": "80w", "weight_g": "201g", "os": "MagicOS 10.0", "launch": "2025年5月29日", "nfc": "支持NFC", "waterproof": "IP68&IP69&IP69K防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙7gen4"}, "metrics": {"battery_mah": 8600.0, "charge_w": 80.0, "weight_g": 201.0, "screen_inch": 6.57, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 20000.0, "cpu_score": 122, "image_score": 40.0}, "source": "zol", "source_id": "2166093", "url": "https://detail.zol.com.cn/cell_phone/index2166093.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/455/ceHy9NSGC3TH2.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = '600 超级版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Z11 Turbo
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Z11 Turbo', 'iQOO Z11 Turbo(16GB/1TB)',
       NULL,
       3699,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/274_800x600/936/ceoiSkNbJiiqg.jpg',
       $json${"display": {"cpu": "高通 骁龙8 Gen5 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "1TB 20.5万张照片 8.5万首歌曲", "screen_inch": "6.59英寸", "resolution": "2750x1260px", "refresh_hz": "144Hz", "battery_mah": "7600mAh 大电池", "charge_w": "100w", "weight_g": "206g", "os": "OriginOS 6", "nfc": "支持NFC", "waterproof": "IP69&69等级防水防尘", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：800万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙8gen5"}, "metrics": {"battery_mah": 7600.0, "charge_w": 100.0, "weight_g": 206.0, "screen_inch": 6.59, "refresh_hz": 144.0, "ram": 16.0, "rom": 1024.0, "rear_mp": 20000.0, "cpu_score": 280, "image_score": 40.0}, "source": "zol", "source_id": "2154430", "url": "https://detail.zol.com.cn/cell_phone/index2154430.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/274_320x240/936/ceoiSkNbJiiqg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/1TB', 3699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Z11 Turbo'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 Civi 5 Pro
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Civi 5 Pro', '小米Civi 5 Pro(16GB/512GB)',
       DATE '2025-05-22',
       3599,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/272_800x600/108/cecYSOQ9COcvw.png',
       $json${"display": {"cpu": "高通 骁龙8S Gen4 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.55英寸", "resolution": "2750x1236px", "refresh_hz": "120Hz", "battery_mah": "6000mAh 大电池", "charge_w": "67w", "weight_g": "184g", "os": "Xiaomi HyperOS 2", "launch": "2025年05月22日", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙8sgen4"}, "metrics": {"battery_mah": 6000.0, "charge_w": 67.0, "weight_g": 184.0, "screen_inch": 6.55, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 205, "image_score": 55.0}, "source": "zol", "source_id": "2128643", "url": "https://detail.zol.com.cn/cell_phone/index2128643.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/272_320x240/108/cecYSOQ9COcvw.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 3599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = 'Civi 5 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K90 Max
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K90 Max', 'Redmi K90 Max(16GB/256GB)',
       DATE '2026-04-21',
       3499,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/988/cex9aqMIpMlc.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.83英寸", "resolution": "2772x1280px", "refresh_hz": "165Hz", "battery_mah": "8550mAh 大电池", "charge_w": "100w有线快充，22.5w有线反充", "weight_g": "227g", "os": "Xiaomi HyperOS 3", "launch": "2026年4月21日", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：2000万像素", "cpu_tier_name": "天玑9500"}, "metrics": {"battery_mah": 8550.0, "charge_w": 100.0, "weight_g": 227.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 16.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 330, "image_score": 40.0}, "source": "zol", "source_id": "2164059", "url": "https://detail.zol.com.cn/cell_phone/index2164059.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/988/cex9aqMIpMlc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/256GB', 3499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K90 Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 nova 16
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'nova 16', '华为nova 16（512GB）',
       DATE '2026-06-05',
       3499,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/964/ce5ajwq0fmmNk.png',
       $json${"display": {"cpu": "海思 麒麟 9010S ， 手机性能排行", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.68英寸", "resolution": "2800x1280px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "100w", "weight_g": "199g", "os": "HarmonyOS 6.1", "launch": "2026年6月5日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP65）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：150万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟9010s"}, "metrics": {"battery_mah": 7000.0, "charge_w": 100.0, "weight_g": 199.0, "screen_inch": 6.68, "refresh_hz": 120.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 108, "image_score": 55.0}, "source": "zol", "source_id": "2167872", "url": "https://detail.zol.com.cn/cell_phone/index2167872.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/964/ce5ajwq0fmmNk.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '512GB', 3499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'nova 16'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo S60元气版
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'S60元气版', 'vivo S60元气版(12GB/512GB)',
       DATE '2026-06-03',
       3499,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/682/ceSbGTouhf68.jpg',
       $json${"display": {"cpu": "联发科 天玑 7500满血版 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2750x1260px", "refresh_hz": "144Hz", "battery_mah": "7200mAh 大电池", "charge_w": "90w", "weight_g": "199g", "os": "OriginOS 6", "launch": "2026年06月03日", "nfc": "支持NFC（全场景）", "waterproof": "IP69+IP68级防尘抗水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑7500"}, "metrics": {"battery_mah": 7200.0, "charge_w": 90.0, "weight_g": 199.0, "screen_inch": 6.59, "refresh_hz": 144.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 78, "image_score": 55.0}, "source": "zol", "source_id": "2167625", "url": "https://detail.zol.com.cn/cell_phone/index2167625.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/682/ceSbGTouhf68.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'S60元气版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Reno16
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Reno16', 'OPPO Reno16(12GB/256GB)',
       DATE '2026-05-29',
       3499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/449/ceL2nZ8W8w7lE.png',
       $json${"display": {"cpu": "联发科 天玑 8550 SUPER ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.32英寸", "resolution": "2640x1216px", "refresh_hz": "120Hz", "battery_mah": "6700mAh 大电池", "charge_w": "80w", "weight_g": "191g", "os": "ColorOS 16.0", "launch": "2026年5月29日", "nfc": "支持NFC", "waterproof": "IP69K满级防水", "rear_camera": "后置摄像头1：2亿像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑8550"}, "metrics": {"battery_mah": 6700.0, "charge_w": 80.0, "weight_g": 191.0, "screen_inch": 6.32, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 20000.0, "cpu_score": 155, "image_score": 55.0}, "source": "zol", "source_id": "2166008", "url": "https://detail.zol.com.cn/cell_phone/index2166008.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/449/ceL2nZ8W8w7lE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 3499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Reno16'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO K15 Pro
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K15 Pro', 'OPPO K15 Pro(12GB/512GB)',
       DATE '2026-04-03',
       3499,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/348/ceH4eTM8YCVo.jpg',
       $json${"display": {"cpu": "联发科 天玑 8500 SUPER ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2760x1256px", "refresh_hz": "144Hz", "battery_mah": "7500mAh 大电池", "charge_w": "80w", "weight_g": "200g", "os": "ColorOS 15.0", "launch": "2026年4月3日", "nfc": "支持NFC", "waterproof": "IPX9满级防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑8500"}, "metrics": {"battery_mah": 7500.0, "charge_w": 80.0, "weight_g": 200.0, "screen_inch": 6.59, "refresh_hz": 144.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 200, "image_score": 40.0}, "source": "zol", "source_id": "2161711", "url": "https://detail.zol.com.cn/cell_phone/index2161711.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/348/ceH4eTM8YCVo.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'K15 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 600 元气版
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '600 元气版', '荣耀600 元气版(12GB/512GB)',
       DATE '2026-05-29',
       3399,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/190/ceka0681qreA.png',
       $json${"display": {"cpu": "高通 骁龙7 Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.57英寸", "resolution": "2728x1264px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "80w", "weight_g": "190g", "os": "MagicOS 10.0", "launch": "2026年5月29日", "nfc": "支持NFC", "waterproof": "IP68&IP69&IP69K防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙7gen4"}, "metrics": {"battery_mah": 7000.0, "charge_w": 80.0, "weight_g": 190.0, "screen_inch": 6.57, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 122, "image_score": 40.0}, "source": "zol", "source_id": "2167303", "url": "https://detail.zol.com.cn/cell_phone/index2167303.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/190/ceka0681qreA.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = '600 元气版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 nova 16z
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'nova 16z', '华为nova 16z（12GB/512GB）',
       DATE '2025-06-01',
       3199,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/11/ceIqPi330SWpY.png',
       $json${"display": {"cpu": "海思 麒麟 8020 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.7英寸", "resolution": "2412x1084px", "refresh_hz": "120Hz", "battery_mah": "6000mAh 大电池", "charge_w": "100w", "weight_g": "196.5g", "os": "HarmonyOS 6.1", "launch": "2025年06月01日", "nfc": "支持NFC", "waterproof": "支持防尘抗水（IP65）", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：1200万像素 后置摄像头3：150万像素 前置摄像头1：5000万像素", "cpu_tier_name": "麒麟8020"}, "metrics": {"battery_mah": 6000.0, "charge_w": 100.0, "screen_inch": 6.7, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 75, "image_score": 40.0}, "source": "zol", "source_id": "2167874", "url": "https://detail.zol.com.cn/cell_phone/index2167874.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/11/ceIqPi330SWpY.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'nova 16z'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO Reno15c
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Reno15c', 'OPPO Reno15c(12GB/512GB)',
       DATE '2025-12-19',
       3199,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/274_800x600/573/ceNGxGg2Qidy2.jpg',
       $json${"display": {"cpu": "高通 骁龙7 Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2760x1256px", "refresh_hz": "120Hz", "battery_mah": "6500mAh 大电池", "charge_w": "80w", "weight_g": "197g", "os": "ColorOS 16.0", "launch": "2025年12月19日", "nfc": "支持NFC", "waterproof": "IP69等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 后置摄像头3：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙7gen4"}, "metrics": {"battery_mah": 6500.0, "charge_w": 80.0, "weight_g": 197.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 122, "image_score": 40.0}, "source": "zol", "source_id": "2151558", "url": "https://detail.zol.com.cn/cell_phone/index2151558.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/274_320x240/573/ceNGxGg2Qidy2.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 3199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'Reno15c'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Turbo 6
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 6', '一加Turbo 6(16GB/512GB)',
       NULL,
       3099,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/274_800x600/406/ceR7H2PJa97Y.png',
       $json${"display": {"cpu": "高通 骁龙 8s Gen4 风驰版 ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "165Hz", "battery_mah": "9000mAh 大电池", "charge_w": "80w", "weight_g": "217g", "os": "ColorOS 16", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69/IP69K满级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：1600万像素", "cpu_tier_name": "骁龙8sgen4"}, "metrics": {"battery_mah": 9000.0, "charge_w": 80.0, "weight_g": 217.0, "screen_inch": 6.78, "refresh_hz": 165.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 205, "image_score": 40.0}, "source": "zol", "source_id": "2153079", "url": "https://detail.zol.com.cn/cell_phone/index2153079.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/274_320x240/406/ceR7H2PJa97Y.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 3099 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Turbo 6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 小米 17T
INSERT INTO biz.brand(name) VALUES ('小米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '17T', '小米17T（12GB/256GB）',
       DATE '2026-06-08',
       2999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/110/ceCA8I4WRROpc.png',
       $json${"display": {"cpu": "联发科 天玑8500-Ultra ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.59英寸", "resolution": "2756x1268px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "67W 小米澎湃有线秒充", "weight_g": "203g", "os": "Xiaomi HyperOS 3", "launch": "2026年6月8日", "nfc": "支持NFC（多功能）", "waterproof": "IP68防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 后置摄像头3：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "天玑8500-ultra"}, "metrics": {"battery_mah": 7000.0, "charge_w": 67.0, "weight_g": 203.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 160, "image_score": 55.0}, "source": "zol", "source_id": "2168622", "url": "https://detail.zol.com.cn/cell_phone/index2168622.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/110/ceCA8I4WRROpc.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '小米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 2999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '小米' AND p.model = '17T'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO A6s Pro
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'A6s Pro', 'OPPO A6s Pro(12GB/512GB)',
       DATE '2026-04-14',
       2999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/709/ceSiceoO9FToo.jpg',
       $json${"display": {"cpu": "联发科 天玑6360 MAX ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.57英寸", "resolution": "2372x1080px", "refresh_hz": "120Hz", "battery_mah": "7000mAh 大电池", "charge_w": "80w", "weight_g": "194g", "os": "ColorOS 16", "launch": "2026年4月14日", "nfc": "支持NFC", "waterproof": "IP69K满级防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑6360"}, "metrics": {"battery_mah": 7000.0, "charge_w": 80.0, "weight_g": 194.0, "screen_inch": 6.57, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 50, "image_score": 40.0}, "source": "zol", "source_id": "2163128", "url": "https://detail.zol.com.cn/cell_phone/index2163128.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/709/ceSiceoO9FToo.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'A6s Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 K90至尊版
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K90至尊版', 'Redmi K90至尊版（12GB/256GB）',
       DATE '2026-06-30',
       2999,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/93/ce5ZmhnzxZvlU.png',
       $json${"display": {"cpu": "高通 骁龙 8 Elite ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.83英寸", "resolution": "2772x1280px", "refresh_hz": "165Hz", "battery_mah": "8550mAh 大电池", "charge_w": "100W有线快充，22.5W有线反充", "weight_g": "227g", "os": "Xiaomi HyperOS 3", "launch": "2026年06月30日", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69 防尘防水大满贯", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：2000万像素", "cpu_tier_name": "骁龙8elite"}, "metrics": {"battery_mah": 8550.0, "charge_w": 100.0, "weight_g": 227.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 285, "image_score": 40.0}, "source": "zol", "source_id": "2170819", "url": "https://detail.zol.com.cn/cell_phone/index2170819.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/93/ce5ZmhnzxZvlU.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 2999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'K90至尊版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y600 Pro
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y600 Pro', 'vivo Y600 Pro（12GB/512GB）',
       DATE '2026-04-30',
       2899,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/971/ceykjqb9802UY.png',
       $json${"display": {"cpu": "联发科 天玑 7300e ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1260px", "refresh_hz": "120Hz", "battery_mah": "10200mAh 大电池", "charge_w": "90w闪充", "weight_g": "221g", "os": "OriginOS 6", "launch": "2026年4月30日", "nfc": "支持NFC", "waterproof": "IP68+IP69 满级防水", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：3200万像素", "cpu_tier_name": "天玑7300"}, "metrics": {"battery_mah": 10200.0, "charge_w": 90.0, "weight_g": 221.0, "screen_inch": 6.83, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 72, "image_score": 40.0}, "source": "zol", "source_id": "2164587", "url": "https://detail.zol.com.cn/cell_phone/index2164587.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/971/ceykjqb9802UY.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y600 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 Turbo 5 MAX
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 5 MAX', 'Redmi Turbo 5 MAX(16GB/512GB)',
       DATE '2026-01-29',
       2799,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/274_800x600/165/cek9Jkc5GEfRc.jpg',
       $json${"display": {"cpu": "联发科 天玑 9500S ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2772x1280px", "refresh_hz": "120Hz", "battery_mah": "9000mAh 大电池", "charge_w": "100w", "weight_g": "219g", "os": "Xiaomi HyperOS 3", "launch": "2026年1月29日", "nfc": "支持NFC", "waterproof": "IP66&IP68&IP69&IP69K", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：2000万像素", "cpu_tier_name": "天玑9500s"}, "metrics": {"battery_mah": 9000.0, "charge_w": 100.0, "weight_g": 219.0, "screen_inch": 6.83, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 295, "image_score": 40.0}, "source": "zol", "source_id": "2155784", "url": "https://detail.zol.com.cn/cell_phone/index2155784.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/274_320x240/165/cek9Jkc5GEfRc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 2799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'Turbo 5 MAX'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 nova 16 SE
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'nova 16 SE', '华为nova 16 SE（256GB）',
       DATE '2026-08-05',
       2699,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/276_800x600/778/ceh6C8RKJc1k.jpg',
       $json${"display": {"cpu": "海思 麒麟 8020 ， 手机性能排行", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.84英寸", "resolution": "2756x1272px", "refresh_hz": "120Hz", "battery_mah": "8500mAh 大电池", "charge_w": "66w（11V/6A）", "weight_g": "229g", "os": "HarmonyOS 6.1", "launch": "2026年08月05日", "nfc": "支持NFC", "waterproof": "IP65", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：150万像素 前置摄像头1：3200万像素", "cpu_tier_name": "麒麟8020"}, "metrics": {"battery_mah": 8500.0, "charge_w": 66.0, "weight_g": 229.0, "screen_inch": 6.84, "refresh_hz": 120.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 75, "image_score": 40.0}, "source": "zol", "source_id": "2173975", "url": "https://detail.zol.com.cn/cell_phone/index2173975.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/276_320x240/778/ceh6C8RKJc1k.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '256GB', 2699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = 'nova 16 SE'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Z11S
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Z11S', 'iQOO Z11S(12GB/512GB)',
       DATE '2026-08-18',
       2699,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/276_800x600/30/ceobxtO9kezjg.jpg',
       $json${"display": {"cpu": "联发科 天玑 7500满血版 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1260px", "refresh_hz": "165Hz", "battery_mah": "10000mAh 大电池", "charge_w": "44w", "weight_g": "225g", "os": "OriginOS 6", "launch": "2026年8月18日", "nfc": "支持NFC", "waterproof": "IP68/IP69级防尘防水", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑7500"}, "metrics": {"battery_mah": 10000.0, "charge_w": 44.0, "weight_g": 225.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 78, "image_score": 40.0}, "source": "zol", "source_id": "2175420", "url": "https://detail.zol.com.cn/cell_phone/index2175420.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/276_320x240/30/ceobxtO9kezjg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Z11S'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y600 Turbo
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y600 Turbo', 'vivo Y600 Turbo(12GB/512GB)',
       NULL,
       2699,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/275_800x600/931/cenCbaOuzKPho.png',
       $json${"display": {"cpu": "高通 骁龙7S Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1260px", "refresh_hz": "120Hz", "battery_mah": "9020mAh 大电池", "charge_w": "90w闪充", "weight_g": "215g", "os": "OriginOS 6", "launch": "2026年5月", "nfc": "支持NFC", "waterproof": "IP68+IP69 满级防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙7sgen4"}, "metrics": {"battery_mah": 9020.0, "charge_w": 90.0, "weight_g": 215.0, "screen_inch": 6.83, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 100, "image_score": 40.0}, "source": "zol", "source_id": "2167287", "url": "https://detail.zol.com.cn/cell_phone/index2167287.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/275_320x240/931/cenCbaOuzKPho.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y600 Turbo'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO A7 Pro Max
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'A7 Pro Max', 'OPPO A7 Pro Max(8GB/256GB)',
       DATE '2026-08-04',
       2599,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/276_800x600/490/ceNKcqTMILemY.png',
       $json${"display": {"cpu": "高通 骁龙4 Gen5 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "120Hz（60/90/120Hz）", "battery_mah": "10000mAh 大电池", "charge_w": "80w", "weight_g": "226g", "os": "ColorOS 16", "launch": "2026年08月04日", "nfc": "支持NFC（全场景）", "waterproof": "IP69K防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：5000万像素", "cpu_tier_name": "骁龙4gen5"}, "metrics": {"battery_mah": 10000.0, "charge_w": 80.0, "weight_g": 226.0, "screen_inch": 6.78, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 48, "image_score": 40.0}, "source": "zol", "source_id": "2173820", "url": "https://detail.zol.com.cn/cell_phone/index2173820.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/276_320x240/490/ceNKcqTMILemY.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 2599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'A7 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 R70m 5G
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'R70m 5G', 'Redmi R70m 5G(12GB/256GB)',
       DATE '2026-04-14',
       2599,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/932/ce9lrMvvTxPG6.jpg',
       $json${"display": {"cpu": "紫光展锐 T8300 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.9英寸", "resolution": "1600x720px", "refresh_hz": "120Hz", "battery_mah": "6300mAh 大电池", "charge_w": "15w", "weight_g": "210g", "os": "Xiaomi HyperOS 3", "launch": "2026年4月14日", "rear_camera": "后置摄像头1：1300万像素 前置摄像头1：800万像素", "cpu_tier_name": "t8300"}, "metrics": {"battery_mah": 6300.0, "charge_w": 15.0, "weight_g": 210.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 1300.0, "cpu_score": 45, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2163142", "url": "https://detail.zol.com.cn/cell_phone/index2163142.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/932/ce9lrMvvTxPG6.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 2599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'R70m 5G'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 Turbo 5
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 5', 'Redmi Turbo 5（16GB/512GB）',
       DATE '2025-01-29',
       2599,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/274_800x600/212/ceqKNh4Duf3zs.jpg',
       $json${"display": {"cpu": "联发科 天玑8500-Ultra ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.59英寸", "resolution": "2756x1268px", "refresh_hz": "120Hz", "battery_mah": "7560mAh 大电池", "charge_w": "100w有线快充，27w有线反充", "weight_g": "204g", "os": "Xiaomi HyperOS 3", "launch": "2025年1月29日", "nfc": "支持NFC（多功能）", "waterproof": "IP66/IP68/IP69/IP69K防水大满贯", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：2000万像素", "cpu_tier_name": "天玑8500-ultra"}, "metrics": {"battery_mah": 7560.0, "charge_w": 100.0, "weight_g": 204.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 160, "image_score": 40.0}, "source": "zol", "source_id": "2155780", "url": "https://detail.zol.com.cn/cell_phone/index2155780.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/274_320x240/212/ceqKNh4Duf3zs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 2599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'Turbo 5'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO A7 Pro
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'A7 Pro', 'OPPO A7 Pro（8GB/256GB）',
       DATE '2026-09-11',
       2499,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/77/ce8vEzGwSa8i2.png',
       $json${"display": {"cpu": "联发科 天玑6360 MAX ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.57英寸", "resolution": "2372x1080px", "refresh_hz": "120Hz（60/90/120Hz）", "battery_mah": "8000mAh 大电池", "charge_w": "45w", "weight_g": "205g", "os": "ColorOS 16.0", "launch": "2026年09月11日", "nfc": "支持NFC（全场景）", "waterproof": "IP69K超强防水", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑6360"}, "metrics": {"battery_mah": 8000.0, "charge_w": 45.0, "weight_g": 205.0, "screen_inch": 6.57, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 50, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2178707", "url": "https://detail.zol.com.cn/cell_phone/index2178707.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/77/ce8vEzGwSa8i2.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 2499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'A7 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Ace 5 竞速版
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Ace 5 竞速版', '一加Ace 5 竞速版(16GB/512GB)',
       DATE '2025-05-27',
       2499,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/272_800x600/556/ce1XbUku3kCTQ.jpg',
       $json${"display": {"cpu": "联发科 天玑 9400e ， 手机性能排行", "ram": "16GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.77英寸", "resolution": "2392x1080px", "refresh_hz": "120Hz", "battery_mah": "7100mAh 大电池", "charge_w": "80w", "weight_g": "200g", "os": "ColorOS 15", "launch": "2025年05月27日", "nfc": "支持NFC", "waterproof": "IP65等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑9400e"}, "metrics": {"battery_mah": 7100.0, "charge_w": 80.0, "weight_g": 200.0, "screen_inch": 6.77, "refresh_hz": 120.0, "ram": 16.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 220, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2128993", "url": "https://detail.zol.com.cn/cell_phone/index2128993.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/272_320x240/556/ce1XbUku3kCTQ.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '16GB/512GB', 2499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Ace 5 竞速版'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享90 Pro Max 512GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享90 Pro Max 512GB', '华为畅享90 Pro Max 512GB',
       DATE '2026-03-23',
       2399,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/634/ceGvsAvx8Exjc.jpg',
       $json${"display": {"cpu": "海思 麒麟8000 ， 手机性能排行", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.84英寸", "resolution": "2756x1272px", "refresh_hz": "120Hz", "battery_mah": "8500mAh 大电池", "charge_w": "40w", "weight_g": "232g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP65", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000"}, "metrics": {"battery_mah": 8500.0, "charge_w": 40.0, "weight_g": 232.0, "screen_inch": 6.84, "refresh_hz": 120.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 60, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161468", "url": "https://detail.zol.com.cn/cell_phone/index2161468.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/634/ceGvsAvx8Exjc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 2399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享90 Pro Max 512GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Turbo 6V
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 6V', '一加Turbo 6V(12GB/512GB)',
       DATE '2026-01-08',
       2399,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/274_800x600/421/cexfBAVvHOsE.png',
       $json${"display": {"cpu": "高通 骁龙7S Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "144Hz", "weight_g": "215g", "os": "ColorOS 16", "launch": "2026年1月8日", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素", "cpu_tier_name": "骁龙7sgen4"}, "metrics": {"weight_g": 215.0, "screen_inch": 6.78, "refresh_hz": 144.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 100, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2153081", "url": "https://detail.zol.com.cn/cell_phone/index2153081.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/274_320x240/421/cexfBAVvHOsE.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2399 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Turbo 6V'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Z11
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Z11', 'iQOO Z11(12GB/256GB)',
       DATE '2026-03-26',
       2299,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/881/cen0erZc9OEe6.jpg',
       $json${"display": {"cpu": "联发科 天玑 8500 Elite ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1260px", "refresh_hz": "165Hz", "battery_mah": "9020mAh 大电池", "charge_w": "90w", "weight_g": "216.5g", "os": "OriginOS 6", "launch": "2026年03月26日", "nfc": "支持NFC", "waterproof": "IP68/IP69级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑8500"}, "metrics": {"battery_mah": 9020.0, "charge_w": 90.0, "screen_inch": 6.83, "refresh_hz": 165.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 200, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161680", "url": "https://detail.zol.com.cn/cell_phone/index2161680.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/881/cen0erZc9OEe6.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 2299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Z11'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO K15
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'K15', 'OPPO K15（12GB/256GB）',
       NULL,
       2299,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/276_800x600/887/ce1JBxUghjWQA.png',
       $json${"display": {"cpu": "联发科 天玑 7360 SUPER ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.59英寸", "resolution": "2760x1256px", "refresh_hz": "120Hz（60/90/120Hz）", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "205g", "os": "ColorOS 16", "launch": "2026 年7月24日", "nfc": "支持NFC（多功能）", "waterproof": "IP69防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：5000万像素 前置摄像头1：5000万像素", "cpu_tier_name": "天玑7360"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 205.0, "screen_inch": 6.59, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 70, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2173239", "url": "https://detail.zol.com.cn/cell_phone/index2173239.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/276_320x240/887/ce1JBxUghjWQA.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 2299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'K15'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 M100
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'M100', 'Redmi M100（8GB/256GB）',
       DATE '2026-08-18',
       2199,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/276_800x600/590/ceyEzurqCuuk.png',
       $json${"display": {"cpu": "高通 骁龙4 Gen5 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.9英寸", "resolution": "1600x720px", "refresh_hz": "120Hz", "battery_mah": "7900mAh 大电池", "charge_w": "45W有线快充，22.5W有线反充", "weight_g": "232g", "os": "Xiaomi HyperOS 3", "launch": "2026年08月18日", "nfc": "支持NFC（多功能）", "waterproof": "IP64防尘防水", "rear_camera": "后置摄像头1：1300万像素 前置摄像头1：500万像素", "cpu_tier_name": "骁龙4gen5"}, "metrics": {"battery_mah": 7900.0, "charge_w": 45.0, "weight_g": 232.0, "screen_inch": 6.9, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 1300.0, "cpu_score": 48, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2175585", "url": "https://detail.zol.com.cn/cell_phone/index2175585.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/276_320x240/590/ceyEzurqCuuk.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 2199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'M100'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 Play11 Plus
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Play11 Plus', '荣耀Play11 Plus（8GB/256GB）',
       NULL,
       2199,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/910/ceVCjrx1wxM.png',
       $json${"display": {"cpu": "联发科 天玑6500 Elite ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.6英寸", "resolution": "1200x2600px", "refresh_hz": "120Hz（60/90/120Hz）", "battery_mah": "7000mAh 大电池", "charge_w": "45w", "weight_g": "185g", "os": "MagicOS 10", "launch": "2026年4月", "nfc": "支持NFC", "waterproof": "IP66防尘抗水", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑6500"}, "metrics": {"battery_mah": 7000.0, "charge_w": 45.0, "weight_g": 185.0, "screen_inch": 6.6, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 55, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2166055", "url": "https://detail.zol.com.cn/cell_phone/index2166055.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/910/ceVCjrx1wxM.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 2199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'Play11 Plus'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Z11x
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Z11x', 'iQOO Z11x(12GB/512GB)',
       DATE '2026-03-26',
       2199,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/919/cesGtUxwvq6FQ.jpg',
       $json${"display": {"cpu": "联发科 天玑 7400 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "512GB 10.5万张照片 4.4万首歌曲", "screen_inch": "6.76英寸", "resolution": "2344x1080px", "refresh_hz": "120Hz", "battery_mah": "7200mAh 大电池", "charge_w": "44w", "weight_g": "219g", "os": "OriginOS 6", "launch": "2026年03月26日", "nfc": "支持NFC", "waterproof": "IP68/IP69级防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑7400"}, "metrics": {"battery_mah": 7200.0, "charge_w": 44.0, "weight_g": 219.0, "screen_inch": 6.76, "refresh_hz": 120.0, "ram": 12.0, "rom": 512.0, "rear_mp": 5000.0, "cpu_score": 74, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161688", "url": "https://detail.zol.com.cn/cell_phone/index2161688.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/919/cesGtUxwvq6FQ.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/512GB', 2199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Z11x'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- OPPO A6 Max
INSERT INTO biz.brand(name) VALUES ('OPPO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'A6 Max', 'OPPO A6 Max（8GB/256GB）',
       DATE '2025-09-10',
       2199,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/274_800x600/130/cerH7r1ecLclg.jpg',
       $json${"display": {"cpu": "高通 骁龙7 Gen3 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.8英寸", "resolution": "2800x1280px", "refresh_hz": "120Hz（60/90/120Hz）", "battery_mah": "7000mAh 大电池", "charge_w": "80w", "weight_g": "198g", "os": "ColorOS 15", "launch": "2025年09月10日", "nfc": "支持NFC（全场景）", "waterproof": "IP69防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：3200万像素", "cpu_tier_name": "骁龙7gen3"}, "metrics": {"battery_mah": 7000.0, "charge_w": 80.0, "weight_g": 198.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 88, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2159501", "url": "https://detail.zol.com.cn/cell_phone/index2159501.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/274_320x240/130/cerH7r1ecLclg.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'OPPO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 2199 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'OPPO' AND p.model = 'A6 Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y600
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y600', 'vivo Y600(8GB/128GB)',
       NULL,
       2099,
       '京东/天猫(参考)', now(),
       'https://2f.zol-img.com.cn/product/276_800x600/477/ceflWE2PxbS82.png',
       $json${"display": {"cpu": "联发科 天玑 7300e ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.83英寸", "resolution": "2800x1260px", "refresh_hz": "120Hz", "battery_mah": "10000mAh 大电池", "charge_w": "44w", "weight_g": "224g", "os": "OriginOS 6", "launch": "2026年10月", "nfc": "支持NFC", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑7300"}, "metrics": {"battery_mah": 10000.0, "charge_w": 44.0, "weight_g": 224.0, "screen_inch": 6.83, "refresh_hz": 120.0, "ram": 8.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 72, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2181674", "url": "https://detail.zol.com.cn/cell_phone/index2181674.shtml", "image_thumb": "https://2f.zol-img.com.cn/product/276_320x240/477/ceflWE2PxbS82.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/128GB', 2099 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y600'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y600i
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y600i', 'vivo Y600i（6GB/256GB）',
       DATE '2026-09-30',
       1999,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/276_800x600/535/ceKysGiiPhGG6.jpg',
       $json${"display": {"cpu": "高通 骁龙4 Gen2 ， 手机性能排行", "ram": "6GB 游戏运行良好", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.87英寸", "resolution": "1592x720px", "refresh_hz": "120Hz", "battery_mah": "8000mAh 大电池", "charge_w": "44w", "weight_g": "229g", "os": "OriginOS 6", "launch": "2026年9月30日", "nfc": "支持NFC", "waterproof": "CQCIP68+IP69", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙4gen2"}, "metrics": {"battery_mah": 8000.0, "charge_w": 44.0, "weight_g": 229.0, "screen_inch": 6.87, "refresh_hz": 120.0, "ram": 6.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 40, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2181678", "url": "https://detail.zol.com.cn/cell_phone/index2181678.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/276_320x240/535/ceKysGiiPhGG6.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '6GB/256GB', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y600i'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Turbo 6X Pro
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 6X Pro', '一加Turbo 6X Pro（8GB/256GB）',
       DATE '2026-06-10',
       1999,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/421/ceyo3Bmx9EU.jpg',
       $json${"display": {"cpu": "联发科 天玑 7400 SUPER ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.78英寸", "resolution": "2772x1272px", "refresh_hz": "144Hz", "battery_mah": "8000mAh 大电池", "charge_w": "80w", "weight_g": "213g", "os": "ColorOS 16", "launch": "2026年6月10日", "nfc": "支持NFC（多功能）", "waterproof": "IP66，IP68，IP69，IP69K防水等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：800万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑7400"}, "metrics": {"battery_mah": 8000.0, "charge_w": 80.0, "weight_g": 213.0, "screen_inch": 6.78, "refresh_hz": 144.0, "ram": 8.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 74, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2168621", "url": "https://detail.zol.com.cn/cell_phone/index2168621.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/421/ceyo3Bmx9EU.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Turbo 6X Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享90 Pro Max 256GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享90 Pro Max 256GB', '华为畅享90 Pro Max 256GB',
       DATE '2026-03-23',
       1999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/634/ceGvsAvx8Exjc.jpg',
       $json${"display": {"cpu": "海思 麒麟8000 ， 手机性能排行", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.84英寸", "resolution": "2756x1272px", "refresh_hz": "120Hz", "battery_mah": "8500mAh 大电池", "charge_w": "40w", "weight_g": "232g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP65", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000"}, "metrics": {"battery_mah": 8500.0, "charge_w": 40.0, "weight_g": 232.0, "screen_inch": 6.84, "refresh_hz": 120.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 60, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161467", "url": "https://detail.zol.com.cn/cell_phone/index2161467.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/634/ceGvsAvx8Exjc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享90 Pro Max 256GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 Note17 Pro
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Note17 Pro', 'Redmi Note17 Pro(12GB/256GB)',
       NULL,
       1999,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/928/celcn46Sje8A.png',
       $json${"display": {"cpu": "高通 骁龙6S Gen4 ， 手机性能排行", "ram": "12GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.83英寸", "resolution": "2772x1280px", "refresh_hz": "120Hz", "battery_mah": "9000mAh 大电池", "charge_w": "67w", "weight_g": "226g", "os": "Xiaomi HyperOS 3", "nfc": "支持NFC", "waterproof": "IP66、IP68、IP69和IP69K防尘防水", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙6sgen4"}, "metrics": {"battery_mah": 9000.0, "charge_w": 67.0, "weight_g": 226.0, "screen_inch": 6.83, "refresh_hz": 120.0, "ram": 12.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 58, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2172331", "url": "https://detail.zol.com.cn/cell_phone/index2172331.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/928/celcn46Sje8A.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '12GB/256GB', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'Note17 Pro'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 X80 Pro Max
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'X80 Pro Max', '荣耀X80 Pro Max(8GB/128GB)',
       NULL,
       1999,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/854/ceY4IXT6lpHs.jpg',
       $json${"display": {"cpu": "高通 骁龙6 Gen5 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.8英寸", "resolution": "2788x1280px", "refresh_hz": "120Hz", "battery_mah": "11000mAh 大电池", "charge_w": "80w", "weight_g": "203g", "os": "MagicOS 10.0", "launch": "2026年6月", "nfc": "支持NFC", "waterproof": "支持防尘防水（IP66、IP68、IP69、IP69K）", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙6gen5"}, "metrics": {"battery_mah": 11000.0, "charge_w": 80.0, "weight_g": 203.0, "screen_inch": 6.8, "refresh_hz": 120.0, "ram": 8.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 95, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2170102", "url": "https://detail.zol.com.cn/cell_phone/index2170102.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/854/ceY4IXT6lpHs.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/128GB', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = 'X80 Pro Max'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y6
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y6', 'vivo Y6（8GB/256GB）',
       NULL,
       1999,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/275_800x600/478/ceUPsjAxY2.jpg',
       $json${"display": {"cpu": "高通 骁龙 4 Gen2 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.75英寸", "resolution": "1570x720px", "refresh_hz": "120Hz", "battery_mah": "7200mAh 大电池", "charge_w": "44w", "weight_g": "219g", "os": "OriginOS 6", "launch": "2026年4月", "nfc": "支持NFC", "waterproof": "IP68＆IP69", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙4gen2"}, "metrics": {"battery_mah": 7200.0, "charge_w": 44.0, "weight_g": 219.0, "screen_inch": 6.75, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 40, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2164553", "url": "https://detail.zol.com.cn/cell_phone/index2164553.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/275_320x240/478/ceUPsjAxY2.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 1999 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y6'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 一加 Turbo 6X
INSERT INTO biz.brand(name) VALUES ('一加') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Turbo 6X', '一加Turbo 6X(8GB/128GB)',
       NULL,
       1899,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/418/ceefiQ0DUrzos.jpg',
       $json${"display": {"cpu": "联发科 天玑 7360 SUPER ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.72英寸", "resolution": "2400x1080px", "refresh_hz": "144Hz", "battery_mah": "7000mAh 大电池", "charge_w": "45w", "weight_g": "208g", "os": "ColorOS 16", "nfc": "支持NFC（多功能）", "waterproof": "IP66，IP68，IP69，IP69K", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：800万像素", "cpu_tier_name": "天玑7360"}, "metrics": {"battery_mah": 7000.0, "charge_w": 45.0, "weight_g": 208.0, "screen_inch": 6.72, "refresh_hz": 144.0, "ram": 8.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 70, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2168620", "url": "https://detail.zol.com.cn/cell_phone/index2168620.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/418/ceefiQ0DUrzos.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '一加' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/128GB', 1899 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '一加' AND p.model = 'Turbo 6X'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享90 Plus 256GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享90 Plus 256GB', '华为畅享90 Plus 256GB',
       DATE '2026-03-23',
       1799,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/671/ce1MjjSsrVHGM.jpg',
       $json${"display": {"cpu": "海思 麒麟8000 ， 手机性能排行", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.67英寸", "resolution": "1604x720px", "battery_mah": "6620mAh 大电池", "charge_w": "40w", "weight_g": "212g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP64", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000"}, "metrics": {"battery_mah": 6620.0, "charge_w": 40.0, "weight_g": 212.0, "screen_inch": 6.67, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 60, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161469", "url": "https://detail.zol.com.cn/cell_phone/index2161469.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/671/ce1MjjSsrVHGM.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享90 Plus 256GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- vivo Y60
INSERT INTO biz.brand(name) VALUES ('vivo') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Y60', 'vivo Y60(8GB/256GB)',
       NULL,
       1799,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/887/ceI8SkRoLZNM.jpg',
       $json${"display": {"cpu": "高通 骁龙 4 Gen2 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.74英寸", "resolution": "1600x720px", "refresh_hz": "120Hz", "battery_mah": "6500mAh 大电池", "charge_w": "15w", "weight_g": "209g", "os": "OriginOS 6", "launch": "2026年4月", "rear_camera": "后置摄像头1：1300万像素 前置摄像头1：500万像素", "cpu_tier_name": "骁龙4gen2"}, "metrics": {"battery_mah": 6500.0, "charge_w": 15.0, "weight_g": 209.0, "screen_inch": 6.74, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 1300.0, "cpu_score": 40, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2164557", "url": "https://detail.zol.com.cn/cell_phone/index2164557.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/887/ceI8SkRoLZNM.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'vivo' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 1799 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'vivo' AND p.model = 'Y60'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享90 Pro Max 128GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享90 Pro Max 128GB', '华为畅享90 Pro Max 128GB',
       DATE '2026-03-23',
       1699,
       '京东/天猫(参考)', now(),
       'https://2a.zol-img.com.cn/product/275_800x600/634/ceGvsAvx8Exjc.jpg',
       $json${"display": {"cpu": "海思 麒麟8000 ， 手机性能排行", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.84英寸", "resolution": "2756x1272px", "refresh_hz": "120Hz", "battery_mah": "8500mAh 大电池", "charge_w": "40w", "weight_g": "232g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP65", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000"}, "metrics": {"battery_mah": 8500.0, "charge_w": 40.0, "weight_g": 232.0, "screen_inch": 6.84, "refresh_hz": 120.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 60, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2160696", "url": "https://detail.zol.com.cn/cell_phone/index2160696.shtml", "image_thumb": "https://2a.zol-img.com.cn/product/275_320x240/634/ceGvsAvx8Exjc.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1699 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享90 Pro Max 128GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享 90 256GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享 90 256GB', '华为畅享 90 256GB',
       DATE '2026-03-23',
       1599,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/781/cetRgFGPKFDk.jpg',
       $json${"display": {"cpu": "海思 麒麟 8000A ， 手机性能排行", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.67英寸", "resolution": "1604x720px", "battery_mah": "6620mAh 大电池", "charge_w": "40w", "weight_g": "212g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP64", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000a"}, "metrics": {"battery_mah": 6620.0, "charge_w": 40.0, "weight_g": 212.0, "screen_inch": 6.67, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 62, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161471", "url": "https://detail.zol.com.cn/cell_phone/index2161471.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/781/cetRgFGPKFDk.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享 90 256GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 Note 17
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Note 17', 'Redmi Note 17（8GB/256GB）',
       DATE '2026-07-14',
       1599,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/976/cenFKECFrsXo.png',
       $json${"display": {"cpu": "高通 骁龙4 Gen4 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "7英寸", "resolution": "2396x1080px", "refresh_hz": "120Hz", "battery_mah": "8000mAh 大电池", "charge_w": "45w有线快充，22.5w有线反充", "weight_g": "225g", "os": "Xiaomi HyperOS 3", "launch": "2026年7月14日", "nfc": "支持NFC（多功能）", "waterproof": "IP65等级", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "骁龙4gen4"}, "metrics": {"battery_mah": 8000.0, "charge_w": 45.0, "weight_g": 225.0, "screen_inch": 7.0, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 5000.0, "cpu_score": 38, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2172334", "url": "https://detail.zol.com.cn/cell_phone/index2172334.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/976/cenFKECFrsXo.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 1599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'Note 17'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- iQOO Z11i
INSERT INTO biz.brand(name) VALUES ('iQOO') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Z11i', 'iQOO Z11i(8GB/256GB)',
       DATE '2026-07-03',
       1599,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/277/ceKevzgjjFys.jpg',
       $json${"display": {"cpu": "高通 骁龙 4 Gen2 ， 手机性能排行", "ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.74英寸", "resolution": "1600x720px", "refresh_hz": "120Hz", "battery_mah": "6500mAh 大电池", "charge_w": "15w", "weight_g": "209g", "os": "OriginOS 6", "launch": "2026年07月03日", "nfc": "支持NFC", "waterproof": "IP65防尘防水", "rear_camera": "后置摄像头1：1300万像素 前置摄像头1：500万像素", "cpu_tier_name": "骁龙4gen2"}, "metrics": {"battery_mah": 6500.0, "charge_w": 15.0, "weight_g": 209.0, "screen_inch": 6.74, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 1300.0, "cpu_score": 40, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2171057", "url": "https://detail.zol.com.cn/cell_phone/index2171057.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/277/ceKevzgjjFys.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = 'iQOO' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '8GB/256GB', 1599 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = 'iQOO' AND p.model = 'Z11i'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享90 Plus 128GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享90 Plus 128GB', '华为畅享90 Plus 128GB',
       DATE '2026-03-23',
       1499,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/275_800x600/671/ce1MjjSsrVHGM.jpg',
       $json${"display": {"cpu": "海思 麒麟8000 ， 手机性能排行", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.67英寸", "resolution": "1604x720px", "battery_mah": "6620mAh 大电池", "charge_w": "40w", "weight_g": "212g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP64", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000"}, "metrics": {"battery_mah": 6620.0, "charge_w": 40.0, "weight_g": 212.0, "screen_inch": 6.67, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 60, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2160695", "url": "https://detail.zol.com.cn/cell_phone/index2160695.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/275_320x240/671/ce1MjjSsrVHGM.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1499 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享90 Plus 128GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 华为 畅享 90 128GB
INSERT INTO biz.brand(name) VALUES ('华为') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅享 90 128GB', '华为畅享 90 128GB',
       DATE '2026-03-23',
       1299,
       '京东/天猫(参考)', now(),
       'https://2d.zol-img.com.cn/product/275_800x600/781/cetRgFGPKFDk.jpg',
       $json${"display": {"cpu": "海思 麒麟 8000A ， 手机性能排行", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.67英寸", "resolution": "1604x720px", "battery_mah": "6620mAh 大电池", "charge_w": "40w", "weight_g": "212g", "os": "HarmonyOS 6.0", "launch": "2026年3月23日", "waterproof": "IP64", "rear_camera": "后置摄像头1：5000万像素 前置摄像头1：800万像素", "cpu_tier_name": "麒麟8000a"}, "metrics": {"battery_mah": 6620.0, "charge_w": 40.0, "weight_g": 212.0, "screen_inch": 6.67, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 62, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2161470", "url": "https://detail.zol.com.cn/cell_phone/index2161470.shtml", "image_thumb": "https://2d.zol-img.com.cn/product/275_320x240/781/cetRgFGPKFDk.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '华为' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', 1299 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '华为' AND p.model = '畅享 90 128GB'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 红米 Note 14
INSERT INTO biz.brand(name) VALUES ('红米') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'Note 14', 'Redmi Note 14(6GB/128GB)',
       DATE '2024-09-26',
       1099,
       '京东/天猫(参考)', now(),
       'https://2c.zol-img.com.cn/product/269_800x600/134/cecWba35iSyw.png',
       $json${"display": {"cpu": "联发科 天玑 7025-Ultra ， 手机性能排行", "ram": "6GB 游戏运行良好", "rom": "128GB 2.6万张照片 1.1万首歌曲", "screen_inch": "6.67英寸", "resolution": "2400x1080px", "refresh_hz": "120Hz", "battery_mah": "5110mAh 大电池", "charge_w": "45w", "weight_g": "190g", "os": "Xiaomi HyperOS", "launch": "2024年9月26日", "waterproof": "IP64等级", "rear_camera": "后置摄像头1：5000万像素 后置摄像头2：200万像素 前置摄像头1：1600万像素", "cpu_tier_name": "天玑7025"}, "metrics": {"battery_mah": 5110.0, "charge_w": 45.0, "weight_g": 190.0, "screen_inch": 6.67, "refresh_hz": 120.0, "ram": 6.0, "rom": 128.0, "rear_mp": 5000.0, "cpu_score": 65, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2101023", "url": "https://detail.zol.com.cn/cell_phone/index2101023.shtml", "image_thumb": "https://2c.zol-img.com.cn/product/269_320x240/134/cecWba35iSyw.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '红米' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '6GB/128GB', 1099 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '红米' AND p.model = 'Note 14'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 荣耀 畅玩70C
INSERT INTO biz.brand(name) VALUES ('荣耀') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, '畅玩70C', '荣耀畅玩70C(4GB/64GB)',
       NULL,
       598,
       '京东/天猫(参考)', now(),
       'https://2e.zol-img.com.cn/product/275_800x600/768/cexOrem5Rzx9A.png',
       $json${"display": {"cpu": "联发科 Helio G81-Ultra ， 手机性能排行", "ram": "4GB 游戏运行一般", "rom": "64GB 1.3万张照片 5461首歌曲", "screen_inch": "6.75英寸", "resolution": "1600x720px", "refresh_hz": "90Hz", "battery_mah": "5300mAh 大电池", "weight_g": "186g", "os": "MagicOS 9.0", "launch": "2026年5月", "rear_camera": "后置摄像头1：1300万像素 前置摄像头1：500万像素", "cpu_tier_name": "heliog81"}, "metrics": {"battery_mah": 5300.0, "weight_g": 186.0, "screen_inch": 6.75, "refresh_hz": 90.0, "ram": 4.0, "rom": 64.0, "rear_mp": 1300.0, "cpu_score": 30, "dxo_camera": 0, "image_score": 40.0}, "source": "zol", "source_id": "2166017", "url": "https://detail.zol.com.cn/cell_phone/index2166017.shtml", "image_thumb": "https://2e.zol-img.com.cn/product/275_320x240/768/cexOrem5Rzx9A.png"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '荣耀' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '4GB/64GB', 598 FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '荣耀' AND p.model = '畅玩70C'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 苹果 iPhone 18
INSERT INTO biz.brand(name) VALUES ('苹果') ON CONFLICT (name) DO NOTHING;
INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, 'iPhone 18', 'Apple（苹果）iPhone 18',
       NULL,
       NULL,
       '京东/天猫(参考)', now(),
       'https://2b.zol-img.com.cn/product/273_800x600/985/ce6sSazvBooWE.jpg',
       $json${"display": {"ram": "8GB 游戏运行流畅", "rom": "256GB 5.2万张照片 2.2万首歌曲", "screen_inch": "6.3英寸", "resolution": "2622x1206px", "refresh_hz": "120Hz", "charge_w": "40w", "weight_g": "177g", "os": "iOS 26", "nfc": "支持NFC", "waterproof": "IP68等级", "rear_camera": "后置摄像头1：4800万像素 后置摄像头2：4800万像素 前置摄像头1：1800万像素", "cpu_source": "同价位估算"}, "metrics": {"charge_w": 40.0, "weight_g": 177.0, "screen_inch": 6.3, "refresh_hz": 120.0, "ram": 8.0, "rom": 256.0, "rear_mp": 4800.0, "image_score": 55.0, "cpu_score": 357}, "source": "zol", "source_id": "2145488", "url": "https://detail.zol.com.cn/cell_phone/index2145488.shtml", "image_thumb": "https://2b.zol-img.com.cn/product/273_320x240/985/ce6sSazvBooWE.jpg"}$json$::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = '苹果' AND c.code = 'phone'
ON CONFLICT (brand_id, model) DO NOTHING;
INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, '', NULL FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = '苹果' AND p.model = 'iPhone 18'
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;

-- 4. 演示用户（密码 123456）
INSERT INTO biz.users(username, password_hash, nickname)
VALUES ('u1001', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '演示用户')
ON CONFLICT (username) DO NOTHING;

COMMIT;
