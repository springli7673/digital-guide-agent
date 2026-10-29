package com.digitalguide.ai.trace;

import com.digitalguide.ai.graph.ChatState;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * 对话链路埋点：一轮问答一条记录，写到 {@code ai.trace}。
 *
 * <p>为什么不做成 OpenTelemetry：OTel 需要 collector + 后端（Jaeger/Langfuse），
 * 对一个单机项目来说是纯运维负担。这里做的是最小可用的那一层——
 * **能回答"这次为什么慢、为什么被护栏拦、检索命中几条"**，就够了。
 * 要接 OTel 时，把 {@code record()} 里换成 span 上报即可，调用点不用改。
 *
 * <p>写法上刻意用 {@code try/catch} 吞掉异常：埋点失败绝不能影响用户拿到回答。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TraceService {

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public void record(ChatState state) {
        if (state == null || state.getIntent() == null) {
            return;
        }
        try {
            Map<String, Long> timings = state.getNodeTimings();
            long total = timings.values().stream().mapToLong(Long::longValue).sum();
            jdbc.update("""
                            INSERT INTO ai.trace
                                (session_id, question, category, candidates, kb_hits,
                                 latency_ms, timing, guard_violation, error)
                            VALUES (?, ?, ?, ?, ?, ?, ?::jsonb, ?, ?)
                            """,
                    state.getSessionId(),
                    truncate(state.getMessage(), 500),
                    state.getIntent().category(),
                    state.getRanked().isEmpty() ? state.getCandidates().size() : state.getRanked().size(),
                    state.getKbChunks().size(),
                    (int) total,
                    objectMapper.writeValueAsString(timings),
                    state.getGuardViolation(),
                    state.getError());
        } catch (Exception e) {
            // 表还没建 / 库抖动 / JSON 序列化失败，都不该让这一轮对话失败
            log.debug("trace 写入失败（不影响回答）：{}", e.getMessage());
        }
    }

    private static String truncate(String text, int max) {
        if (text == null) {
            return "";
        }
        return text.length() <= max ? text : text.substring(0, max);
    }
}
