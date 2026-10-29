"""把商品价格修正为「最低配版本」的报价。

问题背景
--------
原来抓的是"某个容量版本"的商品页，价格和 rom 都是那个版本的，但清洗时把容量从
型号名里剥掉了。于是卡片上出现「iPhone 18 Pro ¥20,499」——那是 2TB 版的价格。

ZOL 详情页底部有一张版本表，每行是「版本名 + 价格」：

    <tr class="model__item ...">
      <td class="cell-7"><a title="苹果iPhone 18 Pro（256GB）">…</a></td>
      <td class="cell-8"><span data-type="curRomName">256GB/</span></td>
      <td class="cell-2"><b class="fontRed">￥9999</b></td>
    </tr>

所以不需要重新抓：从缓存好的 data/raw/<id>.detail.html 里把整张表解析出来，
取 **ROM 最小的那个版本**作为该机型的代表版本，价格、ram、rom 都换成它的。

用法
----
    python tools/fix_variants.py            # 只报告，不改文件
    python tools/fix_variants.py --apply    # 改 data/normalized/products.json（留 .bak）
    python tools/fix_variants.py --sql      # 额外生成 db/fix_prices.sql

产出
----
- data/normalized/products.json（--apply 时覆盖，原文件留 .bak）
- db/fix_prices.sql（--sql 时生成，可直接在 IDE 里执行）
- data/normalized/variant_report.md（每次都会写，列出所有改动与可疑项）
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
PRODUCTS = ROOT / "data" / "normalized" / "products.json"
REPORT = ROOT / "data" / "normalized" / "variant_report.md"
SQL_OUT = ROOT / "db" / "fix_prices.sql"

# 一行版本：<tr class="model__item ...> 里取「标题 + 价格」
ROW_SPLIT = re.compile(r'<tr class="model__item\b')
TITLE = re.compile(r'title="([^"]+)"')
PRICE = re.compile(r"￥\s*([\d,]+)")
CAPACITY = re.compile(r"(\d{1,4})\s*(TB|GB)", re.IGNORECASE)


def parse_capacity(text: str) -> tuple[int | None, int | None]:
    """从版本名里解析 (ram_gb, rom_gb)。>=128GB 视为存储，TB 一律是存储。"""
    ram = rom = None
    for number, unit in CAPACITY.findall(text or ""):
        value = int(number)
        if unit.upper() == "TB":
            rom = value * 1024
        elif value >= 128:
            rom = value
        else:
            ram = value
    return ram, rom


def variants_of(source_id: str) -> list[dict]:
    """解析一个商品页里的全部版本报价，按 rom 升序（rom 缺失的排后面）"""
    path = RAW_DIR / f"{source_id}.detail.html"
    if not path.exists():
        return []
    html = path.read_text(encoding="utf-8", errors="ignore")

    rows = ROW_SPLIT.split(html)[1:]
    found: dict[tuple, dict] = {}
    for row in rows:
        title = TITLE.search(row)
        price = PRICE.search(row)
        if not title or not price:
            continue
        name = title.group(1)
        amount = int(price.group(1).replace(",", ""))
        ram, rom = parse_capacity(name)
        key = (ram, rom, amount)
        # 同一版本会因多个商家重复出现，去重后保留一次
        found.setdefault(key, {"name": name, "price": amount, "ram": ram, "rom": rom})

    items = list(found.values())
    items.sort(key=lambda v: (v["rom"] is None, v["rom"] or 0, v["price"]))
    return items


def clean_model_name(model: str) -> str:
    """去掉型号名里残余的容量写法，用于发现"同一机型被拆成多条" """
    text = re.sub(r"[（(]\s*.*?(?:TB|GB).*?[）)]", "", model or "", flags=re.IGNORECASE)
    text = re.sub(r"\s*\d+\s*(?:TB|GB)\s*$", "", text, flags=re.IGNORECASE)
    return text.strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="改写 products.json")
    parser.add_argument("--sql", action="store_true", help="生成 db/fix_prices.sql")
    args = parser.parse_args()

    data = json.loads(PRODUCTS.read_text(encoding="utf-8"))
    products = data["products"]

    changes: list[dict] = []
    no_variants: list[dict] = []
    untouched = 0

    for product in products:
        source_id = str(product.get("source_id") or "")
        variants = variants_of(source_id)
        if not variants:
            no_variants.append(product)
            continue

        base = variants[0]
        old_price = product.get("price_ref")
        metrics = product.setdefault("specs", {}).setdefault("metrics", {})

        new_price = base["price"]
        if old_price == new_price:
            untouched += 1
            continue

        record = {
            "id": product.get("id"),
            # products.json 里没有数据库自增 id（入库才生成），所以 SQL 用 ZOL 的商品号定位：
            # specs->>'source_id' 是唯一稳定的业务键
            "source_id": source_id,
            "brand": product.get("brand"),
            "model": product.get("model"),
            "old_price": old_price,
            "new_price": new_price,
            "old_rom": metrics.get("rom"),
            "new_rom": base["rom"],
            "new_ram": base["ram"],
            "version": base["name"],
            "variant_count": len(variants),
        }
        changes.append(record)

        if args.apply:
            product["price_ref"] = new_price
            product["price_source"] = "zol_base_variant"
            # 标题也换成基础版本，避免"标题写 2TB、价格却是 256GB"的自相矛盾
            product["title"] = base["name"]
            if base["rom"] is not None:
                metrics["rom"] = base["rom"]
            if base["ram"] is not None:
                metrics["ram"] = base["ram"]

    # 同一机型被拆成多条的情况（型号名里带容量）
    by_key: dict[tuple, list[dict]] = {}
    for product in products:
        key = (product.get("brand"), clean_model_name(product.get("model") or ""))
        by_key.setdefault(key, []).append(product)
    duplicates = {k: v for k, v in by_key.items() if len(v) > 1}

    write_report(changes, no_variants, duplicates, untouched, len(products))

    if args.apply:
        backup = PRODUCTS.with_suffix(".json.bak")
        shutil.copyfile(PRODUCTS, backup)
        PRODUCTS.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"已改写 {PRODUCTS.name}（备份 {backup.name}）")

    if args.sql:
        write_sql(changes)
        print(f"已生成 {SQL_OUT.relative_to(ROOT)}（{len(changes)} 条 UPDATE）")

    print(f"共 {len(products)} 款：改动 {len(changes)}，无版本表 {len(no_variants)}，无需改 {untouched}")
    print(f"重复机型分组：{len(duplicates)}")
    print(f"报告：{REPORT.relative_to(ROOT)}")
    return 0


def write_report(changes, no_variants, duplicates, untouched, total) -> None:
    lines = ["# 价格修正报告（最低配版本）", ""]
    lines.append(f"- 商品总数：{total}")
    lines.append(f"- 价格被修正：{len(changes)}")
    lines.append(f"- 页面没有版本表：{len(no_variants)}")
    lines.append(f"- 无需修改：{untouched}")
    lines.append("")

    if changes:
        lines += ["## 修正明细", "", "| 机型 | 原价 | 新价 | 版本 | 版本数 |", "|---|---|---|---|---|"]
        for c in sorted(changes, key=lambda x: -(x["old_price"] or 0)):
            lines.append(f"| {c['brand']} {c['model']} | {c['old_price']} | {c['new_price']} "
                         f"| {c['version']} | {c['variant_count']} |")
        lines.append("")

    if no_variants:
        lines += ["## 页面没有版本表（保持原价）", "", "| 机型 | 原价 |", "|---|---|"]
        for p in no_variants:
            lines.append(f"| {p.get('brand')} {p.get('model')} | {p.get('price_ref')} |")
        lines.append("")

    if duplicates:
        lines += ["## 同一机型被拆成多条（需人工决定是否合并）", ""]
        for (brand, model), items in duplicates.items():
            lines.append(f"- **{brand} {model}**")
            for item in items:
                lines.append(f"  - id={item.get('id')} 型号名=`{item.get('model')}` 价格={item.get('price_ref')}")
        lines.append("")

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines), encoding="utf-8")


def write_sql(changes) -> None:
    lines = [
        "-- 价格修正：把 price_ref 换成「最低配版本」的报价",
        "-- 由 tools/fix_variants.py 生成，可重复执行（幂等）",
        "--",
        "-- 定位键用 specs->>'source_id'（ZOL 商品号），因为 products.json 里没有数据库自增 id。",
        "-- 执行：psql -U postgres -d digital_guide -f db/fix_prices.sql",
        "",
    ]
    for c in changes:
        source_id = c.get("source_id")
        if not source_id:
            continue
        title = (c["version"] or "").replace("'", "''")
        where = f"specs->>'source_id' = '{source_id}'"
        lines.append(
            f"UPDATE biz.product SET price_ref = {c['new_price']}, "
            f"title = '{title}', price_source = 'zol_base_variant' "
            f"WHERE {where};"
        )
        if c["new_rom"] is not None:
            lines.append(
                f"UPDATE biz.product SET specs = jsonb_set(specs, '{{metrics,rom}}', "
                f"to_jsonb({c['new_rom']}::int)) WHERE {where};"
            )
    SQL_OUT.parent.mkdir(parents=True, exist_ok=True)
    SQL_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
