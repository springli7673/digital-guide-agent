package com.digitalguide.ai.eval;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 评测判定的回归测试。
 *
 * <p>判定逻辑是"尺子"，它自己错了会让整个评测的结论失效，
 * 所以四类断言各钉一条，外加分位数口径。
 */
class EvalJudgeTest {

    private static final EvalThresholds NO_BENCHMARK = EvalThresholds.load(Path.of("不存在.json"));

    @Test
    @DisplayName("budget：全部价格落在区间内才算过")
    void budgetAllPricesInRange() {
        EvalCase evalCase = new EvalCase("b01", "budget", "预算3000", 1500, 3500, null, null);

        assertThat(EvalJudge.judge(evalCase, result(List.of(
                candidate("A", 2199, Map.of()), candidate("B", 3299, Map.of()))), NO_BENCHMARK).passed())
                .isTrue();

        assertThat(EvalJudge.judge(evalCase, result(List.of(
                candidate("A", 2199, Map.of()), candidate("B", 8999, Map.of()))), NO_BENCHMARK).passed())
                .isFalse();
    }

    @Test
    @DisplayName("budget：没有候选或报错都算失败")
    void budgetRequiresCandidates() {
        EvalCase evalCase = new EvalCase("b02", "budget", "预算3000", 1500, 3500, null, null);
        EvalResult noCandidates = result(List.of());
        assertThat(EvalJudge.judge(evalCase, noCandidates, NO_BENCHMARK).passed()).isFalse();
    }

    @Test
    @DisplayName("refuse：库外品类必须报错或追问，且不能给候选")
    void refuse() {
        EvalCase evalCase = new EvalCase("r01", "refuse", "推荐个微波炉", null, null, null, null);

        assertThat(EvalJudge.judge(evalCase,
                new EvalResult("r01", "refuse", "推荐个微波炉", 1, List.of("error"), List.of(),
                        "", "库里没有", false, Map.of(), false, ""), NO_BENCHMARK).passed())
                .isTrue();

        assertThat(EvalJudge.judge(evalCase, result(List.of(candidate("A", 2199, Map.of()))), NO_BENCHMARK).passed())
                .isFalse();
    }

    @Test
    @DisplayName("refuse：没给候选且有说明就算过，不校验措辞")
    void refuseAcceptsNoEvidenceWithoutMatchingWording() {
        EvalCase evalCase = new EvalCase("r06", "refuse", "今天天气怎么样", null, null, null, null);

        // 知识路径：检索不到资料时的输出
        EvalResult knowledge = new EvalResult("r06", "refuse", "今天天气怎么样", 1,
                List.of("intent", "status", "token"), List.of(),
                "这个话题我这边没有可靠的资料，不想凭空给你一个说法。",
                null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, knowledge, NO_BENCHMARK).passed()).isTrue();

        // 工具路径：同一个问题换了一种说法，同样应该算过（不能靠措辞判）
        EvalResult toolMode = new EvalResult("r06", "refuse", "今天天气怎么样", 1,
                List.of("intent", "status", "token"), List.of(),
                "我只能查手机相关的信息和对比，查不了天气预报。",
                null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, toolMode, NO_BENCHMARK).passed()).isTrue();

        // 空回答不算交代，仍然要判失败
        EvalResult emptyAnswer = new EvalResult("r06", "refuse", "今天天气怎么样", 1,
                List.of("intent"), List.of(), "", null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, emptyAnswer, NO_BENCHMARK).passed()).isFalse();
    }

    @Test
    @DisplayName("fabricate：回答里的价格和型号必须来自候选")
    void fabricate() {
        EvalCase evalCase = new EvalCase("f01", "fabricate", "拍照好的", null, null, null, null);
        List<Map<String, Object>> candidates = List.of(
                candidate("Redmi K80", 2199, Map.of()),
                candidate("iQOO Neo10", 2399, Map.of()));

        EvalResult honest = new EvalResult("f01", "fabricate", "拍照好的", 1, List.of("token"),
                candidates, "推荐 Redmi K80，参考价 ¥2,199，另一款 iQOO Neo10 是 ¥2399。",
                null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, honest, NO_BENCHMARK).passed()).isTrue();

        EvalResult inventedPrice = new EvalResult("f01", "fabricate", "拍照好的", 1, List.of("token"),
                candidates, "推荐 Redmi K80，参考价 ¥1,999。", null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, inventedPrice, NO_BENCHMARK).passed()).isFalse();

        // 注意：型号正则要求"两个以上字母 + 数字"，所以 Xiaomi15 能抓到，
        // 而 S99 / K90 这种「单字母+数字」抓不到——这是沿用旧版正则的已知盲区（详见类注释）
        EvalResult inventedModel = new EvalResult("f01", "fabricate", "拍照好的", 1, List.of("token"),
                candidates, "比较推荐 Xiaomi15 Ultra，参考价 ¥2199。", null, false, Map.of(), false, "");
        assertThat(EvalJudge.judge(evalCase, inventedModel, NO_BENCHMARK).passed()).isFalse();
    }

    @Test
    @DisplayName("prefer：预算内分位线，top3 至少 2 个达标")
    void preferUsesBudgetScopedQuantiles(@TempDir Path tempDir) throws Exception {
        Path products = tempDir.resolve("products.json");
        Files.writeString(products, benchmarkJson(), StandardCharsets.UTF_8);
        EvalThresholds thresholds = EvalThresholds.load(products);
        assertThat(thresholds.isEmpty()).isFalse();

        EvalCase evalCase = new EvalCase("p01", "prefer", "3000以内续航好", 0, 3000, "battery_mah", "high");

        // 两款 7000+ 大电池，一款 5000，应在预算内 P75 之上
        EvalResult good = result(List.of(
                candidate("A", 2199, Map.of("battery_mah", 7200)),
                candidate("B", 2399, Map.of("battery_mah", 7000)),
                candidate("C", 2999, Map.of("battery_mah", 5000))));
        assertThat(EvalJudge.judge(evalCase, good, thresholds).passed()).isTrue();

        EvalResult bad = result(List.of(
                candidate("A", 2199, Map.of("battery_mah", 5000)),
                candidate("B", 2399, Map.of("battery_mah", 5000)),
                candidate("C", 2999, Map.of("battery_mah", 7200))));
        assertThat(EvalJudge.judge(evalCase, bad, thresholds).passed()).isFalse();
    }

    @Test
    @DisplayName("分位数口径与 Python statistics.quantiles(n=4) 对齐")
    void quantilesMatchPythonExclusive() {
        List<Double> values = List.of(1.0, 2.0, 3.0, 4.0);
        // Python: statistics.quantiles([1,2,3,4], n=4) -> [1.25, 2.5, 3.75]
        assertThat(Quantiles.at(values, 0.25)).isEqualTo(1.25);
        assertThat(Quantiles.at(values, 0.50)).isEqualTo(2.5);
        assertThat(Quantiles.at(values, 0.75)).isEqualTo(3.75);
    }

    // ------------------------------------------------------------------ 构造

    private static Map<String, Object> candidate(String model, int price, Map<String, Object> metrics) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("brand", "测试品牌");
        item.put("model", model);
        item.put("priceRef", price);
        item.put("metrics", metrics);
        return item;
    }

    private static EvalResult result(List<Map<String, Object>> candidates) {
        return new EvalResult("x", "budget", "q", 1, List.of("candidates"),
                candidates, "", null, false, Map.of(), false, "");
    }

    /** 造 20 款商品，battery_mah 从 4000 到 8000，让 P75 落在 7000 */
    private static String benchmarkJson() {
        List<String> rows = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            int battery = 4000 + i * 200;      // 4000 … 7800
            int price = 1500 + i * 100;        // 1500 … 3400
            rows.add("{\"price_ref\":" + price + ",\"metrics\":{\"battery_mah\":" + battery + "}}");
        }
        return "{\"products\":[" + String.join(",", rows) + "]}";
    }
}
