"""把 data/normalized/products.json 导入数据库（幂等）

用法：
    python tools/import_products.py
    python tools/import_products.py --file data/normalized/products.json
"""

import argparse
import json
import re
from datetime import date
from pathlib import Path

import psycopg

ROOT = Path(__file__).resolve().parent.parent
DSN = "postgresql://postgres:123456@127.0.0.1:5432/digital_guide"

# 品牌中英文归一
BRAND_ALIAS = {
    "huawei": "华为", "华为": "华为",
    "xiaomi": "小米", "小米": "小米",
    "redmi": "红米", "红米": "红米",
    "apple": "苹果", "苹果": "苹果",
    "honor": "荣耀", "荣耀": "荣耀",
    "oneplus": "一加", "一加": "一加", "一加（oneplus）": "一加",
    "realme": "真我", "真我": "真我",
    "samsung": "三星", "三星": "三星",
    "oppo": "OPPO", "vivo": "vivo", "iqoo": "iQOO",
    "nubia": "努比亚", "努比亚": "努比亚",
    "meizu": "魅族", "魅族": "魅族",
    "sony": "索尼", "索尼": "索尼",
    "motorola": "摩托罗拉", "摩托罗拉": "摩托罗拉", "moto": "摩托罗拉",
}


def normalize_brand(name: str) -> str:
    key = (name or "").strip().lower()
    return BRAND_ALIAS.get(key, BRAND_ALIAS.get(name.strip(), name.strip() or "未知"))


def parse_date(text: str | None) -> date | None:
    if not text:
        return None
    m = re.search(r"(\d{4})年(\d{1,2})月(\d{1,2})日", text)
    if m:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    m = re.search(r"(\d{4})-(\d{1,2})-(\d{1,2})", text)
    if m:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    return None


def upsert_brand(cur, name: str) -> int:
    cur.execute(
        """INSERT INTO biz.brand(name) VALUES (%s)
           ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
           RETURNING id""",
        (name,),
    )
    return cur.fetchone()[0]


def upsert_product(cur, brand_id: int, category_id: int, item: dict) -> int:
    specs = {
        "display": item.get("specs", {}),
        "metrics": item.get("metrics", {}),
        "source": item.get("source"),
        "source_id": item.get("source_id"),
        "url": item.get("url"),
        "raw_param_count": item.get("raw_param_count"),
    }
    cur.execute(
        """INSERT INTO biz.product
             (brand_id, category_id, model, title, launch_date, price_ref, price_source,
              price_updated_at, specs, data_source, status)
           VALUES (%s, %s, %s, %s, %s, %s, %s, now(), %s::jsonb, %s, 'ON_SALE')
           ON CONFLICT (brand_id, model) DO UPDATE
             SET price_ref = EXCLUDED.price_ref,
                 price_updated_at = now(),
                 specs = EXCLUDED.specs,
                 launch_date = COALESCE(EXCLUDED.launch_date, biz.product.launch_date),
                 title = EXCLUDED.title
           RETURNING id""",
        (brand_id, category_id, item["model"], item.get("title"),
         parse_date(item.get("launch_date")), item.get("price_ref"), item.get("price_source"),
         json.dumps(specs, ensure_ascii=False), item.get("source")),
    )
    return cur.fetchone()[0]


def upsert_sku(cur, product_id: int, variant: dict) -> None:
    storage = variant.get("storage") or ""
    cur.execute(
        """INSERT INTO biz.product_sku(product_id, storage, price_ref)
           VALUES (%s, %s, %s)
           ON CONFLICT (product_id, storage, color) DO UPDATE
             SET price_ref = EXCLUDED.price_ref""",
        (product_id, storage, variant.get("price_ref")),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", default=str(ROOT / "data" / "normalized" / "products.json"))
    args = parser.parse_args()

    payload = json.loads(Path(args.file).read_text(encoding="utf-8"))
    products = payload.get("products", [])
    category_code = payload.get("category", "phone")

    with psycopg.connect(DSN, autocommit=True) as conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM biz.category WHERE code = %s", (category_code,))
        row = cur.fetchone()
        if not row:
            raise SystemExit(f"类目不存在: {category_code}，先跑 tools/init_db.py")
        category_id = row[0]

        ok = 0
        for item in products:
            brand_id = upsert_brand(cur, normalize_brand(item.get("brand")))
            product_id = upsert_product(cur, brand_id, category_id, item)
            variants = item.get("variants") or [{"storage": item.get("storage"), "price_ref": item.get("price_ref")}]
            for variant in variants:
                upsert_sku(cur, product_id, variant)
            ok += 1

        print(f"imported products: {ok}, skus: {sum(len(p.get('variants') or [1]) for p in products)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
