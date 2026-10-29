package com.digitalguide.ai.memory;

import com.digitalguide.ai.graph.ChatMessage;
import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.ai.prompt.PromptLoader;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 会话记忆的读写。
 *
 * <p>读写分开、都吞异常：<b>记忆是增强，不是主链路</b>。
 * 表没建、库抖一下，对话必须照常进行——最多退回"只靠前端传的 history"。
 *
 * <p>压缩策略是"先摘要、再删消息"：摘要写成功才删，避免把历史弄丢；
 * 摘要失败就保留原始消息，让它继续占 token，下轮再试。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MemoryService {

    private static final int SUMMARY_INPUT_PER_MESSAGE = 200;

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final LlmClient llm;
    private final LlmProperties llmProperties;
    private final PromptLoader prompts;
    private final MemoryProperties properties;

    /**
     * 装载记忆。库里没有会话时退回前端传来的 history——
     * 这样"第一次对话"和"库挂了"两种情况都能工作。
     */
    public MemoryContext load(String sessionId, List<ChatMessage> fallbackHistory) {
        if (!properties.isEnabled() || sessionId == null || sessionId.isBlank()) {
            return new MemoryContext("", MemoryWindow.last(fallbackHistory, properties.getWindowSize()), Map.of());
        }
        try {
            List<Map<String, Object>> sessions = jdbc.queryForList(
                    "SELECT summary, slots::text AS slots FROM ai.chat_session WHERE session_id = ?", sessionId);
            String summary = sessions.isEmpty() ? "" : asString(sessions.get(0).get("summary"));
            Map<String, Object> anchor = sessions.isEmpty() ? Map.of() : parseSlots(sessions.get(0).get("slots"));

            List<ChatMessage> recent = jdbc.query("""
                            SELECT role, content FROM ai.chat_message
                            WHERE session_id = ? ORDER BY id DESC LIMIT ?
                            """,
                    (rs, rowNum) -> new ChatMessage(rs.getString("role"), rs.getString("content")),
                    sessionId, properties.getWindowSize());
            // 查询按 id 倒序取最近 N 条，用之前要翻回正序
            Collections.reverse(recent);

            if (recent.isEmpty()) {
                recent = MemoryWindow.last(fallbackHistory, properties.getWindowSize());
            }
            return new MemoryContext(summary, recent, anchor);
        } catch (Exception e) {
            log.debug("记忆装载失败，退回前端 history：{}", e.getMessage());
            return new MemoryContext("", MemoryWindow.last(fallbackHistory, properties.getWindowSize()), Map.of());
        }
    }

    /** 一轮对话结束后落库：两条消息 + 更新槽位锚点，必要时触发压缩 */
    public void append(String sessionId, String question, String answer, Intent intent) {
        if (!properties.isEnabled() || sessionId == null || sessionId.isBlank()) {
            return;
        }
        try {
            jdbc.update("INSERT INTO ai.chat_message (session_id, role, content) VALUES (?, 'user', ?)",
                    sessionId, truncate(question, 2000));
            if (answer != null && !answer.isBlank()) {
                jdbc.update("INSERT INTO ai.chat_message (session_id, role, content) VALUES (?, 'assistant', ?)",
                        sessionId, truncate(answer, 4000));
            }
            jdbc.update("""
                            INSERT INTO ai.chat_session (session_id, slots, turns, updated_at)
                            VALUES (?, ?::jsonb, 1, now())
                            ON CONFLICT (session_id) DO UPDATE
                            SET slots = EXCLUDED.slots, turns = ai.chat_session.turns + 1, updated_at = now()
                            """,
                    sessionId, objectMapper.writeValueAsString(slotPayload(intent)));
            maybeSummarize(sessionId);
        } catch (Exception e) {
            log.debug("记忆写入失败（不影响本轮回答）：{}", e.getMessage());
        }
    }

    // ------------------------------------------------------------------ 压缩

    private void maybeSummarize(String sessionId) {
        try {
            Integer total = jdbc.queryForObject(
                    "SELECT count(*) FROM ai.chat_message WHERE session_id = ?", Integer.class, sessionId);
            if (total == null || !MemoryWindow.shouldSummarize(total, properties)) {
                return;
            }
            int compressCount = total - properties.getWindowSize();
            if (compressCount <= 0) {
                return;
            }

            List<Map<String, Object>> rows = jdbc.queryForList("""
                    SELECT id, role, content FROM ai.chat_message
                    WHERE session_id = ? ORDER BY id ASC LIMIT ?
                    """, sessionId, compressCount);
            if (rows.isEmpty()) {
                return;
            }
            List<ChatMessage> messages = new ArrayList<>();
            long maxId = 0;
            for (Map<String, Object> row : rows) {
                messages.add(new ChatMessage(asString(row.get("role")), asString(row.get("content"))));
                maxId = Math.max(maxId, ((Number) row.get("id")).longValue());
            }

            String previous = jdbc.query("SELECT summary FROM ai.chat_session WHERE session_id = ?",
                    rs -> rs.next() ? asString(rs.getString(1)) : "", sessionId);
            String input = MemoryWindow.mergeSummary(previous, MemoryWindow.render(messages, SUMMARY_INPUT_PER_MESSAGE), 0);

            String fresh;
            try {
                fresh = llm.complete(llmProperties.routerRequest(prompts.load("memory_summary"), input));
            } catch (Exception e) {
                // 摘要失败就保留原始消息，下轮再试；不要删了再失败
                log.warn("摘要生成失败，保留原始历史：{}", e.getMessage());
                return;
            }
            if (fresh == null || fresh.isBlank()) {
                return;
            }

            String merged = MemoryWindow.mergeSummary(previous, fresh, properties.getSummaryMaxChars());
            jdbc.update("UPDATE ai.chat_session SET summary = ?, updated_at = now() WHERE session_id = ?",
                    merged, sessionId);
            jdbc.update("DELETE FROM ai.chat_message WHERE session_id = ? AND id <= ?", sessionId, maxId);
            log.info("记忆压缩完成：{} 条消息 → 摘要 {} 字", messages.size(), merged.length());
        } catch (Exception e) {
            log.debug("记忆压缩失败：{}", e.getMessage());
        }
    }

    // ------------------------------------------------------------------ 小工具

    /** 槽位锚点只存"能继承的"字段，不存 needClarify 之类的瞬时状态 */
    private Map<String, Object> slotPayload(Intent intent) {
        Map<String, Object> payload = new LinkedHashMap<>();
        if (intent == null) {
            return payload;
        }
        payload.put("category", intent.category());
        payload.put("budgetMin", intent.budgetMin());
        payload.put("budgetMax", intent.budgetMax());
        payload.put("budgetKnown", intent.budgetKnown());
        payload.put("mustHave", intent.mustHave());
        payload.put("niceToHave", intent.niceToHave());
        payload.put("brands", intent.brands());
        return payload;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> parseSlots(Object raw) {
        if (raw == null) {
            return Map.of();
        }
        try {
            return objectMapper.readValue(asString(raw), Map.class);
        } catch (Exception e) {
            return Map.of();
        }
    }

    private static String asString(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private static String truncate(String text, int max) {
        if (text == null) {
            return "";
        }
        return text.length() <= max ? text : text.substring(0, max);
    }
}
