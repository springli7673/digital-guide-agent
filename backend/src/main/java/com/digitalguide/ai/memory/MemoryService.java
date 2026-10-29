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
    private final RedisMemoryStore redisMemory;

    /**
     * 装载记忆。库里没有会话时退回前端传来的 history——
     * 这样"第一次对话"和"库挂了"两种情况都能工作。
     *
     * <p>顺序：Redis 热存 → PostgreSQL（拿到就回填 Redis）。
     * 连续追问是最常见的用法，热存命中时这一轮完全不碰数据库。
     */
    public MemoryContext load(String sessionId, List<ChatMessage> fallbackHistory) {
        if (!properties.isEnabled() || sessionId == null || sessionId.isBlank()) {
            return new MemoryContext("", MemoryWindow.last(fallbackHistory, properties.getWindowSize()), Map.of());
        }
        MemoryContext hot = redisMemory.load(sessionId);
        if (hot != null) {
            return hot;
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
            MemoryContext context = new MemoryContext(summary, recent, anchor);
            // 回填热存：下一轮追问直接命中，省掉这一轮的两次查询
            redisMemory.save(sessionId, context);
            return context;
        } catch (Exception e) {
            log.debug("记忆装载失败，退回前端 history：{}", e.getMessage());
            return new MemoryContext("", MemoryWindow.last(fallbackHistory, properties.getWindowSize()), Map.of());
        }
    }

    /** 一轮对话结束后落库：两条消息 + 更新槽位锚点，必要时触发压缩 */
    public void append(String sessionId, String question, String answer, Intent intent) {
        append(sessionId, question, answer, intent, null);
    }

    /**
     * 同上，但带着"本轮开始时装载出来的那份上下文"。
     *
     * <p>为什么要多传一个参数：写穿热存需要知道压缩后的新窗口，
     * 而那份窗口 = 旧窗口 + 本轮两条消息。有了 base 就不用再查一次库，
     * 否则每轮多两次 SELECT，热存省的 IO 又被自己吃回去。
     */
    public void append(String sessionId, String question, String answer, Intent intent, MemoryContext base) {
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
            String summary = maybeSummarize(sessionId);
            // 写穿热存：PG 是权威，Redis 跟着更新，两边不会漂
            redisMemory.save(sessionId, new MemoryContext(summary,
                    nextWindow(base, question, answer), slotPayload(intent)));
        } catch (Exception e) {
            log.debug("记忆写入失败（不影响本轮回答）：{}", e.getMessage());
        }
    }

    /** 旧窗口 + 本轮问答，再裁到窗口大小——和 PG 里实际留下的那几条保持一致 */
    private List<ChatMessage> nextWindow(MemoryContext base, String question, String answer) {
        List<ChatMessage> merged = new ArrayList<>();
        if (base != null && base.recent() != null) {
            merged.addAll(base.recent());
        }
        merged.add(new ChatMessage("user", truncate(question, 2000)));
        if (answer != null && !answer.isBlank()) {
            merged.add(new ChatMessage("assistant", truncate(answer, 4000)));
        }
        return MemoryWindow.last(merged, properties.getWindowSize());
    }

    // ------------------------------------------------------------------ 压缩

    /**
     * 需要就压一次，并<b>返回压缩后的最新摘要</b>（不需要压就返回库里现有的）。
     *
     * <p>返回值是为写穿热存服务的：调用方拿到它就能一次把 Redis 写对，
     * 不必再补一次 SELECT。
     */
    private String maybeSummarize(String sessionId) {
        String current = readSummary(sessionId);
        try {
            Integer total = jdbc.queryForObject(
                    "SELECT count(*) FROM ai.chat_message WHERE session_id = ?", Integer.class, sessionId);
            if (total == null || !MemoryWindow.shouldSummarize(total, properties)) {
                return current;
            }
            int compressCount = total - properties.getWindowSize();
            if (compressCount <= 0) {
                return current;
            }

            List<Map<String, Object>> rows = jdbc.queryForList("""
                    SELECT id, role, content FROM ai.chat_message
                    WHERE session_id = ? ORDER BY id ASC LIMIT ?
                    """, sessionId, compressCount);
            if (rows.isEmpty()) {
                return current;
            }
            List<ChatMessage> messages = new ArrayList<>();
            long maxId = 0;
            for (Map<String, Object> row : rows) {
                messages.add(new ChatMessage(asString(row.get("role")), asString(row.get("content"))));
                maxId = Math.max(maxId, ((Number) row.get("id")).longValue());
            }

            String input = MemoryWindow.mergeSummary(current,
                    MemoryWindow.render(messages, SUMMARY_INPUT_PER_MESSAGE), 0);

            String fresh;
            try {
                fresh = llm.complete(llmProperties.routerRequest(prompts.load("memory_summary"), input));
            } catch (Exception e) {
                // 摘要失败就保留原始消息，下轮再试；不要删了再失败
                log.warn("摘要生成失败，保留原始历史：{}", e.getMessage());
                return current;
            }
            if (fresh == null || fresh.isBlank()) {
                return current;
            }

            String merged = MemoryWindow.mergeSummary(current, fresh, properties.getSummaryMaxChars());
            jdbc.update("UPDATE ai.chat_session SET summary = ?, updated_at = now() WHERE session_id = ?",
                    merged, sessionId);
            jdbc.update("DELETE FROM ai.chat_message WHERE session_id = ? AND id <= ?", sessionId, maxId);
            log.info("记忆压缩完成：{} 条消息 → 摘要 {} 字", messages.size(), merged.length());
            return merged;
        } catch (Exception e) {
            log.debug("记忆压缩失败：{}", e.getMessage());
            return current;
        }
    }

    private String readSummary(String sessionId) {
        try {
            String summary = jdbc.query("SELECT summary FROM ai.chat_session WHERE session_id = ?",
                    rs -> rs.next() ? asString(rs.getString(1)) : "", sessionId);
            return summary == null ? "" : summary;
        } catch (Exception e) {
            return "";
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
