package com.digitalguide.ai.eval;

import java.util.List;
import java.util.Map;

/** 一条 case 跑完之后的记录（也是 report.json 里的一条）。 */
public record EvalResult(
        String id,
        String cat,
        String query,
        long latencyMs,
        List<String> events,
        List<Map<String, Object>> candidates,
        String answer,
        String error,
        boolean clarified,
        Map<String, Object> intent,
        /** done 事件里带回来的引用来源（知识型问题才有） */
        List<String> sourceLabels,
        boolean passed,
        String note
) {

    public EvalResult withVerdict(boolean passed, String note) {
        return new EvalResult(id, cat, query, latencyMs, events, candidates, answer,
                error, clarified, intent, sourceLabels, passed, note);
    }
}
