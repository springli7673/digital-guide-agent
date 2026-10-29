package com.digitalguide.ai.graph;

import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.intent.Intents;
import com.digitalguide.ai.scoring.ScoringService;
import com.digitalguide.ai.scoring.SpecSchema;
import com.digitalguide.ai.scoring.SpecSchemaProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** score：读类目权重 → 归一化加权打分 → 取前 3 款推给前端。 */
@Component
@RequiredArgsConstructor
public class ScoreNode {

    private static final int TOP_N = 3;

    private final ScoringService scoringService;
    private final SpecSchemaProvider schemaProvider;

    public void run(ChatState state, EventSink sink) {
        Intent intent = state.getIntent();
        List<Map<String, Object>> candidates = state.getCandidates();

        sink.emit("status", Map.of("stage", "scoring",
                "text", "命中 " + candidates.size() + " 款，按 "
                        + Intents.describePrefs(intent) + " 加权打分…"));

        Map<String, SpecSchema.Dim> schema = schemaProvider.schemaFor(intent.category());
        Map<String, Double> boost = scoringService.buildBoost(intent);
        String focus = scoringService.focusOf(intent);

        List<Map<String, Object>> ranked =
                scoringService.score(candidates, schema, boost, focus);
        List<Map<String, Object>> top = ranked.size() > TOP_N
                ? new ArrayList<>(ranked.subList(0, TOP_N))
                : ranked;

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("total", ranked.size());
        payload.put("items", top);
        sink.emit("candidates", payload);

        state.setRanked(top);
        state.setSchema(schema);
    }
}
