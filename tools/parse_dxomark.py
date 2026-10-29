"""把 DXOMARK 排行榜变成 data/reference/dxomark_camera.json

支持两种输入（有哪个用哪个）：
    data/reference/dxo_raw.html   直接抓下来的页面（可能是 HTML 表格，也可能内嵌 JSON）
    data/reference/dxo_paste.txt  从浏览器里复制表格粘出来的文本（制表符分隔）

用法：
    python tools/parse_dxomark.py

输出：
    {"scores": {"huaweipura80ultra": 175, ...}, "meta": {...}}
    之后 tools/build_reference.py 会把它并进商品的 metrics.dxo_camera
"""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "data" / "reference"
HTML = REF / "dxo_raw.html"
PASTE = REF / "dxo_paste.txt"
OUT = REF / "dxomark_camera.json"

BRAND_PREFIX = {
    "huawei": "华为", "honor": "荣耀", "xiaomi": "小米", "redmi": "红米",
    "oppo": "OPPO", "vivo": "vivo", "iqoo": "iQOO", "oneplus": "一加",
    "apple": "苹果", "iphone": "苹果", "samsung": "三星", "google": "谷歌",
}


def norm(text: str) -> str:
    """型号归一：小写、去空格/连字符/括号内容，英文品牌名换成中文，和库里对齐。"""
    s = (text or "").strip().lower()
    s = re.sub(r"[（(].*?[）)]", "", s)
    s = re.sub(r"[\s\-_·]+", "", s)
    for en, cn in BRAND_PREFIX.items():
        if s.startswith(en):
            s = cn + s[len(en):]
            break
    return s


def score_of(cells: list[str]) -> int | None:
    """摄像头分是价格/日期之后第一个 2~3 位纯数字。"""
    for cell in cells:
        c = cell.strip()
        if re.fullmatch(r"\d{2,3}", c):
            value = int(c)
            if 20 <= value <= 200:
                return value
    return None


def parse_html(text: str) -> list[tuple[str, int]]:
    rows: list[tuple[str, int]] = []
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", text, re.S | re.I):
        cells = [
            re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", c)).strip()
            for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S | re.I)
        ]
        cells = [c for c in cells if c]
        if len(cells) < 4:
            continue
        name = next((c for c in cells[1:3] if re.search(r"[A-Za-z\u4e00-\u9fa5]", c)), "")
        score = score_of(cells)
        if name and score:
            rows.append((name, score))
    return rows


def parse_json_block(text: str) -> list[tuple[str, int]]:
    """页面里内嵌的 JS 数组/对象：抓「型号 + 分数」相邻出现的片段。"""
    rows: list[tuple[str, int]] = []
    pattern = re.compile(
        r'"(?:name|device|model|title)"\s*:\s*"([^"]{3,60})"[^{}]{0,200}?'
        r'"(?:score|camera|photo|global)"\s*:\s*"?(\d{2,3})"?',
        re.I,
    )
    for name, score in pattern.findall(text):
        value = int(score)
        if 20 <= value <= 200:
            rows.append((name, value))
    return rows


DEV_START = re.compile(r'\{"device":"smartphone","id":\d+,"name":"([^"]+)"')
CAM_SCORE = re.compile(r'"tocol":"camera","score":(\d+)')


def parse_embedded_devices(text: str) -> list[tuple[str, int]]:
    """DXOMARK 榜单页把数据内嵌成一段 JSON，每个设备形如：

        {"device":"smartphone","id":630,"name":"Huawei Pura 80 Ultra","brand":"Huawei",
         ... ,"scores":[...,{"tocol":"camera","score":175,"subscores":{...}}]}

    这里按「下一个设备开始」切块，再在块内找 tocol=camera 的分数。
    """
    rows: list[tuple[str, int]] = []
    starts = list(DEV_START.finditer(text))
    for i, match in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else min(len(text), match.start() + 6000)
        chunk = text[match.end():end]
        camera = CAM_SCORE.search(chunk)
        if camera:
            score = int(camera.group(1))
            if 20 <= score <= 200:
                rows.append((match.group(1), score))
    return rows


def parse_paste(text: str) -> list[tuple[str, int]]:
    rows: list[tuple[str, int]] = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        cells = [c.strip() for c in re.split(r"\t+", line) if c.strip()]
        if len(cells) < 3:
            # 退化成空格分隔：'1 Huawei Pura 80 Ultra $1199 2025年6月 175'
            cells = [c for c in re.split(r"\s{2,}|\s(?=\$)|\s(?=\d{4}年)", line) if c.strip()]
        name = next((c for c in cells if re.search(r"[A-Za-z]{3,}", c) and not c.startswith("$")), "")
        score = score_of(cells)
        if name and score:
            rows.append((name, score))
    return rows


def main() -> int:
    sources = []
    if HTML.exists() and HTML.stat().st_size > 20000:
        text = HTML.read_text(encoding="utf-8", errors="ignore")
        parsed = parse_html(text) or parse_embedded_devices(text) or parse_json_block(text)
        sources.append(("dxo_raw.html", parsed))
    if PASTE.exists():
        sources.append(("dxo_paste.txt", parse_paste(PASTE.read_text(encoding="utf-8", errors="ignore"))))

    rows: list[tuple[str, int]] = []
    used = []
    for name, parsed in sources:
        if parsed:
            print(f"[{name}] 解析出 {len(parsed)} 行")
            rows.extend(parsed)
            used.append(name)

    if not rows:
        print("没有拿到数据。检查：\n"
              "  1) data/reference/dxo_raw.html 是否 >20KB（403 只有几百字节）\n"
              "  2) 或者把页面表格复制到 data/reference/dxo_paste.txt")
        return 1

    scores: dict[str, int] = {}
    for name, score in rows:
        key = norm(name)
        if key and key not in scores:
            scores[key] = score

    # 手工补几条最常见的英文/中文别名差异
    ALIAS = {
        "华为人像": None,
    }
    for alias, target in ALIAS.items():
        if target and alias in scores and target not in scores:
            scores[target] = scores[alias]

    OUT.write_text(
        json.dumps(
            {"scores": scores, "meta": {"rows": len(rows), "sources": used}},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"写出 {OUT}（{len(scores)} 个型号）")
    print("示例：", list(scores.items())[:5])
    print("\n下一步：python tools/build_reference.py && python tools/export_sql.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
