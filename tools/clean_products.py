"""清洗抓取结果：去页面导航文字、重算数值指标、按品牌白名单过滤

用法：
    python tools/clean_products.py
原地重写 data/normalized/products.json（会备份一份 .bak）
"""

import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "normalized" / "products.json"

# 只保留这九个品牌，其余（三星 / 努比亚 / 真我 …）一律丢掉
WHITELIST = ["华为", "小米", "红米", "OPPO", "一加", "vivo", "iQOO", "荣耀", "苹果"]

BRAND_ALIAS = {
    "huawei": "华为", "华为": "华为",
    "xiaomi": "小米", "mi": "小米", "小米": "小米",
    "redmi": "红米", "红米": "红米",
    "oppo": "OPPO",
    "oneplus": "一加", "一加": "一加",
    "vivo": "vivo",
    "iqoo": "iQOO",
    "honor": "荣耀", "荣耀": "荣耀",
    "apple": "苹果", "苹果": "苹果", "iphone": "苹果",
}


def norm_brand(raw: str | None) -> str:
    key = (raw or "").strip()
    return BRAND_ALIAS.get(key.lower(), BRAND_ALIAS.get(key, ""))


def clean_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"\s*纠错\s*$", "", text)
    text = re.sub(r"更多[^，。；]*?>", "", text)
    text = re.sub(r"<[^>]*>", "", text)
    text = text.replace(">", " ")
    text = re.sub(r"\s+", " ", text).strip(" ，,;")
    return text


def num(pattern: str, text: str, scale: float = 1.0):
    if not text:
        return None
    m = re.search(pattern, text, re.I)
    if not m:
        return None
    try:
        return round(float(m.group(1)) * scale, 2)
    except ValueError:
        return None



def megapixel(text: str):
    """「2 亿像素」和「5000 万像素」都要认，取后置第一颗（主摄）的值。

    单位换算：亿 * 10000 万像素。
    """
    if not text:
        return None
    m = re.search(r"(\d+(?:\.\d+)?)\s*(亿|万)\s*像素", text)
    if not m:
        return None
    value = float(m.group(1))
    return round(value * 10000 if m.group(2) == "亿" else value, 2)


def section(text: str, keyword: str) -> str:
    """取 '后置...' 之后、'前置...' 之前的一段，避免前后摄混在一起。"""
    idx = text.find(keyword)
    return text[idx:] if idx >= 0 else ""


def rebuild_metrics(specs: dict) -> dict:
    battery = specs.get("battery_mah", "")
    charge = specs.get("charge_w", "")
    weight = specs.get("weight_g", "")
    screen = specs.get("screen_inch", "")
    refresh = specs.get("refresh_hz", "")
    ram = specs.get("ram", "")
    rom = specs.get("rom", "")
    rear = section(specs.get("rear_camera", ""), "后置")
    front = section(specs.get("front_camera", ""), "前置")

    metrics = {
        "battery_mah": num(r"(\d{3,5})\s*mAh", battery),
        "charge_w": num(r"(\d{1,3})\s*w", charge),
        "weight_g": num(r"(\d{2,3})\s*g", weight),
        "screen_inch": num(r"([\d.]+)\s*英寸", screen),
        "refresh_hz": num(r"(\d{2,3})\s*Hz", refresh),
        "ram": num(r"(\d+)\s*GB", ram),
        "rom": num(r"([\d.]+)\s*TB", rom, 1024) or num(r"(\d+)\s*GB", rom),
        "rear_mp": megapixel(rear or specs.get("rear_camera", "")),
        "front_mp": megapixel(front or specs.get("front_camera", "")),
    }
    return {k: v for k, v in metrics.items() if v is not None}


def main() -> int:
    payload = json.loads(SRC.read_text(encoding="utf-8"))
    shutil.copy2(SRC, SRC.with_suffix(".json.bak"))

    kept, dropped, changed = [], [], 0
    for product in payload["products"]:
        brand = norm_brand(product.get("brand"))
        if brand not in WHITELIST:
            dropped.append(f"{product.get('brand')} {product.get('model')}")
            continue
        product["brand"] = brand

        raw = product.get("specs", {})
        cleaned = {k: clean_text(v) for k, v in raw.items()}
        metrics = rebuild_metrics(cleaned)
        if cleaned != raw or metrics != product.get("metrics"):
            changed += 1
        product["specs"] = cleaned
        # 参考分（cpu_score / dxo_camera）不是从参数页解析出来的，清洗时保留
        for ref_key in ("cpu_score", "dxo_camera", "image_score"):
            if ref_key in (product.get("metrics") or {}):
                metrics[ref_key] = product["metrics"][ref_key]
        product["metrics"] = metrics

        # 图片统一成 https（http 会被浏览器当混合内容拦掉）
        for field in ("image_url", "image_thumb"):
            value = product.get(field)
            if value and value.startswith("http://"):
                product[field] = "https://" + value[len("http://"):]

        kept.append(product)

    payload["products"] = kept
    payload["count"] = len(kept)
    payload["brand_counts"] = {}
    for p in kept:
        payload["brand_counts"][p["brand"]] = payload["brand_counts"].get(p["brand"], 0) + 1

    SRC.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"保留 {len(kept)} 款，丢除非白名单品牌 {len(dropped)} 款，参数重算 {changed} 款")
    if dropped[:5]:
        print("  丢弃示例：", "、".join(dropped[:5]))
    print("  品牌分布：", "  ".join(f"{k} {v}" for k, v in sorted(
        payload["brand_counts"].items(), key=lambda x: -x[1])))
    with_img = sum(1 for p in kept if p.get("image_url"))
    print(f"  有图片 {with_img}/{len(kept)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
