"""把「参考分数」并进 products.json 的 metrics：处理器天梯分 + DXOMARK 影像分

用法：
    python tools/build_reference.py

输入：
    data/normalized/products.json        抓取清洗后的商品
    data/reference/cpu_tiers.json        处理器天梯（人工整理，0-450 相对分）
    data/reference/dxomark_camera.json   可选，DXOMARK 摄像头分（没有就跳过影像分）

输出：
    原地写回 products.json，新增 metrics.cpu_score / metrics.dxo_camera，
    并把匹配到的型号记在 specs.cpu_tier_name 便于核对。

设计说明：
- 这两个分都是"参考分"，参与打分但不参与筛选（筛选仍走价格/品牌）；
- DXO 未收录的机型：低端按 0 处理（用户定的规则），其余留空（不参与该维度）；
- 处理器匹配不到就留空，并在最后列出未命中的型号，方便补天梯表。
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRODUCTS = ROOT / "data" / "normalized" / "products.json"
CPU_TIERS = ROOT / "data" / "reference" / "cpu_tiers.json"
DXO = ROOT / "data" / "reference" / "dxomark_camera.json"
IMAGE_TIERS = ROOT / "data" / "reference" / "image_tiers.json"

# 低端机的判定：价格低于这个数，或者主摄像素低于 4800 万 → 影像分记 0
LOW_END_PRICE = 2500
LOW_END_REAR_MP = 4800

CPU_SUFFIXES = ("超能版", "满血版", "monster版", "风驰版", "vseries", "monster", "版")
VENDOR_PREFIXES = ("高通", "联发科", "海思", "苹果", "紫光展锐", "三星", "华为", "小米")


def norm_cpu(text: str) -> str:
    s = (text or "").lower()
    s = re.sub(r"[，,].*$", "", s)          # 去掉「，手机性能排行」
    s = s.replace("手机性能排行", "")
    s = re.sub(r"\s+", "", s)
    for prefix in VENDOR_PREFIXES:
        if s.startswith(prefix) and len(s) > len(prefix):
            s = s[len(prefix):]
    for suffix in CPU_SUFFIXES:
        if s.endswith(suffix) and len(s) > len(suffix):
            s = s[: -len(suffix)]
    return s


def norm_name(text: str) -> str:
    """型号归一：去括号、去空格/连字符，小写。"""
    s = (text or "").lower()
    s = re.sub(r"[（(].*?[）)]", "", s)
    s = re.sub(r"[\s\-_·]+", "", s)
    return s


def load_cpu_table() -> dict[str, int]:
    raw = json.loads(CPU_TIERS.read_text(encoding="utf-8"))["scores"]
    # key 也走一遍同样的归一，这样表里写「苹果A19 Pro」或「A19 Pro」都能命中
    return {norm_cpu(k): int(v) for k, v in raw.items()}


def match_cpu(text: str, table: dict[str, int]) -> tuple[str, int] | tuple[None, None]:
    key = norm_cpu(text)
    if not key:
        return None, None
    if key in table:
        return key, table[key]
    # 长 key 优先，避免「骁龙8elite」抢走「骁龙8elitegen5」
    for candidate in sorted(table, key=len, reverse=True):
        if candidate in key:
            return candidate, table[candidate]
    return None, None


def estimate_missing_cpu(products: list[dict]) -> list[tuple[str, str, int, str]]:
    """CPU 字段缺失的机型，按同价位已知机型的中位数估一个处理器分。

    比"统一给个默认值"靠谱：4 千档和 2 万档显然不是一个水平。
    完全没有价格的（比如概念机）退化成同品牌中位数。
    """
    import bisect

    known = sorted(
        (
            float(p["price_ref"]),
            float(p["metrics"]["cpu_score"]),
            p["brand"],
            norm_name(p["model"]),
        )
        for p in products
        if p["metrics"].get("cpu_score") is not None and p.get("price_ref")
    )

    brand_scores: dict[str, list[float]] = {}
    for item in products:
        score = item["metrics"].get("cpu_score")
        if score is not None:
            brand_scores.setdefault(item["brand"], []).append(float(score))

    results: list[tuple[str, str, int, str]] = []
    for item in products:
        if item["metrics"].get("cpu_score") is not None:
            continue

        price = item.get("price_ref")
        estimate: int | None = None
        basis = ""

        # 0) 同系列兄弟优先：iPhone 18 Pro Max ← iPhone 18 Pro
        target = norm_name(item["model"])
        if len(target) >= 5:
            siblings = [
                k for k in known
                if k[2] == item["brand"] and (k[3].startswith(target) or target.startswith(k[3]))
            ]
            if siblings:
                # 目标型号更短（iPhone 18 vs iPhone 18 Pro）= 基础款，按 0.85 折
                # 只有当目标型号是兄弟型号的前缀时才算基础款：
                # iphone18 是 iphone18pro 的前缀 → 打折；iphone18promax 不是 → 不打折
                is_base = all(k[3].startswith(target) and len(k[3]) > len(target) for k in siblings)
                base = siblings
                values = sorted(v for _, v, _, _ in base)
                estimate = int(round(values[len(values) // 2]))
                if is_base:
                    estimate = int(round(estimate * 0.85))
                basis = f"同系列参考 {item['brand']} {base[0][3]}（{int(base[0][1])}分{'×0.85 基础款' if is_base else ''}）"

        if estimate is None and price and known:
            # 优先用同品牌同价位：折叠屏/华为此类"价格高但芯片一般"的机型，
            # 用全品牌邻居会被安卓旗舰拉高（实测 Pura X 会从 165 被估成 285）
            same_brand = [k for k in known if k[2] == item["brand"]]
            pool = same_brand if len(same_brand) >= 3 else known
            pool_prices = [k[0] for k in pool]
            pos = bisect.bisect_left(pool_prices, float(price))
            window = pool[max(0, pos - 4): pos + 5]
            near = sorted(window, key=lambda kv: abs(kv[0] - float(price)))[:5]
            if near:
                values = sorted(v for _, v, _, _ in near)
                estimate = int(round(values[len(values) // 2]))
                sample = "、".join(f"{int(n[0])}元/{int(n[1])}分" for n in near[:3])
                scope = "同品牌同价位" if pool is same_brand else "同价位"
                basis = f"{scope}参考 {sample}"

        if estimate is None:
            values = sorted(brand_scores.get(item["brand"], []))
            if values:
                estimate = int(round(values[len(values) // 2]))
                basis = f"{item['brand']}品牌中位数"

        if estimate is None:
            continue

        item["metrics"]["cpu_score"] = estimate
        item["specs"]["cpu_source"] = "同价位估算"
        results.append((item["brand"], item["model"], estimate, basis))

    return results


def load_image_tiers() -> dict[str, float]:
    """手工划分的影像梯队分（100/85/70/55/40），全库覆盖。"""
    if not IMAGE_TIERS.exists():
        return {}
    data = json.loads(IMAGE_TIERS.read_text(encoding="utf-8"))
    return {k: float(v) for k, v in (data.get("scores") or {}).items()}


def load_dxo() -> dict[str, float]:
    if not DXO.exists():
        return {}
    data = json.loads(DXO.read_text(encoding="utf-8"))
    scores = data.get("scores") or data
    return {norm_name(k): float(v) for k, v in scores.items()}


def main() -> int:
    payload = json.loads(PRODUCTS.read_text(encoding="utf-8"))
    products = payload["products"]
    cpu_table = load_cpu_table()
    dxo = load_dxo()
    tiers = load_image_tiers()

    cpu_hit = cpu_miss = 0
    unmatched_cpu: dict[str, int] = {}
    dxo_hit = dxo_zero = dxo_blank = 0

    for product in products:
        specs = product.setdefault("specs", {})
        metrics = product.setdefault("metrics", {})

        # ---- 处理器 ----
        cpu_text = specs.get("cpu") or ""
        tier_key, tier_score = match_cpu(cpu_text, cpu_table)
        if tier_score is not None:
            metrics["cpu_score"] = tier_score
            specs["cpu_tier_name"] = tier_key
            cpu_hit += 1
        else:
            metrics.pop("cpu_score", None)
            cpu_miss += 1
            if cpu_text:
                unmatched_cpu[cpu_text] = unmatched_cpu.get(cpu_text, 0) + 1

        # ---- 影像梯队（人工口径，全库覆盖）----
        tier_score = tiers.get(norm_name(product.get("brand") or "") + norm_name(product.get("model") or ""))
        if tier_score is None:
            metrics.pop("image_score", None)
        else:
            metrics["image_score"] = tier_score

        # ---- 影像 ----
        model_key = norm_name(product.get("model") or "")
        brand_key = norm_name(product.get("brand") or "")
        score = dxo.get(brand_key + model_key) or dxo.get(model_key)
        if score is not None:
            metrics["dxo_camera"] = score
            dxo_hit += 1
            continue

        price = product.get("price_ref") or 0
        rear = metrics.get("rear_mp") or 0
        if (price and price < LOW_END_PRICE) or (rear and rear < LOW_END_REAR_MP):
            metrics["dxo_camera"] = 0  # 低端机不送测，按 0 计
            dxo_zero += 1
        else:
            metrics.pop("dxo_camera", None)  # 中高端但 DXO 没测：留空不参与该维度
            dxo_blank += 1

    estimated = estimate_missing_cpu(products)

    payload["reference"] = {
        "cpu_tiers": str(CPU_TIERS.relative_to(ROOT)),
        "dxomark": str(DXO.relative_to(ROOT)) if dxo else None,
        "cpu_matched": cpu_hit,
        "cpu_unmatched": cpu_miss,
        "cpu_estimated": len(estimated),
        "dxo_matched": dxo_hit,
        "dxo_zeroed_low_end": dxo_zero,
        "dxo_blank": dxo_blank,
    }
    PRODUCTS.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"处理器：命中 {cpu_hit} / 未命中 {cpu_miss} / 按价位估算 {len(estimated)}")
    for brand, model, score, basis in estimated:
        print(f"  [估算] {brand} {model} -> {score} 分（{basis}）")
    if unmatched_cpu:
        print("  未命中的 CPU（补天梯表用）：")
        for name, count in sorted(unmatched_cpu.items(), key=lambda kv: -kv[1])[:15]:
            print(f"    {count:>2}  {name}")
    print(f"影像：DXO 命中 {dxo_hit}，低端记 0 {dxo_zero}，中高端留空 {dxo_blank}")
    if not dxo:
        print("  (没有 data/reference/dxomark_camera.json，本次只处理处理器)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
