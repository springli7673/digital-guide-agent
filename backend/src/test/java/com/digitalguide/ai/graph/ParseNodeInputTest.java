package com.digitalguide.ai.graph;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 解析节点输入拼装的测试。
 *
 * <p>多轮对话出问题时，80% 的原因在"喂给模型的上下文不对"，而不是模型不行。
 * 这里把三层上下文（摘要 / 槽位锚点 / 最近对话）分别钉住。
 */
class ParseNodeInputTest {

    @Test
    @DisplayName("没有历史也没有摘要时，输入就是原话")
    void bareMessage() {
        ChatState state = new ChatState("预算3000", "s1", List.of(), 0);
        assertThat(ParseNode.buildParseInput(state)).isEqualTo("预算3000");
    }

    @Test
    @DisplayName("摘要、槽位、最近对话三层都要出现")
    void allThreeLayersPresent() {
        ChatState state = new ChatState("再便宜点", "s1",
                List.of(new ChatMessage("user", "预算3000"), new ChatMessage("assistant", "推荐了这几款")), 0);
        state.setSummary("用户预算三千，看重续航，排除了华为。");
        state.setAnchor(Map.of(
                "budgetMin", 1800, "budgetMax", 3450,
                "mustHave", List.of("battery_mah"),
                "brands", List.of("小米")));

        String input = ParseNode.buildParseInput(state);

        assertThat(input).contains("【早前对话摘要】").contains("排除了华为");
        assertThat(input).contains("【已确认的槽位】")
                .contains("预算 1800–3450")
                .contains("重点 battery_mah")
                .contains("品牌 小米");
        assertThat(input).contains("【最近对话】").contains("用户：预算3000");
        assertThat(input).endsWith("【用户本轮】\n再便宜点");
    }

    @Test
    @DisplayName("锚点里只有预算时也能渲染，不出现 null")
    void anchorWithoutPrefs() {
        String text = ParseNode.anchorText(Map.of("budgetMin", 1800, "budgetMax", 3450));
        assertThat(text).contains("预算 1800–3450");
        assertThat(text).doesNotContain("null");
    }

    @Test
    @DisplayName("预算只有一边时显示「不限」")
    void anchorOneSidedBudget() {
        assertThat(ParseNode.anchorText(Map.of("budgetMin", 10000))).contains("预算 10000–不限");
    }

    @Test
    @DisplayName("空锚点返回空串，不往输入里塞空段落")
    void emptyAnchor() {
        assertThat(ParseNode.anchorText(Map.of())).isEmpty();
        assertThat(ParseNode.anchorText(null)).isEmpty();

        ChatState state = new ChatState("看看手机", "s1", List.of(), 0);
        assertThat(ParseNode.buildParseInput(state)).doesNotContain("已确认的槽位");
    }

    @Test
    @DisplayName("历史超过上限只取最近几条，避免把上下文撑爆")
    void historyWindow() {
        List<ChatMessage> history = new java.util.ArrayList<>();
        for (int i = 0; i < 12; i++) {
            history.add(new ChatMessage("user", "第" + i + "轮"));
        }
        ChatState state = new ChatState("继续", "s1", history, 0);

        String input = ParseNode.buildParseInput(state);
        assertThat(input).contains("第11轮");
        assertThat(input).doesNotContain("第0轮");
    }
}
