"""ZOL 手机抓取 -> 归一化 JSON（品牌白名单 + 分页 + 图片 + 断点续抓）

用法（在项目根目录）：
    python tools/scrape_zol.py --target 500

特性：
- 品牌白名单：华为 / 小米 / 红米 / OPPO / 一加 / vivo / iQOO / 荣耀 / 苹果，其余一律丢弃；
- 候选池 = 各品牌列表页 + 4 个价位段列表页，轮询交错取，保证低/中/高价都有；
- 详情页 / 参数页按产品 ID 缓存到 data/raw/，中断后重跑不会重复请求（断点续抓）；
- 顺带抓商品主图，输出 image_url(800x600) 与 image_thumb(320x240)；
- 价格是"参考报价"，不是实时成交价；"价格面议"的概念机价格为 null。

注意：ZOL 有 301 到 https，必须能访问 https。
"""

import argparse
import hashlib
import json
import re
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

import httpx

UA = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/120.0 Safari/537.36",
    "Accept-Language": "zh-CN,zh;q=0.9",
}

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
BASE = "https://detail.zol.com.cn"
LIST_URL = BASE + "/cell_phone_index/subcate57_{sid}_list_{page}.html"      # 品牌列表
PRICE_URL = BASE + "/cell_phone_index/subcate57_list_{band}_{page}.html"    # 价位段列表
GENERAL_URL = BASE + "/cell_phone_index/subcate57_list_{page}.html"         # 全站热门列表

# 品牌 -> ZOL 品牌 ID（只保留这九个）
WHITELIST = {
    "华为": 613,
    "小米": 34645,
    "红米": 55731,
    "OPPO": 1673,
    "一加": 35579,
    "vivo": 1795,
    "iQOO": 55075,
    "荣耀": 50840,
    "苹果": 544,
}
PRICE_BANDS = [0, 2000, 4600, 7600]  # <=1999 / 2000-4599 / 4600-7599 / >=7600

ID_RE = re.compile(r"/cell_phone/index(\d+)\.shtml")
# 商品图在 zol-img CDN 上，路径形如 /product/{相册ID}_{宽}x{高}/{分片}/{文件名}
IMG_RE = re.compile(
    r"(?:https?:)?//(\w+)\.zol-img\.com\.cn/product/(\d+)(?:_\d+x\d+)?/(\d+)/([\w\-]+\.(?:jpg|jpeg|png))",
    re.I,
)

# 标题里的品牌前缀 -> 统一品牌名。ZOL 同一品牌有中英文两种写法，
# 不加这张表的话 Redmi / OnePlus / HUAWEI 会被当成"非白名单品牌"丢掉（红米就是这么丢光的）
BRAND_ALIASES = {
    "huawei": "华为", "华为": "华为",
    "xiaomi": "小米", "小米": "小米",
    "redmi": "红米", "红米": "红米",
    "oppo": "OPPO",
    "oneplus": "一加", "一加": "一加",
    "vivo": "vivo",
    "iqoo": "iQOO",
    "honor": "荣耀", "荣耀": "荣耀",
    "apple": "苹果", "iphone": "苹果", "苹果": "苹果",
}
BRAND_PREFIXES = sorted(BRAND_ALIASES, key=len, reverse=True)

SPEC_ALIASES = {
    "cpu": ["CPU型号"],
    "ram": ["RAM容量"],
    "rom": ["ROM容量"],
    "screen_inch": ["屏幕尺寸"],
    "resolution": ["分辨率"],
    "refresh_hz": ["屏幕刷新率"],
    "battery_mah": ["电池容量"],
    "charge_w": ["有线充电", "充电功率", "快充功率"],
    "weight_g": ["重量"],
    "os": ["操作系统"],
    "launch": ["上市日期"],
    "nfc": ["NFC"],
    "waterproof": ["防水防尘", "三防", "防护等级"],
    "rear_camera": ["像素", "后置摄像头"],
    "front_camera": ["前置摄像头"],
}
NUMERIC = {"ram", "rom", "screen_inch", "refresh_hz", "battery_mah", "charge_w", "weight_g"}


class Limiter:
    """全局限速：多线程也保证整体请求间隔不低于 delay。"""

    def __init__(self, delay: float) -> None:
        self.delay = delay
        self._lock = threading.Lock()
        self._next = 0.0

    def wait(self) -> None:
        if self.delay <= 0:
            return
        with self._lock:
            now = time.monotonic()
            if now < self._next:
                time.sleep(self._next - now)
                now = self._next
            self._next = now + self.delay


def split_brand(title: str) -> tuple[str, str]:
    """ZOL 标题常把品牌和型号连写，先去掉括号再按别名前缀匹配。

    例子：华为Mate 90 Pro / Redmi K100 / OnePlus（一加）Ace 7 / iPhone Duo
    """
    clean = re.sub(r"[（(][^）)]*[）)]", "", title).strip()
    low = clean.lower()
    for alias in BRAND_PREFIXES:
        if low.startswith(alias):
            rest = clean[len(alias):].strip(" -_")
            return BRAND_ALIASES[alias], rest or clean
    parts = clean.split(" ", 1)
    if len(parts) == 2:
        brand = BRAND_ALIASES.get(parts[0].lower())
        if brand:
            return brand, parts[1]
    return "", clean


def strip_storage(title: str) -> tuple[str, str | None]:
    """"vivo Y600 Pro（8GB/256GB）" -> ("vivo Y600 Pro", "8GB/256GB")"""
    m = re.search(r"[（(]([^（）()]*?(?:GB|TB)[^（）()]*)[）)]\s*$", title)
    storage = m.group(1).strip() if m else None
    model = re.sub(r"[（(][^（）()]*[）)]\s*$", "", title).strip()
    return model, storage


def to_number(text: str | None) -> float | None:
    if not text:
        return None
    m = re.search(r"(\d+(?:\.\d+)?)", text.replace(",", ""))
    return float(m.group(1)) if m else None



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


def parse_pairs(html: str) -> dict:
    """参数页是 <tr><td>键</td><td>值</td></tr>；JS 渲染的新模板解析不到会返回空。"""
    pairs: dict[str, str] = {}
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S):
        cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.S)
        vals = [
            re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", c).replace("&nbsp;", " ")).strip()
            for c in cells
        ]
        vals = [v for v in vals if v]
        if len(vals) == 2:
            pairs.setdefault(vals[0], vals[1])
    return pairs


def pick(pairs: dict, keys: list[str]) -> str | None:
    for k in keys:
        if k in pairs:
            return pairs[k]
    for k, v in pairs.items():
        if any(k.startswith(x) or x in k for x in keys):
            return v
    return None


def parse_detail(html: str) -> dict:
    info = {}
    h1 = re.search(r"<h1[^>]*>(.*?)</h1>", html, re.S)
    if h1:
        info["title"] = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", h1.group(1))).strip()
    m = re.search(r"参考报价[^0-9]{0,40}?(\d{3,6})", re.sub(r"<[^>]+>", " ", html))
    if m:
        info["price_ref"] = int(m.group(1))
    return info


def parse_images(html: str) -> tuple[str | None, str | None]:
    """取详情页第一张商品图，拼出 800x600 和 320x240 两个尺寸。"""
    m = IMG_RE.search(html)
    if not m:
        return None, None
    host, album, shard, name = m.group(1), m.group(2), m.group(3), m.group(4)
    prefix = f"https://{host}.zol-img.com.cn/product/{album}"
    return f"{prefix}_800x600/{shard}/{name}", f"{prefix}_320x240/{shard}/{name}"


class Scraper:
    def __init__(self, delay: float) -> None:
        self.client = httpx.Client(headers=UA, timeout=25, follow_redirects=True)
        self.limiter = Limiter(delay)
        self.fail_count = 0

    def close(self) -> None:
        self.client.close()

    def fetch(self, url: str, cache_name: str | None = None, retries: int = 2) -> str | None:
        if cache_name:
            path = RAW_DIR / cache_name
            if path.exists() and path.stat().st_size > 2000:
                return path.read_text(encoding="utf-8", errors="ignore")
        for attempt in range(retries + 1):
            self.limiter.wait()
            try:
                r = self.client.get(url)
                if r.status_code == 200 and len(r.text) > 2000:
                    if cache_name:
                        RAW_DIR.mkdir(parents=True, exist_ok=True)
                        (RAW_DIR / cache_name).write_text(r.text, encoding="utf-8")
                    return r.text
                if r.status_code in (403, 429):
                    time.sleep(3 + attempt * 3)  # 被限流就退让
            except Exception as exc:  # noqa: BLE001
                print(f"  ! {url} -> {exc}")
                time.sleep(1 + attempt)
        self.fail_count += 1
        return None

    # ---------------------------------------------------------------- 自检

    def probe(self) -> None:
        """翻页是否生效：同一来源不同页应该给出不同的 ID 集合（md5 不同）。"""
        tests = [
            ("品牌-华为 p1", LIST_URL.format(sid=613, page=1)),
            ("品牌-华为 p2", LIST_URL.format(sid=613, page=2)),
            ("品牌-华为 p3", LIST_URL.format(sid=613, page=3)),
            ("品牌-华为 p1(规范)", LIST_URL.format(sid=613, page=1).replace("_list_1.html", "_list_1_0_1_1_0_1.html")),
            ("品牌-华为 p2(规范)", LIST_URL.format(sid=613, page=2).replace("_list_2.html", "_list_2_0_1_1_0_1.html")),
            ("热门 p1", GENERAL_URL.format(page=1)),
            ("热门 p2", GENERAL_URL.format(page=2)),
            ("价位<=1999 p1", PRICE_URL.format(band=0, page=1)),
            ("价位<=1999 p2", PRICE_URL.format(band=0, page=2)),
        ]
        for name, url in tests:
            html = self.fetch(url)
            ids = list(dict.fromkeys(ID_RE.findall(html))) if html else []
            digest = hashlib.md5(",".join(sorted(ids)).encode()).hexdigest()[:8] if ids else "-"
            print(f"  {name:<16} {url.split('/')[-1]:<42} {len(ids):>3} 个  md5={digest}  首ID={ids[0] if ids else '-'}")
    # ---------------------------------------------------------------- 列表页

    def collect_candidates(self, brand_pages: int, price_pages: int) -> list[str]:
        buckets: list[tuple[str, list[str]]] = []

        # 1) 全站热门列表：最稳的一路（和以前能跑通的那三个 URL 一样）
        for page in range(1, price_pages + 1):
            html = self.fetch(GENERAL_URL.format(page=page), f"list_hot_{page}.html")
            ids = list(dict.fromkeys(ID_RE.findall(html))) if html else []
            buckets.append((f"热门-p{page}", ids))
            print(f"  列表 热门 第 {page} 页: {len(ids)} 个")

        # 2) 各品牌列表：品牌覆盖的主力
        for brand, sid in WHITELIST.items():
            for page in range(1, brand_pages + 1):
                url = LIST_URL.format(sid=sid, page=page)
                html = self.fetch(url)
                ids = list(dict.fromkeys(ID_RE.findall(html))) if html else []
                buckets.append((f"{brand}-p{page}", ids))
                print(f"  列表 {brand} 第 {page} 页: {len(ids)} 个")

        # 3) 价位段列表：补低端/中端，防止全挤在旗舰
        for band in PRICE_BANDS:
            for page in range(1, price_pages + 1):
                url = PRICE_URL.format(band=band, page=page)
                html = self.fetch(url)
                ids = list(dict.fromkeys(ID_RE.findall(html))) if html else []
                buckets.append((f"价位{band}-p{page}", ids))
                print(f"  列表 价位>={band} 第 {page} 页: {len(ids)} 个")

        # 轮询交错：保证低端、中端、高端、各品牌都能被均匀采样
        ordered: list[str] = []
        seen: set[str] = set()
        depth = max((len(b) for _, b in buckets), default=0)
        for i in range(depth):
            for _, bucket in buckets:
                if i < len(bucket) and bucket[i] not in seen:
                    seen.add(bucket[i])
                    ordered.append(bucket[i])
        return ordered

    # ---------------------------------------------------------------- 详情页

    def scrape_one(self, pid: str) -> dict | None:
        detail_html = self.fetch(f"{BASE}/cell_phone/index{pid}.shtml", f"{pid}.detail.html")
        if not detail_html:
            return None
        m = re.search(r'href="(/\d+/\d+/param\.shtml)"', detail_html)
        if not m:
            return None
        param_html = self.fetch(BASE + m.group(1), f"{pid}.param.html")
        if not param_html:
            return None
        return normalize(pid, detail_html, param_html)


def normalize(pid: str, detail_html: str, param_html: str) -> dict:
    detail = parse_detail(detail_html)
    pairs = parse_pairs(param_html)
    title = detail.get("title", "")
    model_full, storage = strip_storage(title)
    brand, model = split_brand(model_full)

    specs: dict[str, str] = {}
    metrics: dict[str, float] = {}
    for key, aliases in SPEC_ALIASES.items():
        value = pick(pairs, aliases)
        if value is None:
            continue
        specs[key] = value
        if key in NUMERIC:
            number = to_number(value)
            if number is not None:
                metrics[key] = number
    if "rear_camera" in specs:
        metrics["rear_mp"] = megapixel(specs["rear_camera"])
    if "front_camera" in specs:
        metrics["front_mp"] = megapixel(specs["front_camera"])

    image_url, image_thumb = parse_images(detail_html)

    return {
        "source": "zol",
        "source_id": pid,
        "url": f"{BASE}/cell_phone/index{pid}.shtml",
        "category": "phone",
        "brand": brand,
        "model": model or title,
        "title": title,
        "storage": storage,
        "launch_date": specs.get("launch"),
        "price_ref": detail.get("price_ref") or to_number(pairs.get("电商报价")),
        "price_source": "京东/天猫(参考)",
        "image_url": image_url,
        "image_thumb": image_thumb,
        "specs": specs,
        "metrics": {k: v for k, v in metrics.items() if v is not None},
        "raw_param_count": len(pairs),
        "need_manual": len(pairs) < 15,
        "scraped_at": datetime.now().isoformat(timespec="seconds"),
    }


def merge_same_model(products: list[dict]) -> list[dict]:
    """同型号合并：保留最低价作为参考价，各存储版本收进 variants。"""
    dedup: dict[str, dict] = {}
    for p in products:
        key = f"{p['brand']}|{p['model']}"
        price = p.get("price_ref")
        if key not in dedup:
            p["variants"] = [{"storage": p.get("storage"), "price_ref": price}]
            dedup[key] = p
            continue
        item = dedup[key]
        if all(v.get("storage") != p.get("storage") for v in item["variants"]):
            item["variants"].append({"storage": p.get("storage"), "price_ref": price})
        if price and (item.get("price_ref") is None or price < item["price_ref"]):
            item["price_ref"] = price
            item["source_id"] = p["source_id"]
            item["url"] = p["url"]
            item["storage"] = p.get("storage")
            for field in ("image_url", "image_thumb"):
                if p.get(field):
                    item[field] = p[field]
    return list(dedup.values())


def price_stats(products: list[dict]) -> dict[str, int]:
    buckets = {"<=1999": 0, "2000-4599": 0, "4600-7599": 0, ">=7600": 0, "无报价": 0}
    for p in products:
        price = p.get("price_ref")
        if not price:
            buckets["无报价"] += 1
        elif price <= 1999:
            buckets["<=1999"] += 1
        elif price <= 4599:
            buckets["2000-4599"] += 1
        elif price <= 7599:
            buckets["4600-7599"] += 1
        else:
            buckets[">=7600"] += 1
    return buckets


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", type=int, default=500, help="目标型号数（同型号不同容量算一款）")
    parser.add_argument("--brand-pages", type=int, default=20, help="每个品牌翻几页")
    parser.add_argument("--price-pages", type=int, default=8, help="全站热门/每个价位段翻几页")
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--delay", type=float, default=0.3, help="全局请求间隔（秒）")
    parser.add_argument("--out", default=str(ROOT / "data" / "normalized" / "products.json"))
    parser.add_argument("--probe", action="store_true", help="只检查翻页/列表是否可用，不抓商品")
    args = parser.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    scraper = Scraper(args.delay)
    started = time.time()
    try:
        if args.probe:
            print("翻页自检（同来源不同页 md5 应不同；相同说明翻页参数没生效）")
            scraper.probe()
            return 0

        print(f"候选池：{len(WHITELIST)} 个品牌 × {args.brand_pages} 页 + "
              f"{len(PRICE_BANDS)} 个价位段 × {args.price_pages} 页")
        candidates = scraper.collect_candidates(args.brand_pages, args.price_pages)
        print(f"去重后候选 {len(candidates)} 个，目标 {args.target} 款\n")

        products: list[dict] = []
        seen_models: set[str] = set()
        failed: list[dict] = []
        chunk = args.workers * 8

        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            for start in range(0, len(candidates), chunk):
                if len(seen_models) >= args.target:
                    break
                batch = candidates[start:start + chunk]
                futures = {pool.submit(scraper.scrape_one, pid): pid for pid in batch}
                for future in as_completed(futures):
                    pid = futures[future]
                    try:
                        item = future.result()
                    except Exception as exc:  # noqa: BLE001
                        failed.append({"id": pid, "reason": str(exc)})
                        continue
                    if not item:
                        failed.append({"id": pid, "reason": "detail/param 抓取失败"})
                        continue
                    if item["brand"] not in WHITELIST:
                        continue  # 价位段列表里混进来的其他品牌，丢掉
                    if item["need_manual"]:
                        failed.append({"id": pid, "reason": f"参数不足({item['raw_param_count']})",
                                       "model": item.get("model")})
                        continue
                    key = f"{item['brand']}|{item['model']}"
                    if key in seen_models:
                        continue
                    seen_models.add(key)
                    products.append(item)
                    if len(seen_models) % 25 == 0 or len(seen_models) == args.target:
                        elapsed = time.time() - started
                        print(f"  [{len(seen_models)}/{args.target}] {elapsed:.0f}s  "
                              f"{item['brand']} {item['model'][:22]}")
    finally:
        scraper.close()

    merged = merge_same_model(products)
    merged.sort(key=lambda x: (x.get("price_ref") or 0), reverse=True)

    brand_counts: dict[str, int] = {}
    for p in merged:
        brand_counts[p["brand"]] = brand_counts.get(p["brand"], 0) + 1

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "category": "phone",
        "count": len(merged),
        "brand_counts": brand_counts,
        "price_bands": price_stats(merged),
        "failed": failed,
        "products": merged,
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\n完成：{len(merged)} 款，耗时 {(time.time() - started) / 60:.1f} 分钟")
    print("品牌分布：", "  ".join(f"{k} {v}" for k, v in sorted(brand_counts.items(), key=lambda x: -x[1])))
    print("价位分布：", payload["price_bands"])
    print(f"失败/需人工 {len(failed)} 条 -> {out_path}")
    print("\n下一步：python tools/clean_products.py && python tools/export_sql.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
