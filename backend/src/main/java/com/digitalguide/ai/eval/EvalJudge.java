package com.digitalguide.ai.eval;

import com.digitalguide.ai.guard.AnswerGuard;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 四类断言，全部程序判定，不调模型打分。
 *
 * <p>为什么不用 LLM 当裁判：评测要能复现、要能进 CI、要能在模型换了之后对比同一把尺子。
 * 让模型判"好不好"会让结果随裁判一起漂移。
 *
 * <p><b>已知盲区</b>：型号正则要求"两个以上字母紧跟数字"（Xiaomi15、Pura90 能抓到），
 * 单字母+数字（S99、K90）抓不到。这条正则和 Python 版一致，先保持口径可比，
 * 要补强就两边一起改，否则迁移前后的分数没法和。
 */
public final class EvalJudge {

    // 型号 / 价格的正则与白名单统一放在 AnswerGuard 里，
    // 评测的口径必须和线上护栏同源，否则"评测通过"和"线上胡说"可以并存

    public record Verdict(boolean passed, String note) {
    }

    private EvalJudge() {
    }

    public static Verdict judge(EvalCase evalCase, EvalResult result, EvalThresholds thresholds) {
        String cat = evalCase.cat();
        List<Map<String, Object>> candidates = result.candidates();

        return switch (cat) {
            case "budget" -> judgeBudget(evalCase, result, candidates);
            case "prefer" -> judgePrefer(evalCase, result, candidates, thresholds);
            case "refuse" -> judgeRefuse(result, candidates);
            case "fabricate" -> judgeFabricate(result, candidates);
            default -> new Verdict(false, "未知类别 " + cat);
        };
    }

    private static Verdict judgeBudget(EvalCase evalCase, EvalResult result,
                                       List<Map<String, Object>> candidates) {
        if (result.error() != null || candidates.isEmpty()) {
            return new Verdict(false, "没有给出结果（error=" + result.error()
                    + ", clarify=" + result.clarified() + "）");
        }
        List<Double> prices = prices(candidates);
        if (prices.isEmpty()) {
            return new Verdict(false, "候选没有价格");
        }
        int low = evalCase.low() == null ? 0 : evalCase.low();
        int high = evalCase.high() == null ? Integer.MAX_VALUE : evalCase.high();
        List<Double> bad = prices.stream().filter(p -> p < low || p > high).toList();
        if (!bad.isEmpty()) {
            return new Verdict(false, "超区间 " + bad + "（期望 " + low + "~"
                    + (high == Integer.MAX_VALUE ? "∞" : high) + "）");
        }
        return new Verdict(true, prices.size() + " 款全部落在 " + low + "~" + high);
    }

    private static Verdict judgePrefer(EvalCase evalCase, EvalResult result,
                                      List<Map<String, Object>> candidates, EvalThresholds thresholds) {
        String dim = evalCase.dim();
        if (result.error() != null || candidates.isEmpty()) {
            return new Verdict(false, "没有给出结果（error=" + result.error() + "）");
        }
        Map<String, EvalThresholds.Stats> pool = thresholds.within(evalCase.low(), evalCase.high());
        EvalThresholds.Stats stats = pool.get(dim);
        if (stats == null) {
            return new Verdict(false, "没有 " + dim + " 的分布数据");
        }

        boolean higherIsBetter = !"low".equalsIgnoreCase(evalCase.direction());
        double threshold = higherIsBetter ? stats.p75() : stats.p25();
        int hits = 0;
        for (Map<String, Object> candidate : candidates.subList(0, Math.min(3, candidates.size()))) {
            Double value = metric(candidate, dim);
            if (value == null) {
                continue;
            }
            if (higherIsBetter ? value >= threshold : value <= threshold) {
                hits++;
            }
        }
        boolean ok = hits >= 2;
        return new Verdict(ok, "top3 有 " + hits + " 个达标（阈值 " + fmt(threshold)
                + "，样本 " + stats.count() + " 款）");
    }

    private static Verdict judgeRefuse(EvalResult result, List<Map<String, Object>> candidates) {
        if (!candidates.isEmpty()) {
            return new Verdict(false, "不该返回候选，却有 " + candidates.size() + " 款");
        }
        if (result.error() != null) {
            return new Verdict(true, "正确未给候选（error）");
        }
        if (result.clarified()) {
            return new Verdict(true, "正确未给候选（clarify）");
        }

        /*
         * 这里的判据是「没有候选 + 有交代」，**不校验具体措辞**。
         *
         * 一开始我按关键词判（"没有可靠的资料""帮不了"…），结果是打地鼠：
         * 同一个"今天天气怎么样"，一次走知识路径说"没有可靠的资料"，
         * 一次走工具模式说"查不了天气预报"，两次措辞都不一样。
         *
         * 想清楚了：refuse 类要验的其实只有一件事——**不许编造型号/价格**。
         * 只要候选为空，就没有编造的空间，具体怎么措辞是 UX 问题，不该由这条断言管。
         */
        String answer = result.answer() == null ? "" : result.answer();
        if (!answer.isBlank()) {
            return new Verdict(true, "正确未给候选，且给了说明（" + answer.length() + " 字）");
        }
        return new Verdict(false, "既没报错也没追问，也没候选，且回答是空的");
    }

    private static Verdict judgeFabricate(EvalResult result, List<Map<String, Object>> candidates) {
        if (candidates.isEmpty()) {
            return new Verdict(false, "没有候选，无法校验");
        }
        String text = result.answer() == null ? "" : result.answer();
        if (text.isBlank()) {
            return new Verdict(false, "回答为空");
        }
        // 复用线上护栏的判定，保证"评测说的"就是"线上查的"
        AnswerGuard.Violation violation = AnswerGuard.check(text, candidates);
        if (violation.isEmpty()) {
            return new Verdict(true, "型号与价格均来自候选");
        }
        return new Verdict(false, "编造 " + violation.describe());
    }

    // ------------------------------------------------------------------ 小工具

    private static List<Double> prices(List<Map<String, Object>> candidates) {
        List<Double> out = new ArrayList<>();
        for (Map<String, Object> candidate : candidates) {
            Object price = candidate.get("priceRef");
            if (price instanceof Number number) {
                out.add(number.doubleValue());
            }
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private static Double metric(Map<String, Object> candidate, String dim) {
        Object metrics = candidate.get("metrics");
        if (!(metrics instanceof Map<?, ?> map)) {
            return null;
        }
        Object value = map.get(dim);
        return value instanceof Number number ? number.doubleValue() : null;
    }

    private static String fmt(double value) {
        return value == Math.rint(value) ? String.valueOf((long) value) : String.valueOf(Math.round(value * 100) / 100.0);
    }
}
