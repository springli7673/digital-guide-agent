"""建库 + 建表 + 初始化类目

用法：
    python tools/init_db.py
"""

import json
import re
from pathlib import Path

import psycopg

ROOT = Path(__file__).resolve().parent.parent
DB_NAME = "digital_guide"
ADMIN_DSN = "postgresql://postgres:123456@127.0.0.1:5432/postgres"
DB_DSN = f"postgresql://postgres:123456@127.0.0.1:5432/{DB_NAME}"

CATEGORIES = [
    ("phone", "手机", {
        "battery_mah": {"label": "电池容量", "unit": "mAh", "better": "higher", "weight": 1.0},
        "charge_w": {"label": "充电功率", "unit": "W", "better": "higher", "weight": 0.7},
        "screen_inch": {"label": "屏幕尺寸", "unit": "英寸", "better": "higher", "weight": 0.3},
        "refresh_hz": {"label": "刷新率", "unit": "Hz", "better": "higher", "weight": 0.4},
        "weight_g": {"label": "重量", "unit": "g", "better": "lower", "weight": 0.5},
        "rear_mp": {"label": "后置主摄", "unit": "万像素", "better": "higher", "weight": 1.0},
        "ram": {"label": "运行内存", "unit": "GB", "better": "higher", "weight": 0.6},
        "rom": {"label": "存储容量", "unit": "GB", "better": "higher", "weight": 0.4},
    }, 1),
    ("earbuds", "耳机", {
        "battery_h": {"label": "续航", "unit": "小时", "better": "higher", "weight": 1.0},
        "weight_g": {"label": "重量", "unit": "g", "better": "lower", "weight": 0.6},
        "anc_db": {"label": "降噪深度", "unit": "dB", "better": "higher", "weight": 1.0},
    }, 2),
    ("camera", "相机", {
        "sensor_mp": {"label": "有效像素", "unit": "万", "better": "higher", "weight": 1.0},
        "weight_g": {"label": "重量", "unit": "g", "better": "lower", "weight": 0.5},
    }, 3),
    ("powerbank", "充电宝", {
        "capacity_mah": {"label": "容量", "unit": "mAh", "better": "higher", "weight": 1.0},
        "power_w": {"label": "输出功率", "unit": "W", "better": "higher", "weight": 1.0},
    }, 4),
]


def ensure_database() -> None:
    with psycopg.connect(ADMIN_DSN, autocommit=True, connect_timeout=5) as conn:
        exists = conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_NAME,)).fetchone()
        if not exists:
            conn.execute(f'CREATE DATABASE {DB_NAME}')
            print(f"database {DB_NAME} created")
        else:
            print(f"database {DB_NAME} exists")


def ensure_schema() -> None:
    sql = (ROOT / "db" / "schema.sql").read_text(encoding="utf-8")
    with psycopg.connect(DB_DSN, autocommit=True, connect_timeout=5) as conn:
        conn.execute(sql)
        print("schema applied")


def seed_categories() -> None:
    with psycopg.connect(DB_DSN, autocommit=True) as conn:
        for code, name, schema, sort in CATEGORIES:
            conn.execute(
                """INSERT INTO biz.category(code, name, spec_schema, sort)
                   VALUES (%s, %s, %s::jsonb, %s)
                   ON CONFLICT (code) DO UPDATE
                   SET name = EXCLUDED.name, spec_schema = EXCLUDED.spec_schema, sort = EXCLUDED.sort""",
                (code, name, json.dumps(schema, ensure_ascii=False), sort),
            )
        print(f"categories seeded: {len(CATEGORIES)}")


if __name__ == "__main__":
    ensure_database()
    ensure_schema()
    seed_categories()
