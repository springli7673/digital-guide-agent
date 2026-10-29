package com.digitalguide.ai.memory;

import com.digitalguide.ai.graph.ChatMessage;

import java.util.ArrayList;
import java.util.List;

/**
 * 记忆的纯逻辑部分：取窗口、判断要不要压缩、把消息渲染成摘要输入。
 *
 * <p>单独抽出来是为了能单测——这三件事最容易写错（窗口差一条、判断用 >= 还是 >），
 * 而它们一错就表现为"多轮对话莫名其妙丢上下文"，线上极难复现。
 */
public final class MemoryWindow {

    private MemoryWindow() {
    }

    /** 取最后 size 条；size <= 0 时返回全部 */
    public static <T> List<T> last(List<T> all, int size) {
        if (all == null || all.isEmpty()) {
            return List.of();
        }
        if (size <= 0 || all.size() <= size) {
            return List.copyOf(all);
        }
        return List.copyOf(all.subList(all.size() - size, all.size()));
    }

    /**
     * 是否该压缩。用 {@code >} 而不是 {@code >=}：
     * 阈值语义是"超过这么多条才压"，正好等于阈值时不动作，避免每轮都触发一次摘要。
     */
    public static boolean shouldSummarize(int totalMessages, MemoryProperties properties) {
        return totalMessages > properties.getSummarizeAfter();
    }

    /**
     * 把要压缩的消息渲染成一段文本，供摘要模型读取。
     * 单条截断避免某条超长回答把整段摘要挤满。
     */
    public static String render(List<ChatMessage> messages, int perMessageChars) {
        if (messages == null || messages.isEmpty()) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        for (ChatMessage message : messages) {
            String content = message.content() == null ? "" : message.content().replaceAll("\\s+", " ").strip();
            if (content.isEmpty()) {
                continue;
            }
            if (content.length() > perMessageChars) {
                content = content.substring(0, perMessageChars) + "…";
            }
            builder.append(message.isUser() ? "用户" : "助手").append('：').append(content).append('\n');
        }
        return builder.toString().strip();
    }

    /** 把已摘要的历史和新摘要拼起来，并裁到上限（摘要本身不能无限长） */
    public static String mergeSummary(String previous, String fresh, int maxChars) {
        StringBuilder builder = new StringBuilder();
        if (previous != null && !previous.isBlank()) {
            builder.append(previous.strip());
        }
        if (fresh != null && !fresh.isBlank()) {
            if (builder.length() > 0) {
                builder.append('\n');
            }
            builder.append(fresh.strip());
        }
        String merged = builder.toString().strip();
        if (maxChars > 0 && merged.length() > maxChars) {
            // 从尾部裁：越新的信息越重要
            merged = "…" + merged.substring(merged.length() - maxChars + 1);
        }
        return merged;
    }

    /** 给解析节点用：把消息列表转成 {role, content} 的紧凑结构 */
    public static List<ChatMessage> copyOf(List<ChatMessage> messages) {
        return messages == null ? List.of() : new ArrayList<>(messages);
    }
}
