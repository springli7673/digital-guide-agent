package com.digitalguide.ai.intent;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 意图归一化的回归测试。
 *
 * <p>覆盖两类问题：模型输出不可信（要白名单、要边界校验），
 * 以及"X 以上"被折算成某个价位分档（b09 那条评测就栽在这里）。
 */
class IntentNormalizerTest {

    @Test
    @DisplayName("「一万以上」必须识别成下界 10000")
    void chineseWanLowerBound() {
        assertThat(IntentNormalizer.lowerBoundOf("一万以上")).isEqualTo(10_000);
        assertThat(IntentNormalizer.lowerBoundOf("两万起步")).isEqualTo(20_000);
        assertThat(IntentNormalizer.lowerBoundOf("1.5万以上")).isEqualTo(15_000);
    }

    @Test
    @DisplayName("「5000以上 / 8000起」识别成下界")
    void digitLowerBound() {
        assertThat(IntentNormalizer.lowerBoundOf("5000以上")).isEqualTo(5000);
        assertThat(IntentNormalizer.lowerBoundOf("8000起")).isEqualTo(8000);
        assertThat(IntentNormalizer.lowerBoundOf("预算3000")).isNull();
        assertThat(IntentNormalizer.lowerBoundOf("2000到3000")).isNull();
    }

    @Test
    @DisplayName("b09 回归：模型把「一万以上」折算成 7600 档时，守卫要把下界拉回 10000")
    void lowerBoundGuardFixesB09() {
        // 模型（错误地）返回了一个"7600 以上"的区间
        Map<String, Object> raw = Map.of(
                "category", "phone",
                "budget_min", 7600,
                "budget_known", true,
                "must_have", List.of("image_score"));

        Intent normalized = IntentNormalizer.normalize(raw, 0);
        Intent guarded = IntentNormalizer.applyLowerBoundGuard(normalized, "一万以上，要影像旗舰");

        assertThat(guarded.budgetMin()).isEqualTo(10_000);
        assertThat(guarded.budgetMax()).isNull();
        assertThat(guarded.budgetKnown()).isTrue();
        assertThat(guarded.needClarify()).isFalse();
    }

    @Test
    @DisplayName("守卫不误伤正常区间")
    void guardDoesNotTouchNormalRange() {
        Map<String, Object> raw = Map.of(
                "category", "phone",
                "budget_min", 1800,
                "budget_max", 3450,
                "budget_known", true);

        Intent normalized = IntentNormalizer.normalize(raw, 0);
        Intent guarded = IntentNormalizer.applyLowerBoundGuard(normalized, "预算3000");

        assertThat(guarded.budgetMin()).isEqualTo(1800);
        assertThat(guarded.budgetMax()).isEqualTo(3450);
    }

    @Test
    @DisplayName("模型编造的维度键和品牌要被丢掉")
    void unknownKeysAreDropped() {
        Map<String, Object> raw = Map.of(
                "category", "phone",
                "budget_known", true,
                "must_have", List.of("battery_mah", "screen_size_6_8", "bokeh_magic"),
                "nice_to_have", List.of("ram", "battery_mah"),
                "brands", List.of("华为", "三星", "锤子"));

        Intent intent = IntentNormalizer.normalize(raw, 0);

        assertThat(intent.mustHave()).containsExactly("battery_mah");
        // nice_to_have 里与 must_have 重复的要去掉
        assertThat(intent.niceToHave()).containsExactly("ram");
        assertThat(intent.brands()).containsExactly("华为");
    }

    @Test
    @DisplayName("未知品类回退到手机")
    void unknownCategoryFallsBack() {
        Intent intent = IntentNormalizer.normalize(
                Map.of("category", "washing_machine", "budget_known", true), 0);
        assertThat(intent.category()).isEqualTo("phone");
        assertThat(intent.categoryLabel()).isEqualTo("手机");
    }

    @Test
    @DisplayName("预算上下界写反了要交换，离谱数字要丢弃")
    void budgetSanity() {
        Intent swapped = IntentNormalizer.normalize(
                Map.of("category", "phone", "budget_min", 5000, "budget_max", 2000), 0);
        assertThat(swapped.budgetMin()).isEqualTo(2000);
        assertThat(swapped.budgetMax()).isEqualTo(5000);

        Intent crazy = IntentNormalizer.normalize(
                Map.of("category", "phone", "budget_min", 30_000_000), 0);
        assertThat(crazy.budgetMin()).isNull();
        assertThat(crazy.budgetKnown()).isFalse();
    }

    @Test
    @DisplayName("「不限预算」算已表态：不该再追问预算")
    void unlimitedBudgetIsKnown() {
        Intent intent = IntentNormalizer.normalize(
                Map.of("category", "phone", "budget_known", true), 0);

        assertThat(intent.budgetKnown()).isTrue();
        assertThat(intent.hasBudget()).isFalse();
        // 没预算也没偏好没品牌，但 budget_known=true 就不该追问
        assertThat(intent.needClarify()).isFalse();
    }

    @Test
    @DisplayName("完全没信息时才追问；追问过一次就不再问")
    void clarifyOnlyWhenNothingKnown() {
        Intent first = IntentNormalizer.normalize(Map.of("category", "phone"), 0);
        assertThat(first.needClarify()).isTrue();

        Intent second = IntentNormalizer.normalize(Map.of("category", "phone"), 1);
        assertThat(second.needClarify()).isFalse();
    }

    @Test
    @DisplayName("点名了别的品类时不要用「预算多少」把话题岔开")
    void nonPhoneCategoryNeverClarifies() {
        Intent intent = IntentNormalizer.normalize(Map.of("category", "earbuds"), 0);
        assertThat(intent.category()).isEqualTo("earbuds");
        assertThat(intent.needClarify()).isFalse();
    }

    @Test
    @DisplayName("wire 的形状就是前端要的形状")
    void wireShape() {
        Intent intent = IntentNormalizer.normalize(Map.of(
                "category", "phone",
                "budget_min", 1800,
                "budget_max", 3450,
                "budget_known", true,
                "must_have", List.of("image_score"),
                "nice_to_have", List.of("charge_w"),
                "brands", List.of("小米"),
                "usage", "拍照"), 0);

        Map<String, Object> wire = Intents.wire(intent);

        assertThat(wire).containsEntry("category", "phone")
                .containsEntry("categoryLabel", "手机")
                .containsEntry("usage", "拍照");
        assertThat((List<?>) wire.get("prefs")).hasSize(2);
        assertThat(wire.get("brands")).isEqualTo(List.of("小米"));

        @SuppressWarnings("unchecked")
        Map<String, Object> budget = (Map<String, Object>) wire.get("budget");
        assertThat(budget).containsEntry("min", 1800).containsEntry("max", 3450);
    }
}
