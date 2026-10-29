package com.digitalguide.ai.trace;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 最近若干轮对话的链路摘要。
 *
 * <p>注意路径是 {@code /admin/**}，不在 {@code /api/**} 的登录拦截范围内——
 * 单机项目阶段够用，对外暴露前必须加鉴权（记在 HANDOFF 的待办里）。
 */
@RestController
@RequiredArgsConstructor
public class TraceController {

    private final JdbcTemplate jdbc;

    @GetMapping("/admin/trace")
    public List<Map<String, Object>> recent(@RequestParam(defaultValue = "20") int limit) {
        int safeLimit = Math.min(Math.max(limit, 1), 200);
        return jdbc.queryForList("""
                SELECT id, created_at, question, category, candidates, kb_hits,
                       latency_ms, timing, guard_violation, error
                FROM ai.trace
                ORDER BY created_at DESC
                LIMIT ?
                """, safeLimit);
    }

    /** 聚合口径：护栏拦截率和各节点均值，用来判断"要不要继续调 prompt" */
    @GetMapping("/admin/trace/stats")
    public Map<String, Object> stats() {
        return jdbc.queryForMap("""
                SELECT count(*)                                   AS total,
                       coalesce(avg(latency_ms), 0)::int          AS avg_latency_ms,
                       count(*) FILTER (WHERE guard_violation IS NOT NULL) AS guard_hits,
                       count(*) FILTER (WHERE error IS NOT NULL)   AS errors,
                       count(*) FILTER (WHERE category = 'knowledge') AS knowledge_runs
                FROM ai.trace
                """);
    }
}
