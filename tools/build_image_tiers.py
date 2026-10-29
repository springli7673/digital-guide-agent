# -*- coding: utf-8 -*-
"""把用户手工划分的影像梯队落成数据文件

- 输入：下面 5 段原文（照用户原样贴）
- 输出：data/reference/image_tiers.json  {"tiers": {...}, "scores": {key: 分}}
- 规则：梯队 1..5 → 100 / 85 / 70 / 55 / 40 分
        明确列出的条目优先；"小米/OPPO/vivo 的 ultra 机型" 作为兜底规则，
        只对没被明确列出的 ultra 生效
"""

import json
import re
from pathlib import Path

ROOT = Path(r"D:\Temp\dsh_work\digital-guide-agent")
PRODUCTS = ROOT / "data" / "normalized" / "products.json"
OUT = ROOT / "data" / "reference" / "image_tiers.json"

TIER_TEXT = {
    1: """华为 mate90rs 非凡大师、华为 mate90promax 典藏版、小米18promax、oppofindx10promax、
vivox500promax、荣耀 magic9promax、苹果 iphone18promax""",
    2: """华为 mate90promax、小米 18promax、小米 17ultra、小米 15ultra、oppofindx9ultra、vivox500pro、
vivox300ultra、iqoo15ultra、苹果 iphone18pro、小米 17promax、小米 17pro、oppofindx10、oppofindx9spro""",
    3: """华为 mate90pro、华为 pura90promax、华为 pura90pro、华为 mate80promax 风驰版、小米 18fold、
小米 18pro、小米 mixfold4、vivox500、vivoxfold6、荣耀 magicv6、苹果 iphone17promax、苹果 iphone17pro、
苹果 iphone16promax、苹果 iphone16pro、华为 matext2 非凡大师、华为 puraxmax、一加 15t、vivox300s 16gb/+512gb""",
    4: """华为 mate90、华为 puraxview、华为 purax、华为 pura90、华为 nova16ultra、华为 nova16pro、
小米 mixflip2、小米 17max、小米 17、小米 15spro、小米 17tpro、小米 civi5pro、小米 17t、红米 k100promax、
红米 k90promax、红米 k100pro、oppofindn6、oppofindx10e、opporeno16pro、opporeno16、一加 16、一加 15、
一加 ace6 至尊版、vivo x300s、vivos60、iqoo16、iqoo15、iqooneo11 至尊版、iqooneo11、荣耀 magic9、
荣耀 magic9 超能版、苹果 iphone17、苹果 iphone16、苹果 iphone15promax、苹果 iphone15pro、
华为 pura90 16gb+512gb、华为 pura90 12gb+512gb、华为 nova16、vivos50t、vivos60 元气版""",
    5: """华为 novaflip、华为 nova16z、华为 nova16se、华为畅享 90promax 512gb、华为畅享 90promax 256gb、
华为畅享 90plus 256gb、华为畅享 90promax 128gb、华为畅享 90 256gb、华为畅享 90plus 128gb、
华为畅享 90 128gb、红米 k100、红米 k90、红米 k90max、红米 k90 至尊版、红米 turbo5max、红米 r70m5g、
红米 turbo5、红米 m100、红米 note17pro、红米 note17、红米 note14、oppooppo、oppok15pro+、oppok15pro、
opporeno15c、oppoa6spro、oppoa7promax、oppoa7pro、oppok15、oppoa6max、一加 ace6t、一加 ace6、
一加 turbo6、一加 ace5 竞速版、一加 turbo6v、一加 turbo6xpro、一加 turbo6x、vivoy600pro、vivoy600turbo、
vivoy600、vivoy600i、vivoy6、vivoy60、iqooz11turbo、iqooz11s、iqooz11、iqooz11x、iqooz11i、
荣耀 robotphone、荣耀 win2、荣耀 winrt2、荣耀 winturbo2、荣耀 winturbo、荣耀 600pro、荣耀 600 超级版、
荣耀 600 元气版、荣耀 play11plus、荣耀 x80promax、荣耀畅玩 70c、苹果 iphoneduo、苹果 iphoneair1tb、
苹果 iphoneair512gb、苹果 iphone16plus、苹果 iphone15plus、苹果 iphone15、苹果 iphoneair256gb、
苹果 iphone16e、苹果 iphone17e""",
}

TIER_SCORE = {1: 100, 2: 85, 3: 70, 4: 55, 5: 40}

# 用户列表里漏掉的两款，按同级机型补到第 4 梯队（iPhone17/16、iQOO15 都在四梯队）
FALLBACK = {
    "苹果iphone18": 4,
    "iqoo15t": 4,
}


def norm(text: str) -> str:
    return re.sub(r"\s+", "", text).lower()


def main() -> int:
    explicit: dict[str, int] = {}
    conflicts: list[str] = []

    for tier, block in TIER_TEXT.items():
        for raw in re.split(r"[、\n]", block):
            key = norm(raw)
            if not key:
                continue
            if key in explicit and explicit[key] != tier:
                conflicts.append(f"{key}: 梯队{explicit[key]} vs 梯队{tier}（保留先出现的）")
                continue
            explicit[key] = tier

    for key, tier in FALLBACK.items():
        explicit.setdefault(key, tier)

    products = json.loads(PRODUCTS.read_text(encoding="utf-8"))["products"]
    db_keys = {norm(p["brand"] + p["model"]): p for p in products}

    # 兜底规则：小米/OPPO/vivo 的 ultra 机型（没被明确列出的）算第一梯队
    for key in db_keys:
        if key in explicit:
            continue
        if "ultra" in key and any(key.startswith(b) for b in ("小米", "oppo", "vivo")):
            explicit[key] = 1
            print(f"  [兜底] {key} -> 梯队1（ultra 规则）")

    matched = {k: v for k, v in explicit.items() if k in db_keys}
    unmatched = sorted(k for k in explicit if k not in db_keys)
    missing = sorted(k for k in db_keys if k not in explicit)

    scores = {k: TIER_SCORE[t] for k, t in matched.items()}
    payload = {
        "tiers": {str(t): [k for k, v in matched.items() if v == t] for t in TIER_SCORE},
        "scores": scores,
        "tier_score_map": {str(k): v for k, v in TIER_SCORE.items()},
        "stats": {"matched": len(matched), "db_total": len(db_keys)},
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\n明确命中 {len(matched)} / 库内 {len(db_keys)} 款")
    if conflicts:
        print("\n重复出现（以先出现的为准）：")
        for c in conflicts:
            print("  " + c)
    if unmatched:
        print(f"\n梯队里写了但库里没有的（{len(unmatched)} 条，忽略）：")
        print("  " + "、".join(unmatched))
    if missing:
        print(f"\n库里没被分梯队的（{len(missing)} 条，会记 0 分）：")
        print("  " + "、".join(missing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
