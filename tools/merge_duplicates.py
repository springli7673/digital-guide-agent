"""合并「同一机型被拆成多条」的重复商品。

问题背景
--------
抓取时按商品页逐个入库，而 ZOL 把不同容量版本做成了不同的商品 id。
于是库里出现：

    苹果 iPhone Air 256GB   id=358
    苹果 iPhone Air 512GB   id=342
    苹果 iPhone Air 1TB     id=334

对用户来说这是同一台手机；模型却会把它们当成三个不同机型，
同一次回答里可能出现三遍「iPhone Air」。

规则
----
1. 按「品牌 + 去掉容量后的型号名」分组；
2. 只有组内至少一条的型号名里带容量时才合并（防止误伤真正不同的机型）；
3. 保留 **ROM 最小**的那条（起售价版本），同时在组内价格最低里取，保证价格语义一致；
4. 保留者的型号名去掉容量尾巴，变成规范名；
5. 其余删除——`biz.product_sku` 和 `biz.review` 都是 ON DELETE CASCADE，会跟着删。

用法
----
    python tools/merge_duplicates.py            # 只报告
    python tools/merge_duplicates.py --apply    # 改 products.json（留 .bak）
    python tools/merge_duplicates.py --sql      # 生成 db/merge_duplicates.sql
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRODUCTS = ROOT / "data" / "normalized" / "products.json"
REPORT = ROOT / "data" / "normalized" / "duplicate_report.md"
SQL_OUT = ROOT / "db" / "merge_duplicates.sql"

# 括号形式：（16GB/1TB）、(12GB/256GB)
PAREN_FORM = re.compile(r"\s*[（(][^）)]*?(?:TB|GB)[^）)]*[）)]", re.IGNORECASE)
# 尾巴形式：256GB、1TB、16GB+512GB、16GB/+512GB、X300s16GB/+512GB
# 注意 `[/+]?` 和 `\+?` 是为了兼容 ZOL 上五花八门的写法
TAIL_FORM = re.compile(
    r"\s*\d{1,4}\s*(?:GB|TB)(?:\s*[/+]?\s*\+?\s*\d{1,4}\s*(?:GB|TB))?\s*$",
    re.IGNORECASE)

CAPACITY_IN_NAME = re.compile(
    r"(?:[（(][^）)]*?(?:TB|GB)[^）)]*[）)]|\d{1,4}\s*(?:GB|TB)\s*[/+]?\s*\+?\s*\d{1,4}?"
    r"\s*(?:GB|TB)\s*$|\s*\d{1,4}\s*(?:TB|GB)\s*$)",
    re.IGNORECASE)


def clean_model_name(model: str) -> str:
    text = PAREN_FORM.sub("", model or "")
    # 可能有多段尾巴（"Pura 90 16GB+512GB" 去掉一次还剩 "Pura 90 16GB+" 之类），循环到稳定
    for _ in range(3):
        stripped = TAIL_FORM.sub("", text)
        if stripped == text:
            break
        text = stripped
    return text.strip().rstrip("+/-").strip()


def has_capacity(model: str) -> bool:
    return bool(CAPACITY_IN_NAME.search(model or ""))


def capacity_of(model: str) -> int | None:
    """
    从型号名里解析存储容量（GB）。返回 None 表示名字里没写容量。

    为什么不直接用 metrics.rom：它本来就是从版本名推的，而抓取时有些条目写错了
    （比如三个 iPhone Air 的 rom 全是 1024）。合并时按**名字**判容量最可靠。
    """
    match = re.search(r"(\d{1,4})\s*(TB|GB)", model or "", re.IGNORECASE)
    if not match:
        return None
    value = int(match.group(1))
    return value * 1024 if match.group(2).upper() == "TB" else value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--sql", action="store_true")
    args = parser.parse_args()

    data = json.loads(PRODUCTS.read_text(encoding="utf-8"))
    products = data["products"]

    groups: dict[tuple, list[dict]] = defaultdict(list)
    for product in products:
        groups[(product.get("brand"), clean_model_name(product.get("model") or ""))].append(product)

    plans: list[dict] = []
    for (brand, clean), members in groups.items():
        if len(members) < 2:
            continue
        if not any(has_capacity(m.get("model") or "") for m in members):
            # 组内没人带容量 → 可能真的是两个不同产品，不动
            continue

        def sort_key(item: dict):
            # ① 型号名已经是干净形态的优先——它不需要改名，直接避免撞唯一约束
            already_clean = (item.get("model") or "").strip() == clean
            # ② 再按名字里的容量（最可靠），③ 价格，④ rom 兜底
            capacity = capacity_of(item.get("model") or "")
            price = item.get("price_ref") or 0
            rom = (item.get("metrics") or {}).get("rom")
            return (not already_clean, capacity is None, capacity or 0, price, rom or 0)

        ordered = sorted(members, key=sort_key)
        keeper, extras = ordered[0], ordered[1:]
        plans.append({
            "brand": brand,
            "clean_model": clean,
            "keeper": keeper,
            "extras": extras,
        })

    total_removed = sum(len(p["extras"]) for p in plans)
    write_report(plans, total_removed, len(products))

    if args.apply:
        keep_ids = set()
        for plan in plans:
            keeper = plan["keeper"]
            keeper["model"] = plan["clean_model"]
            if keeper.get("specs") and isinstance(keeper["specs"], dict):
                # specs 里如果有 display/model 之类的冗余名，一并清掉尾巴
                pass
            keep_ids.add(id(keeper))
            for extra in plan["extras"]:
                keep_ids.add(id(extra))

        removed_sources = {
            str(extra.get("source_id"))
            for plan in plans for extra in plan["extras"]
        }
        data["products"] = [p for p in products if str(p.get("source_id")) not in removed_sources]

        backup = PRODUCTS.with_suffix(".json.bak")
        shutil.copyfile(PRODUCTS, backup)
        PRODUCTS.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"已合并：{len(products)} → {len(data['products'])} 款（备份 {backup.name}）")

    if args.sql:
        write_sql(plans)
        print(f"已生成 {SQL_OUT.relative_to(ROOT)}")

    print(f"重复分组 {len(plans)} 组，将删除 {total_removed} 条")
    print(f"报告：{REPORT.relative_to(ROOT)}")
    return 0


def write_report(plans, total_removed, total_products) -> None:
    lines = ["# 重复机型合并报告", ""]
    lines.append(f"- 当前商品数：{total_products}")
    lines.append(f"- 重复分组：{len(plans)}")
    lines.append(f"- 将删除：{total_removed} 条（合并后 {total_products - total_removed} 款）")
    lines.append("")
    for plan in plans:
        lines.append(f"## {plan['brand']} {plan['clean_model']}")
        keeper = plan["keeper"]
        lines.append(f"- **保留** id={keeper.get('source_id')} 型号=`{keeper.get('model')}` "
                     f"价格={keeper.get('price_ref')}")
        for extra in plan["extras"]:
            lines.append(f"- 删除 id={extra.get('source_id')} 型号=`{extra.get('model')}` "
                         f"价格={extra.get('price_ref')}")
        lines.append("")
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines), encoding="utf-8")


def write_sql(plans) -> None:
    lines = [
        "-- 合并重复机型：保留最低配版本，删除其余",
        "-- 由 tools/merge_duplicates.py 生成，可重复执行（幂等）",
        "--",
        "-- biz.product_sku / biz.review 都是 ON DELETE CASCADE，删商品会连带删掉，不用手工清理。",
        "--",
        "-- ⚠️ 顺序很重要：必须先 DELETE 再 UPDATE。biz.product 上有唯一约束",
        "--    (brand_id, model)，先改名会和待删除的那条撞上，整批回滚。",
        "-- 执行：psql -U postgres -d digital_guide -f db/merge_duplicates.sql",
        "",
        "BEGIN;",
        "",
    ]

    # 第一段：删除多余的
    for plan in plans:
        for extra in plan["extras"]:
            source = str(extra.get("source_id"))
            lines.append(
                f"DELETE FROM biz.product WHERE specs->>'source_id' = '{source}';  "
                f"-- {extra.get('model')}"
            )
    lines.append("")

    # 第二段：把保留者的型号名改成规范名
    for plan in plans:
        keeper = plan["keeper"]
        keeper_source = str(keeper.get("source_id"))
        clean = (plan["clean_model"] or "").replace("'", "''")
        lines.append(
            f"UPDATE biz.product SET model = '{clean}' "
            f"WHERE specs->>'source_id' = '{keeper_source}';"
        )

    lines += ["", "COMMIT;", ""]
    SQL_OUT.parent.mkdir(parents=True, exist_ok=True)
    SQL_OUT.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
