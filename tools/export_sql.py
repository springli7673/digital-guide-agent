"""把 products.json 转成可直接在 IDEA 控制台执行的 SQL（不依赖 psycopg）

用法：
    python tools/export_sql.py
产物：
    db/seed_products.sql

图片走本地：`image_url` 和 `specs.image_thumb` 都写成 `/img/products/{source_id}.webp`，
文件由 `tools/fetch_images.py` 下到 `web-vite/public/img/products/`。
不再写 ZOL 的 `zol-img.com.cn` 外链——那家图床会防盗链、也会删图。

脚本会先清空 biz.product_sku / biz.product / biz.brand 再全量写入，
保证数据库内容与 products.json 完全一致（类目和演示用户保留）。
"""

import json
import re
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "normalized" / "products.json"
OUT = ROOT / "db" / "seed_products.sql"

# 商品图在仓库内的公开路径（Vite 把 public/ 挂到根目录）
IMAGE_BASE = "/img/products"


def local_image(p: dict) -> str | None:
    """商品图的本地路径；拿不到 source_id 就退回原始外链。"""
    sid = str(p.get("source_id") or "").strip()
    if sid:
        return f"{IMAGE_BASE}/{sid}.webp"
    return p.get("image_url")


WHITELIST = ["华为", "小米", "红米", "OPPO", "一加", "vivo", "iQOO", "荣耀", "苹果"]

BRAND_ALIAS = {
    "huawei": "华为", "华为": "华为",
    "xiaomi": "小米", "小米": "小米",
    "redmi": "红米", "红米": "红米",
    "apple": "苹果", "苹果": "苹果", "iphone": "苹果",
    "honor": "荣耀", "荣耀": "荣耀",
    "oneplus": "一加", "一加": "一加",
    "oppo": "OPPO", "vivo": "vivo", "iqoo": "iQOO",
}

CATEGORY_SPECS = {
    "phone": {
        "battery_mah": {"label": "电池容量", "unit": "mAh", "better": "higher", "weight": 1.0},
        "charge_w": {"label": "充电功率", "unit": "W", "better": "higher", "weight": 0.7},
        "weight_g": {"label": "重量", "unit": "g", "better": "lower", "weight": 0.5},
        "image_score": {"label": "影像梯队", "unit": "分", "better": "higher", "weight": 1.0},
        "dxo_camera": {"label": "DXO 影像", "unit": "分", "better": "higher", "weight": 0.5},
        "rear_mp": {"label": "后置主摄", "unit": "万像素", "better": "higher", "weight": 0.4},
        "cpu_score": {"label": "处理器", "unit": "分", "better": "higher", "weight": 0.8},
        "ram": {"label": "运行内存", "unit": "GB", "better": "higher", "weight": 0.6},
        "refresh_hz": {"label": "刷新率", "unit": "Hz", "better": "higher", "weight": 0.4},
        "screen_inch": {"label": "屏幕尺寸", "unit": "英寸", "better": "higher", "weight": 0.3},
    },
}


def q(value) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def dollar(obj) -> str:
    text = json.dumps(obj, ensure_ascii=False)
    return f"$json${text}$json$"


def parse_date(text):
    if not text:
        return None
    m = re.search(r"(\d{4})年(\d{1,2})月(\d{1,2})日", text)
    if m:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3))).isoformat()
    m = re.search(r"(\d{4})-(\d{1,2})-(\d{1,2})", text)
    if m:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3))).isoformat()
    return None


def main() -> int:
    payload = json.loads(SRC.read_text(encoding="utf-8"))
    products = payload["products"]
    category = payload.get("category", "phone")

    # 品牌白名单校验：脏数据在这里就炸，不要带进库里
    bad = [p for p in products
           if BRAND_ALIAS.get((p.get("brand") or "").strip().lower(),
                              (p.get("brand") or "").strip()) not in WHITELIST]
    if bad:
        names = "、".join(f"{p.get('brand')} {p.get('model')}" for p in bad[:5])
        raise SystemExit(f"[FAIL] 有 {len(bad)} 款不在白名单里：{names}")

    lines = [
        "-- 由 tools/export_sql.py 自动生成，可重复执行（每次全量重建商品目录）",
        f"-- 商品 {len(products)} 款，生成时间 {payload.get('generated_at', '')}",
        "BEGIN;",
        "",
        "-- 1. 类目（权重配置）",
        f"""INSERT INTO biz.category(code, name, spec_schema, sort)
VALUES ({q(category)}, {q("手机")}, {dollar(CATEGORY_SPECS.get(category, {}))}::jsonb, 1)
ON CONFLICT (code) DO UPDATE SET spec_schema = EXCLUDED.spec_schema;""",
        "",
        "-- 2. 全量重建商品目录（先清空，保证与 products.json 一致）",
        "DELETE FROM biz.product_sku WHERE product_id IN (SELECT id FROM biz.product);",
        "DELETE FROM biz.review WHERE product_id IN (SELECT id FROM biz.product);",
        "DELETE FROM biz.product;",
        "DELETE FROM biz.brand;",
        "",
        "-- 3. 商品",
    ]

    brands_seen: dict[str, int] = {}
    for p in products:
        brand = BRAND_ALIAS.get((p.get("brand") or "").strip().lower(),
                                (p.get("brand") or "").strip())
        model = p.get("model") or p.get("title") or "未知型号"
        brands_seen[brand] = brands_seen.get(brand, 0) + 1

        display = {k: v for k, v in (p.get("specs") or {}).items() if v}
        image = local_image(p)
        specs = {
            "display": display,
            "metrics": p.get("metrics", {}),
            "source": p.get("source"),
            "source_id": p.get("source_id"),
            "url": p.get("url"),
        }
        if image:
            specs["image_thumb"] = image
        launch = parse_date(p.get("launch_date"))
        price = p.get("price_ref") if p.get("price_ref") is not None else "NULL"

        lines.append(f"-- {brand} {model}")
        lines.append(f"INSERT INTO biz.brand(name) VALUES ({q(brand)}) ON CONFLICT (name) DO NOTHING;")
        lines.append(
            f"""INSERT INTO biz.product
  (brand_id, category_id, model, title, launch_date, price_ref, price_source,
   price_updated_at, image_url, specs, data_source, status)
SELECT b.id, c.id, {q(model)}, {q(p.get("title") or model)},
       {("DATE " + q(launch)) if launch else "NULL"},
       {price},
       {q(p.get("price_source") or "参考价")}, now(),
       {q(image)},
       {dollar(specs)}::jsonb, 'zol', 'ON_SALE'
FROM biz.brand b, biz.category c
WHERE b.name = {q(brand)} AND c.code = {q(category)}
ON CONFLICT (brand_id, model) DO NOTHING;"""
        )

        variants = p.get("variants") or [{"storage": p.get("storage"), "price_ref": p.get("price_ref")}]
        for v in variants:
            storage = (v.get("storage") or "").strip()
            vprice = v.get("price_ref") if v.get("price_ref") is not None else "NULL"
            lines.append(
                f"""INSERT INTO biz.product_sku(product_id, storage, price_ref)
SELECT p.id, {q(storage)}, {vprice} FROM biz.product p
JOIN biz.brand b ON b.id = p.brand_id
WHERE b.name = {q(brand)} AND p.model = {q(model)}
ON CONFLICT (product_id, storage, color) DO UPDATE SET price_ref = EXCLUDED.price_ref;"""
            )
        lines.append("")

    lines += [
        "-- 4. 演示用户（密码 123456）",
        """INSERT INTO biz.users(username, password_hash, nickname)
VALUES ('u1001', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '演示用户')
ON CONFLICT (username) DO NOTHING;""",
        "",
        "COMMIT;",
        "",
    ]

    OUT.write_text("\n".join(lines), encoding="utf-8")
    kb = OUT.stat().st_size / 1024
    print(f"generated {OUT} （{len(products)} 款 / {kb:.0f} KB）")
    print("品牌分布：", "  ".join(f"{k} {v}" for k, v in sorted(brands_seen.items(), key=lambda x: -x[1])))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
