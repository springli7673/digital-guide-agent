"""评测 runner：拿真实接口跑一批 case，用程序断言判对错，输出报告。

用法（项目根目录，Agent 服务需已启动）：
    python eval/run_eval.py                       # 全量 40 条
    python eval/run_eval.py --limit 5             # 先跑 5 条看看
    python eval/run_eval.py --base http://127.0.0.1:8000

四类断言：
    budget     候选价格必须落在预期区间内（全部，不是"大部分"）
    prefer     点名的维度上，前 3 名里至少 2 个落在候选集的前 25%（weight_g 取后 25%）
    refuse     库内没有的品类/区间 → 必须给 error 或 clarify，且不能返回候选
    fabricate  回答里出现的型号与价格，必须都来自候选集

产出：eval/report.json（原始轨迹）+ eval/report.md（人看的报告）
"""

import argparse
import json
import re
import statistics
import sys
import time
from datetime import datetime
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parent.parent
CASES = ROOT / "eval" / "cases.json"
PRODUCTS = ROOT / "data" / "normalized" / "products.json"
OUT_JSON = ROOT / "eval" / "report.json"
OUT_MD = ROOT / "eval" / "report.md"

def quantiles_for(products: list[dict], low, high) -> dict[str, dict[str, float]]:
    """按预算过滤后算各维分位数：'5000以内拍照好'要用预算内的分布当基准。"""
    dims = ("image_score", "cpu_score", "battery_mah", "weight_g",
            "charge_w", "screen_inch", "refresh_hz")
    out: dict[str, dict[str, float]] = {}
    for dim in dims:
        values = []
        for p in products:
            m = p.get("metrics") or {}
            if m.get(dim) is None:
                continue
            price = p.get("price_ref") or 0
            if low is not None and price < low:
                continue
            if high is not None and high < 999999 and price > high:
                continue
            values.append(m[dim])
        if len(values) < 4:
            continue
        q = statistics.quantiles(sorted(values), n=4)
        out[dim] = {"p25": q[0], "p50": q[1], "p75": q[2], "count": len(values)}
    return out


def global_thresholds() -> dict[str, dict[str, float]]:
    """全库分位数，作为"该维度是否属于头部"的判定基准。

    必须用全库而不是候选集：接口只回 top3，在 3 个数上算 P75 等于取最大值，
    要求"top3 里 2 个 ≥ 最大值"永远不可能达成（实测误判了 6 条）。
    """
    if not PRODUCTS.exists():
        return {}
    products = json.loads(PRODUCTS.read_text(encoding="utf-8"))["products"]
    dims = ("image_score", "cpu_score", "battery_mah", "weight_g",
            "charge_w", "screen_inch", "refresh_hz")
    out: dict[str, dict[str, float]] = {}
    for dim in dims:
        values = sorted(
            p["metrics"][dim] for p in products
            if (p.get("metrics") or {}).get(dim) is not None
        )
        if len(values) < 4:
            continue
        q = statistics.quantiles(values, n=4)
        out[dim] = {"p25": q[0], "p50": q[1], "p75": q[2], "count": len(values)}
    return out


# 回答里这些不算型号，别误判成编造
IGNORE_TOKENS = {
    "5g", "4g", "wifi", "nfc", "ip68", "ip69", "ip67", "120hz", "165hz", "144hz",
    "90hz", "mah", "gb", "tb", "w", "wifi6", "wifi7", "type-c", "usb",
}


def parse_sse(line_iter):
    """把 SSE 流拆成 (event, data)。"""
    event, data = "message", []
    for raw in line_iter:
        line = raw.rstrip("\n").rstrip("\r")
        if line == "":
            if data:
                payload = "\n".join(data)
                try:
                    yield event, json.loads(payload)
                except json.JSONDecodeError:
                    yield event, {"text": payload}
            event, data = "message", []
            continue
        if line.startswith(":"):
            continue
        field, _, value = line.partition(":")
        value = value[1:] if value.startswith(" ") else value
        if field == "event":
            event = value
        elif field == "data":
            data.append(value)


def run_case(client, base, case, timeout=180):
    started = time.perf_counter()
    events, candidates, answer, status_texts = [], [], [], []
    intent = None
    error_msg = None

    with client.stream(
        "POST",
        f"{base}/v1/chat",
        json={"message": case["query"], "history": [], "clarifyCount": 0},
        timeout=timeout,
    ) as resp:
        resp.raise_for_status()
        for event, data in parse_sse(resp.iter_lines()):
            events.append(event)
            if event == "token":
                answer.append(data.get("text", ""))
            elif event == "candidates":
                candidates = data.get("items") or []
            elif event == "error":
                error_msg = data.get("msg")
            elif event == "status":
                status_texts.append(data.get("text", ""))
            elif event == "intent":
                intent = data

    return {
        "id": case["id"],
        "cat": case["cat"],
        "query": case["query"],
        "latency_ms": round((time.perf_counter() - started) * 1000),
        "events": sorted(set(events)),
        "candidates": candidates,
        "answer": "".join(answer),
        "error": error_msg,
        "intent": intent,
        "clarified": "clarify" in events,
    }


def _prices(candidates):
    return [c.get("priceRef") for c in candidates if c.get("priceRef") is not None]


def _dim_values(candidates, dim):
    return [
        (c.get("metrics") or {}).get(dim)
        for c in candidates
        if (c.get("metrics") or {}).get(dim) is not None
    ]


THRESHOLDS = global_thresholds()
ALL_PRODUCTS = (
    json.loads(PRODUCTS.read_text(encoding="utf-8"))["products"] if PRODUCTS.exists() else []
)


def judge(case, result):
    """返回 (是否通过, 说明)。"""
    cat = case["cat"]
    cands = result["candidates"]

    if cat == "budget":
        if result["error"] or not cands:
            return False, f"没有给出结果（error={result['error']}, clarify={result['clarified']}）"
        prices = _prices(cands)
        if not prices:
            return False, "候选没有价格"
        low, high = case["low"], case["high"]
        bad = [p for p in prices if not (low <= p <= high)]
        if bad:
            return False, f"超区间 {bad}（期望 {low}~{high}）"
        return True, f"{len(prices)} 款全部落在 {low}~{high}"

    if cat == "prefer":
        dim = case["dim"]
        if result["error"] or not cands:
            return False, f"没有给出结果（error={result['error']}）"
        low, high = case.get("low"), case.get("high")
        pool = (quantiles_for(ALL_PRODUCTS, low, high)
                if low is not None or high is not None else THRESHOLDS)
        stats = pool.get(dim)
        if not stats:
            return False, f"没有 {dim} 的分布数据"
        if case["direction"] == "high":
            threshold = stats["p75"]
            hits = [v for v in _dim_values(cands[:3], dim) if v is not None and v >= threshold]
        else:
            threshold = stats["p25"]
            hits = [v for v in _dim_values(cands[:3], dim) if v is not None and v <= threshold]
        ok = len(hits) >= 2
        return ok, (f"top3 有 {len(hits)} 个达标（全库阈值 {threshold:g}，"
                    f"样本 {stats['count']} 款）")

    if cat == "refuse":
        if cands:
            return False, f"不该返回候选，却有 {len(cands)} 款"
        if result["error"] or result["clarified"]:
            how = "error" if result["error"] else "clarify"
            return True, f"正确未给候选（{how}）"
        return False, "既没报错也没追问，但也没候选"

    if cat == "fabricate":
        if not cands:
            return False, "没有候选，无法校验"
        text = result["answer"]
        if not text.strip():
            return False, "回答为空"

        # 1) 价格：回答里出现的 ¥数字必须都在候选价格里（允许 ±1 的取整误差）
        cand_prices = set()
        for p in _prices(cands):
            cand_prices.add(int(round(p)))
            cand_prices.add(int(round(p / 100)) * 100)
        bad_prices = []
        for raw in re.findall(r"[¥￥]\s?([\d,]+)", text):
            value = int(raw.replace(",", ""))
            if not any(abs(value - p) <= 1 for p in cand_prices):
                bad_prices.append(value)

        # 2) 型号：像型号的 token 必须能在候选型号里找到
        cand_text = " ".join(
            (c.get("brand", "") + c.get("model", "")).lower().replace(" ", "")
            for c in cands
        )
        bad_models = []
        for token in re.findall(r"[A-Za-z]{2,}[0-9][A-Za-z0-9]*", text):
            low = token.lower()
            if low in IGNORE_TOKENS or len(low) < 4:
                continue
            if low not in cand_text:
                bad_models.append(token)

        problems = []
        if bad_prices:
            problems.append(f"编造价格 {bad_prices[:3]}")
        if bad_models:
            problems.append(f"编造型号 {bad_models[:3]}")
        if problems:
            return False, "；".join(problems)
        return True, "型号与价格均来自候选"

    return False, f"未知类别 {cat}"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="http://127.0.0.1:8000")
    parser.add_argument("--limit", type=int, default=0, help="只跑前 N 条")
    parser.add_argument("--only", default="", help="只跑某个类别：budget/prefer/refuse/fabricate")
    args = parser.parse_args()

    cases = json.loads(CASES.read_text(encoding="utf-8"))
    if args.only:
        cases = [c for c in cases if c["cat"] == args.only]
    if args.limit:
        cases = cases[: args.limit]

    results = []
    with httpx.Client(timeout=180) as client:
        try:
            health = client.get(f"{args.base}/healthz", timeout=10).json()
        except Exception as exc:  # noqa: BLE001
            print(f"[FAIL] 连不上 Agent 服务 {args.base}：{exc}")
            print("       先把 uvicorn 起起来再跑评测")
            return 1

        print(f"目标 {args.base}  模型 {health.get('chat_model')}  "
              f"db={health.get('db')} ollama={health.get('ollama')}")
        print(f"共 {len(cases)} 条 case\n")

        for i, case in enumerate(cases, 1):
            try:
                result = run_case(client, args.base, case)
            except Exception as exc:  # noqa: BLE001
                result = {
                    "id": case["id"], "cat": case["cat"], "query": case["query"],
                    "latency_ms": 0, "events": [], "candidates": [], "answer": "",
                    "error": f"运行异常：{exc}", "clarified": False,
                }
            passed, note = judge(case, result)
            result["passed"] = passed
            result["note"] = note
            results.append(result)

            mark = "PASS" if passed else "FAIL"
            print(f"[{i:>2}/{len(cases)}] {mark}  {case['id']:<4} {case['query'][:22]:<24} "
                  f"{result['latency_ms'] / 1000:>5.1f}s  {note}")

    # ---------------- 汇总
    by_cat: dict[str, dict[str, int]] = {}
    for r in results:
        stat = by_cat.setdefault(r["cat"], {"total": 0, "pass": 0})
        stat["total"] += 1
        stat["pass"] += 1 if r["passed"] else 0

    total = len(results)
    passed = sum(1 for r in results if r["passed"])
    latencies = sorted(r["latency_ms"] for r in results)
    has_image = any(
        (c.get("metrics") or {}).get("image_score") is not None
        for r in results for c in r["candidates"]
    )
    has_cpu = any(
        (c.get("metrics") or {}).get("cpu_score") is not None
        for r in results for c in r["candidates"]
    )

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "base": args.base,
        "model": health.get("chat_model"),
        "data_has_image_score": has_image,
        "data_has_cpu_score": has_cpu,
        "summary": {
            "total": total,
            "passed": passed,
            "pass_rate": round(passed / total * 100, 1) if total else 0,
            "p50_latency_ms": latencies[len(latencies) // 2] if latencies else 0,
            "by_cat": by_cat,
        },
        "results": results,
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    lines = [
        "# 评测报告",
        "",
        f"- 生成时间：{payload['generated_at']}",
        f"- 目标服务：{args.base}（模型 `{health.get('chat_model')}`）",
        f"- 数据版本：`image_score` {'有' if has_image else '**缺失**'} · "
        f"`cpu_score` {'有' if has_cpu else '**缺失**'}",
        f"- 总览：**{passed}/{total}** 通过（{payload['summary']['pass_rate']}%），"
        f"P50 延迟 {payload['summary']['p50_latency_ms'] / 1000:.1f}s",
        "",
        "| 类别 | 通过 / 总数 | 通过率 |",
        "|---|---|---|",
    ]
    for cat, stat in by_cat.items():
        rate = round(stat["pass"] / stat["total"] * 100) if stat["total"] else 0
        lines.append(f"| {cat} | {stat['pass']} / {stat['total']} | {rate}% |")

    failed = [r for r in results if not r["passed"]]
    lines += ["", f"## 失败 case（{len(failed)} 条）", ""]
    if failed:
        lines += ["| id | 提问 | 原因 |", "|---|---|---|"]
        for r in failed:
            lines.append(f"| {r['id']} | {r['query']} | {r['note']} |")
    else:
        lines.append("无。")

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"\n结果：{passed}/{total} 通过（{payload['summary']['pass_rate']}%）")
    print(f"报告：{OUT_MD}")
    return 0 if passed == total else 0


if __name__ == "__main__":
    sys.exit(main())
