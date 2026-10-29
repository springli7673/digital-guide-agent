package com.digitalguide.ai.scoring;

import com.digitalguide.ai.intent.Intent;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 参数打分。
 *
 * <p>原则（和 HANDOFF 第 7 节一致）：
 * <ul>
 *   <li>权重来自 {@code biz.category.spec_schema}，代码里只留兜底；</li>
 *   <li>只在 {@code specs.metrics} 上打分；</li>
 *   <li>分数是<b>候选集内</b>的 min-max 归一化加权和，只表示"这批里排第几"，不是绝对评分。</li>
 * </ul>
 *
 * <p>这个类刻意做成无依赖的纯函数集合：不碰数据库、不碰模型，
 * 这样评分逻辑可以被单测钉死（每个踩过的坑都对应一条测试）。
 */
@Component
public class ScoringService {

    /** 被点名的"参考分"维度：用户问别的维度时，理由里不该夸这两项 */
    private static final Set<String> FOCUS_DIMS = Set.of("image_score", "cpu_score");

    /** 强调某个参考分时，顺带把相关维度也提一点权重 */
    private static final Map<String, Map<String, Double>> BOOST_FOLLOW = Map.of(
            "image_score", Map.of("rear_mp", 1.5, "dxo_camera", 1.2),
            "cpu_score", Map.of("ram", 1.5, "refresh_hz", 1.3));

    private static final double FOCUS_THRESHOLD = 3.0;
    private static final double REASON_MIN_NORM = 0.55;

    // ------------------------------------------------------------------ 权重

    /**
     * 把 must_have / nice_to_have 变成权重放大系数。
     *
     * <p>单一偏好要能<b>主导</b>排序，不只是影像和处理器：
     * 之前只对 FOCUS_DIMS 生效，导致"想要轻薄的"返回三台 230g 的旗舰。
     */
    public Map<String, Double> buildBoost(Intent intent) {
        Map<String, Double> boost = new LinkedHashMap<>();
        for (String key : intent.mustHave()) {
            boost.merge(key, 2.2, Math::max);
        }
        for (String key : intent.niceToHave()) {
            boost.merge(key, 1.6, Math::max);
        }
        for (Map.Entry<String, Map<String, Double>> entry : BOOST_FOLLOW.entrySet()) {
            if (!boost.containsKey(entry.getKey())) {
                continue;
            }
            for (Map.Entry<String, Double> follow : entry.getValue().entrySet()) {
                boost.merge(follow.getKey(), follow.getValue(), Math::max);
            }
        }

        List<String> must = intent.mustHave().stream()
                .filter(SpecSchema.DEFAULT_SPEC_SCHEMA::containsKey)
                .toList();

        if (must.size() >= 2) {
            // 多个偏好：都抬到 3.0，谁也不压谁，展示分仍用综合分
            for (String dim : must) {
                boost.merge(dim, 3.0, Math::max);
            }
        } else if (must.size() == 1) {
            String focus = must.get(0);
            // 单一偏好占约 78% 的话语权：7.0 / (7.0 + 0.4*5)
            boost.merge(focus, 7.0, Math::max);
            Set<String> followers = BOOST_FOLLOW.getOrDefault(focus, Map.of()).keySet();
            for (String dim : SpecSchema.DEFAULT_SPEC_SCHEMA.keySet()) {
                if (dim.equals(focus) || followers.contains(dim)) {
                    continue;
                }
                boost.merge(dim, 0.4, Math::min);
            }
        }
        return boost;
    }

    /** 用户点名的唯一维度；点名了多个就不设单一焦点 */
    public String focusOf(Intent intent) {
        List<String> must = intent.mustHave().stream()
                .filter(SpecSchema.DEFAULT_SPEC_SCHEMA::containsKey)
                .toList();
        return must.size() == 1 ? must.get(0) : null;
    }

    /** 从权重反推焦点：只有被显著放大（≥3）的维度才算 */
    public String focusDim(Map<String, Double> boost) {
        if (boost == null || boost.isEmpty()) {
            return null;
        }
        Map.Entry<String, Double> top = boost.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .orElse(null);
        if (top == null || top.getValue() < FOCUS_THRESHOLD) {
            return null;
        }
        return top.getKey();
    }

    // ------------------------------------------------------------------ 打分

    /**
     * 归一化加权打分，返回按分数降序的列表（含 score / reasons / metrics）。
     *
     * <p>{@code focus} 是用户点名的维度：这一维缺数据的机型按 0 计。
     * 否则"没被评测过"反而因为分母小拿到高分——实测会让没送测的机型
     * 挤在真正影像旗舰的前面。
     */
    public List<Map<String, Object>> score(List<Map<String, Object>> candidates,
                                           Map<String, SpecSchema.Dim> schema,
                                           Map<String, Double> boost,
                                           String focus) {
        if (candidates == null || candidates.isEmpty() || schema == null || schema.isEmpty()) {
            return List.of();
        }
        Map<String, Double> effectiveBoost = boost == null ? Map.of() : boost;
        String effectiveFocus = (focus != null && !focus.isBlank()) ? focus : focusDim(effectiveBoost);

        List<Map<String, Object>> metricsOf = new ArrayList<>(candidates.size());
        for (Map<String, Object> candidate : candidates) {
            metricsOf.add(metricsOf(candidate));
        }

        // 每个维度的候选集内上下界
        Map<String, double[]> stats = new LinkedHashMap<>();
        for (String key : schema.keySet()) {
            List<Double> values = new ArrayList<>();
            for (Map<String, Object> metrics : metricsOf) {
                Double value = num(metrics.get(key));
                if (value != null) {
                    values.add(value);
                }
            }
            if (values.size() < 2) {
                continue;
            }
            double lo = values.stream().mapToDouble(Double::doubleValue).min().orElse(0);
            double hi = values.stream().mapToDouble(Double::doubleValue).max().orElse(0);
            if (hi == lo) {
                continue;
            }
            stats.put(key, new double[]{lo, hi});
        }

        // 每维最优值 + 并列个数，用来区分"唯一最好"和"大家一起最好"
        Map<String, double[]> bestOf = new LinkedHashMap<>();
        for (Map.Entry<String, double[]> entry : stats.entrySet()) {
            String key = entry.getKey();
            SpecSchema.Dim dim = schema.get(key);
            double best = dim.lowerIsBetter() ? entry.getValue()[0] : entry.getValue()[1];
            long count = metricsOf.stream()
                    .map(metrics -> num(metrics.get(key)))
                    .filter(value -> value != null && value == best)
                    .count();
            bestOf.put(key, new double[]{best, count});
        }

        List<Map<String, Object>> scored = new ArrayList<>(candidates.size());
        for (int i = 0; i < candidates.size(); i++) {
            Map<String, Object> candidate = candidates.get(i);
            Map<String, Object> metrics = metricsOf.get(i);

            double total = 0;
            double weightSum = 0;
            Double focusNorm = null;
            List<Reason> parts = new ArrayList<>();

            for (Map.Entry<String, double[]> entry : stats.entrySet()) {
                String key = entry.getKey();
                SpecSchema.Dim dim = schema.get(key);
                if (dim == null) {
                    continue;
                }
                double weight = dim.weight() * effectiveBoost.getOrDefault(key, 1.0);
                Double value = num(metrics.get(key));
                if (value == null) {
                    if (key.equals(effectiveFocus)) {
                        // 按 0 分计入，不做"跳过"处理
                        weightSum += weight;
                    }
                    continue;
                }
                double lo = entry.getValue()[0];
                double hi = entry.getValue()[1];
                double norm = (value - lo) / (hi - lo);
                if (dim.lowerIsBetter()) {
                    norm = 1 - norm;
                }
                if (key.equals(effectiveFocus)) {
                    focusNorm = norm;
                }
                total += weight * norm;
                weightSum += weight;

                if (norm < REASON_MIN_NORM) {
                    continue;
                }
                // 用户问打游戏时，理由里别去夸影像分（反之亦然）
                if (effectiveFocus != null && FOCUS_DIMS.contains(key) && !key.equals(effectiveFocus)) {
                    continue;
                }
                double[] bestInfo = bestOf.getOrDefault(key, new double[]{value, 1});
                boolean isBest = value == bestInfo[0];
                boolean unique = isBest && bestInfo[1] == 1;
                boolean tied = isBest && bestInfo[1] > 1;
                String tail;
                if (unique) {
                    tail = dim.lowerIsBetter() ? "，这批里最低" : "，这批里唯一最高";
                } else if (tied) {
                    tail = "，候选中并列最优";
                } else if (norm >= 0.8) {
                    tail = "，明显优于平均";
                } else {
                    tail = "，优于这批平均";
                }
                double rank = norm * weight * (unique ? 1.5 : tied ? 1.2 : 1.0);
                parts.add(new Reason(rank, dim.label() + " " + fmt(value) + dim.unit() + tail));
            }

            // 点名了参考维度时，展示分就用该维度的候选集内相对分：
            // 否则会出现"影像分 172 的排在 170 后面，卡片上分数还更低"这种自相矛盾的画面
            int score = (effectiveFocus != null && focusNorm != null)
                    ? (int) Math.round(focusNorm * 100)
                    : (weightSum > 0 ? (int) Math.round(total / weightSum * 100) : 0);

            parts.sort(Comparator.comparingDouble(Reason::rank).reversed());

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", candidate.get("id"));
            item.put("brand", candidate.get("brand"));
            item.put("model", candidate.get("model"));
            item.put("priceRef", candidate.get("priceRef"));
            item.put("imageUrl", candidate.get("imageUrl"));
            item.put("score", score);
            item.put("reasons", parts.stream().limit(3).map(Reason::text).toList());
            item.put("metrics", numericMetrics(metrics));
            item.put("highlights", candidate.getOrDefault("highlights", List.of()));
            scored.add(item);
        }

        scored.sort(Comparator
                .comparingInt((Map<String, Object> item) -> (Integer) item.get("score")).reversed()
                .thenComparingDouble(item -> {
                    Double price = num(item.get("priceRef"));
                    return price == null ? 0 : price;
                }));
        return scored;
    }

    // ------------------------------------------------------------------ 小工具

    @SuppressWarnings("unchecked")
    private Map<String, Object> metricsOf(Map<String, Object> candidate) {
        Object specs = candidate.get("specs");
        if (!(specs instanceof Map<?, ?> specMap)) {
            return Map.of();
        }
        Object metrics = specMap.get("metrics");
        if (!(metrics instanceof Map<?, ?> metricMap)) {
            return Map.of();
        }
        return (Map<String, Object>) metricMap;
    }

    private Map<String, Double> numericMetrics(Map<String, Object> metrics) {
        Map<String, Double> result = new LinkedHashMap<>();
        metrics.forEach((key, value) -> {
            Double number = num(value);
            if (number != null) {
                result.put(key, number);
            }
        });
        return result;
    }

    /** 整数就别显示 .0（12070mAh 比 12070.0mAh 好看） */
    public static String fmt(double value) {
        if (value == Math.rint(value)) {
            return String.valueOf((long) value);
        }
        return String.valueOf(Math.round(value * 100) / 100.0);
    }

    static Double num(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        String text = String.valueOf(value).trim();
        if (text.isEmpty()) {
            return null;
        }
        try {
            return Double.parseDouble(text);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private record Reason(double rank, String text) {
    }
}
