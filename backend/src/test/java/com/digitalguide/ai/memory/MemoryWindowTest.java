package com.digitalguide.ai.memory;

import com.digitalguide.ai.graph.ChatMessage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 记忆窗口的纯逻辑测试。
 *
 * <p>这三件事写错的表现都很隐蔽：窗口差一条 → 刚说过的话莫名其妙丢了；
 * 判断用 {@code >=} → 每轮都触发摘要，token 不降反升；摘要拼接不裁尾 → 摘要越滚越长。
 */
class MemoryWindowTest {

    @Test
    @DisplayName("取最近 N 条，正序保持")
    void lastKeepsOrder() {
        List<String> all = List.of("a", "b", "c", "d", "e");
        assertThat(MemoryWindow.last(all, 3)).containsExactly("c", "d", "e");
        // size <= 0 表示不限
        assertThat(MemoryWindow.last(all, 0)).hasSize(5);
        // 比总数还大也不报错
        assertThat(MemoryWindow.last(all, 99)).hasSize(5);
        assertThat(MemoryWindow.last(List.of(), 3)).isEmpty();
    }

    @Test
    @DisplayName("超过阈值才压缩，正好等于阈值不动")
    void summarizeThreshold() {
        MemoryProperties properties = new MemoryProperties();
        properties.setSummarizeAfter(16);

        assertThat(MemoryWindow.shouldSummarize(16, properties)).isFalse();
        assertThat(MemoryWindow.shouldSummarize(17, properties)).isTrue();
    }

    @Test
    @DisplayName("渲染摘要输入时带上角色，单条过长要截断")
    void renderTruncatesLongMessage() {
        String longText = "很".repeat(300);
        String rendered = MemoryWindow.render(List.of(
                new ChatMessage("user", "预算3000"),
                new ChatMessage("assistant", longText)), 200);

        assertThat(rendered).contains("用户：预算3000");
        assertThat(rendered).contains("助手：");
        // 200 字 + 省略号
        assertThat(rendered.length()).isLessThan(300);
        assertThat(rendered).contains("…");
    }

    @Test
    @DisplayName("摘要合并时裁尾部：越新的信息越重要")
    void mergeKeepsTail() {
        String previous = "用户预算三千，看重续航。";
        String fresh = "用户排除了华为，改看小米。";
        String merged = MemoryWindow.mergeSummary(previous, fresh, 20);

        assertThat(merged.length()).isLessThanOrEqualTo(20);
        assertThat(merged).startsWith("…");
        assertThat(merged).endsWith("改看小米。");
    }

    @Test
    @DisplayName("空摘要/空消息不产生垃圾文本")
    void emptyInputs() {
        assertThat(MemoryWindow.render(List.of(), 100)).isEmpty();
        assertThat(MemoryWindow.mergeSummary(null, null, 100)).isEmpty();
        assertThat(MemoryWindow.mergeSummary("", "  ", 100)).isEmpty();
        assertThat(MemoryWindow.mergeSummary("旧摘要", null, 100)).isEqualTo("旧摘要");
    }
}
