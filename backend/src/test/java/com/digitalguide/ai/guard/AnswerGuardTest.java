package com.digitalguide.ai.guard;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 幻觉护栏的回归测试。
 *
 * <p>这个类同时被线上校验和评测判定使用，所以它错了会同时污染两边：
 * 放得太松 → 编造漏过去；收得太紧 → 正常的参数词被当成型号，回答被无故"更正"。
 * 两个方向各钉几条。
 */
class AnswerGuardTest {

    private static final List<Map<String, Object>> CANDIDATES = List.of(
            candidate("小米", "Redmi K80", 2199),
            candidate("vivo", "iQOO Neo10", 2399));

    @Test
    @DisplayName("型号和价格都来自候选时，不报警")
    void cleanAnswerPasses() {
        String answer = "推荐 Redmi K80，参考价 ¥2,199；另一款 iQOO Neo10 是 ¥2399。";
        assertThat(AnswerGuard.check(answer, CANDIDATES).isEmpty()).isTrue();
    }

    @Test
    @DisplayName("候选外的价格要被抓出来")
    void inventedPriceIsCaught() {
        AnswerGuard.Violation violation = AnswerGuard.check(
                "Redmi K80 参考价 ¥1,999。", CANDIDATES);

        assertThat(violation.isEmpty()).isFalse();
        assertThat(violation.prices()).containsExactly(1999.0);
        assertThat(violation.describe()).contains("1999");
    }

    @Test
    @DisplayName("候选外的型号要被抓出来")
    void inventedModelIsCaught() {
        AnswerGuard.Violation violation = AnswerGuard.check(
                "也可以看看 Xiaomi15 Ultra，参考价 ¥2199。", CANDIDATES);

        assertThat(violation.models()).anyMatch(token -> token.toLowerCase().contains("xiaomi15"));
    }

    @Test
    @DisplayName("技术名词不能当成型号：LPDDR5X / UFS4.0 / WiFi7 / 120Hz 都放行")
    void techTermsAreNotModels() {
        String answer = """
                Redmi K80 用 LPDDR5X 内存和 UFS4.0 存储，支持 WiFi7，
                屏幕 120Hz，参考价 ¥2199。
                """;
        AnswerGuard.Violation violation = AnswerGuard.check(answer, CANDIDATES);

        assertThat(violation.models()).isEmpty();
        assertThat(violation.isEmpty()).isTrue();
    }

    @Test
    @DisplayName("整百取整可以接受：2199 说成 2200 不算编造")
    void roundedPriceIsAcceptable() {
        assertThat(AnswerGuard.check("参考价 ¥2200 起。", CANDIDATES).isEmpty()).isTrue();
        // 但 2000 就不行，差得太多
        assertThat(AnswerGuard.check("参考价 ¥2000 起。", CANDIDATES).isEmpty()).isFalse();
    }

    @Test
    @DisplayName("空回答或空候选时不误报")
    void emptyInputs() {
        assertThat(AnswerGuard.check("", CANDIDATES).isEmpty()).isTrue();
        assertThat(AnswerGuard.check(null, CANDIDATES).isEmpty()).isTrue();
        assertThat(AnswerGuard.check("推荐 Redmi K80，¥2199", List.of()).isEmpty()).isTrue();
    }

    private static Map<String, Object> candidate(String brand, String model, int price) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("brand", brand);
        item.put("model", model);
        item.put("priceRef", BigDecimal.valueOf(price));
        return item;
    }
}
