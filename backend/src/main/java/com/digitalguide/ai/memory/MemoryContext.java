package com.digitalguide.ai.memory;

import com.digitalguide.ai.graph.ChatMessage;

import java.util.List;
import java.util.Map;

/**
 * 一次对话开始时装载出来的记忆快照。
 *
 * @param summary 被压缩掉的历史摘要（可能为空）
 * @param recent  滑动窗口内的最近消息
 * @param anchor  最近一次确认的槽位（Intent 的 JSON 视图），没有就是空 Map
 */
public record MemoryContext(String summary, List<ChatMessage> recent, Map<String, Object> anchor) {

    public static MemoryContext empty() {
        return new MemoryContext("", List.of(), Map.of());
    }

    public boolean hasSummary() {
        return summary != null && !summary.isBlank();
    }

    public boolean hasAnchor() {
        return anchor != null && !anchor.isEmpty();
    }
}
