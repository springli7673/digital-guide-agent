package com.digitalguide.ai.scoring;

import com.digitalguide.ai.intent.Intent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 打分逻辑的回归测试。
 *
 * <p>每一条对应一个"以前踩过的坑"。测试的价值不是发现新 bug，
 * 而是防止以后调权重时把老坑改回来。
 */
class ScoringServiceTest {

    private final ScoringService scoring = new ScoringService();

    @Test
    @DisplayName("缺数据的维度不能因为分母小而排到前面")
    void missingFocusedDimensionRanksLast() {
        // A 有影像分但没有 DXO，B/C 两项都有。用户点名 DXO 时，A 的 DXO 必须按 0 计入分母，
        // 否则"没被评测过"反而拿高分。
        // 注意前提：至少要 2 个候选有该维度，否则这一维连上下界都建不出来（会被跳过），
        // 这正是当初那个 bug 只在全库打分时才暴露的原因。
        Map<String, Object> noDxo = candidate("A", Map.of("image_score", 100));
        Map<String, Object> bestDxo = candidate("B", Map.of("image_score", 85, "dxo_camera", 150));
        Map<String, Object> weakDxo = candidate("C", Map.of("image_score", 70, "dxo_camera", 120));

        List<Map<String, Object>> ranked = scoring.score(
                List.of(noDxo, bestDxo, weakDxo), SpecSchema.DEFAULT_SPEC_SCHEMA, Map.of(), "dxo_camera");

        assertThat(ranked).hasSize(3);
        assertThat(ranked.get(0).get("model")).isEqualTo("B");
        assertThat(ranked.get(1).get("model")).isEqualTo("A");
        assertThat(score(ranked.get(0))).isEqualTo(100);
        // A 没有 DXO，展示分被拉低而不是被抬高
        assertThat(score(ranked.get(1))).isLessThan(score(ranked.get(0)));
    }

    @Test
    @DisplayName("单一偏好要能主导排序：说轻薄就该把最轻的排第一")
    void singlePreferenceDrivesRanking() {
        Map<String, Object> heavy = candidate("重旗舰", Map.of("weight_g", 230, "cpu_score", 420, "image_score", 100));
        Map<String, Object> light = candidate("轻薄机", Map.of("weight_g", 168, "cpu_score", 200, "image_score", 55));

        Intent intent = new Intent("phone", "手机", true, 1000, 6000,
                List.of("weight_g"), List.of(), List.of(), "", false, "");

        List<Map<String, Object>> ranked = scoring.score(
                List.of(heavy, light), SpecSchema.DEFAULT_SPEC_SCHEMA,
                scoring.buildBoost(intent), scoring.focusOf(intent));

        assertThat(ranked.get(0).get("model")).isEqualTo("轻薄机");
        // 展示分用该维度的候选集内相对分：最轻的那台就是 100
        assertThat(score(ranked.get(0))).isEqualTo(100);
    }

    @Test
    @DisplayName("单一偏好时焦点权重是 7.0，其余维度被压到 0.4")
    void focusWeightIsSeven() {
        Intent intent = new Intent("phone", "手机", true, 1000, 6000,
                List.of("image_score"), List.of(), List.of(), "", false, "");
        Map<String, Double> boost = scoring.buildBoost(intent);

        assertThat(boost).containsEntry("image_score", 7.0);
        // 关联维度保留自己的权重，不被压到 0.4
        assertThat(boost).containsEntry("rear_mp", 1.5);
        assertThat(boost).containsEntry("dxo_camera", 1.2);
        // 无关维度被压低
        assertThat(boost.get("battery_mah")).isEqualTo(0.4);
    }

    @Test
    @DisplayName("两个偏好都抬到 3.0，且不设单一焦点")
    void twoPreferencesAreBalanced() {
        Intent intent = new Intent("phone", "手机", true, 1000, 6000,
                List.of("battery_mah", "image_score"), List.of(), List.of(), "", false, "");
        Map<String, Double> boost = scoring.buildBoost(intent);

        assertThat(boost.get("battery_mah")).isEqualTo(3.0);
        assertThat(boost.get("image_score")).isEqualTo(3.0);
        assertThat(scoring.focusOf(intent)).isNull();
    }

    @Test
    @DisplayName("用户问续航时，理由里不要夸影像梯队分")
    void reasonsSkipUnrelatedFocusDimension() {
        Map<String, Object> a = candidate("A", Map.of(
                "image_score", 100, "dxo_camera", 170, "battery_mah", 6000, "cpu_score", 400));
        Map<String, Object> b = candidate("B", Map.of(
                "image_score", 70, "dxo_camera", 120, "battery_mah", 5000, "cpu_score", 300));

        Intent intent = new Intent("phone", "手机", true, 1000, 6000,
                List.of("battery_mah"), List.of(), List.of(), "", false, "");

        List<Map<String, Object>> ranked = scoring.score(
                List.of(a, b), SpecSchema.DEFAULT_SPEC_SCHEMA,
                scoring.buildBoost(intent), scoring.focusOf(intent));

        @SuppressWarnings("unchecked")
        List<String> reasons = (List<String>) ranked.get(0).get("reasons");
        assertThat(reasons).anyMatch(text -> text.startsWith("电池容量"));
        // 只屏蔽"参考分"本身；DXO 是影像的子指标，按原版行为保留
        assertThat(reasons).noneMatch(text -> text.startsWith("影像梯队"));
    }

    @Test
    @DisplayName("价格相同时按分数降序，价格不同不参与排序")
    void sortByScoreThenPrice() {
        Map<String, Object> cheapGood = candidate("便宜好用", Map.of("battery_mah", 7000, "price", 1999));
        Map<String, Object> priceyWeak = candidate("高价低配", Map.of("battery_mah", 4000, "price", 5999));

        List<Map<String, Object>> ranked = scoring.score(
                List.of(priceyWeak, cheapGood), SpecSchema.DEFAULT_SPEC_SCHEMA, Map.of(), null);

        assertThat(ranked.get(0).get("model")).isEqualTo("便宜好用");
    }

    @Test
    @DisplayName("候选为空或维度表为空时返回空列表，不抛异常")
    void emptyInputs() {
        assertThat(scoring.score(List.of(), SpecSchema.DEFAULT_SPEC_SCHEMA, Map.of(), null)).isEmpty();
        assertThat(scoring.score(List.of(candidate("A", Map.of())), Map.of(), Map.of(), null)).isEmpty();
    }

    // ------------------------------------------------------------------ 构造

    private static Map<String, Object> candidate(String model, Map<String, Object> metrics) {
        Map<String, Object> specs = new LinkedHashMap<>();
        specs.put("metrics", metrics);
        Map<String, Object> candidate = new LinkedHashMap<>();
        candidate.put("id", (long) Math.abs(model.hashCode()));
        candidate.put("brand", "测试品牌");
        candidate.put("model", model);
        candidate.put("priceRef", metrics.getOrDefault("price", new BigDecimal("2999")));
        candidate.put("specs", specs);
        candidate.put("highlights", List.of());
        return candidate;
    }

    private static int score(Map<String, Object> item) {
        return (Integer) item.get("score");
    }
}
