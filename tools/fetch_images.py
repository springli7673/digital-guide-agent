"""把商品主图抓到本地，压成 webp，落到 web-vite/public/img/products/

为什么要有这一步：数据是从中关村在线（ZOL）抓的，`image_url` 一直指向
`2a~2f.zol-img.com.cn`。它家图床有两个毛病——**会防盗链、也会删图**，
只要断网或对方调整，商城里就是一片空白块。图片本身只有 138 张，
干脆下载到仓库里，前端按 `/img/products/{source_id}.webp` 直接引用，
clone 下来就能跑，不依赖任何外部图床。

用法：
    python tools/fetch_images.py              # 只补缺的
    python tools/fetch_images.py --force      # 全部重下
    python tools/fetch_images.py --only 2177484
    python tools/fetch_images.py --limit 5    # 先试 5 张

产物：
    web-vite/public/img/products/{source_id}.webp

依赖：Pillow（`pip install pillow`），其余是标准库。
注意：`source_id` 是 ZOL 的商品编号，**不是**数据库自增 id。
用它的原因是 seed_products.sql 每次都 DELETE 重建商品表，自增 id 会漂，
拿 id 当文件名的话重灌一次数据图就全错位了。
"""

import argparse
import io
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # 在 import 处就报清楚，别等下载完 138 张才炸
    sys.exit("[FAIL] 缺少 Pillow，先执行： pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "normalized" / "products.json"
OUT_DIR = ROOT / "web-vite" / "public" / "img" / "products"

MAX_WIDTH = 480      # 卡片最大显示宽度不到 200px，480 已经是 2x 屏
QUALITY = 80
TRIES = 3
SLEEP = 0.3          # 别把人家图床当自家 CDN 使

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
    ),
    # ZOL 图床对空 Referer 会返回 403，带上详情页地址
    "Referer": "https://detail.zol.com.cn/",
    "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
}


def fetch(url: str) -> bytes:
    """下载一张图，带重试；失败抛最后一次异常。"""
    last = None
    for i in range(TRIES):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=20) as resp:
                return resp.read()
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError) as e:
            last = e
            time.sleep(1.0 * (i + 1))
    raise RuntimeError(f"下载失败：{url}（{last}）")


def to_webp(raw: bytes, dest: Path) -> tuple[int, int, int]:
    """转成 webp 落盘，返回 (宽, 高, 字节数)。"""
    img = Image.open(io.BytesIO(raw))
    if img.mode not in ("RGB", "RGBA"):
        # 手机主图有调色板 PNG / 灰度图，统一一下才存得动
        img = img.convert("RGBA" if "transparency" in img.info else "RGB")
    if img.width > MAX_WIDTH:
        height = round(img.height * MAX_WIDTH / img.width)
        img = img.resize((MAX_WIDTH, height), Image.LANCZOS)
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, "WEBP", quality=QUALITY, method=6)
    return img.width, img.height, dest.stat().st_size


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="已存在的也重下")
    ap.add_argument("--only", help="只处理这个 source_id")
    ap.add_argument("--limit", type=int, help="只处理前 N 张（调试用）")
    ap.add_argument("--src", default=str(SRC), help="products.json 路径")
    ap.add_argument("--out", default=str(OUT_DIR), help="输出目录")
    args = ap.parse_args()

    payload = json.loads(Path(args.src).read_text(encoding="utf-8"))
    products = payload["products"] if isinstance(payload, dict) else payload
    out_dir = Path(args.out)

    if args.only:
        products = [p for p in products if str(p.get("source_id")) == args.only]
        if not products:
            return print(f"[FAIL] 没有 source_id = {args.only} 的商品") or 1
    if args.limit:
        products = products[: args.limit]

    ok = skipped = failed = 0
    total_bytes = 0
    failures: list[str] = []

    for i, p in enumerate(products, 1):
        sid = str(p.get("source_id") or "").strip()
        name = f"{p.get('brand', '')} {p.get('model', '')}".strip()
        if not sid:
            failed += 1
            failures.append(f"{name}：没有 source_id")
            continue
        dest = out_dir / f"{sid}.webp"
        if dest.exists() and not args.force:
            skipped += 1
            total_bytes += dest.stat().st_size
            print(f"[{i}/{len(products)}] skip  {sid} {name}")
            continue

        url = p.get("image_url") or p.get("image_thumb")
        try:
            raw = fetch(url)
            w, h, size = to_webp(raw, dest)
            ok += 1
            total_bytes += size
            print(f"[{i}/{len(products)}] ok    {sid} {name}  {w}x{h} {size / 1024:.0f}KB")
        except Exception as e:  # noqa: BLE001 —— 单张失败不该中断整批
            failed += 1
            failures.append(f"{sid} {name}：{e}")
            print(f"[{i}/{len(products)}] FAIL  {sid} {name}  {e}")
        time.sleep(SLEEP)

    print()
    print(f"总计 {len(products)} 款：新下 {ok} / 已存在 {skipped} / 失败 {failed}")
    print(f"目录 {out_dir}")
    print(f"体积 {total_bytes / 1024 / 1024:.2f} MB")
    if failures:
        print("\n失败清单：")
        for line in failures:
            print("  -", line)
        return 1
    print("\n记得：db/migration_local_images.sql 把库里的 URL 也换成本地路径。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
