package com.digitalguide.ai.rag;

import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.ai.prompt.PromptLoader;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 精排：让模型给"这段资料能不能回答这个问题"打 0~10 分。
 *
 * <p>为什么用 LLM 而不是 cross-encoder：本地跑 bge-reranker 需要 ONNX Runtime + 模型文件，
 * 而对话模型已经在手上了。一次调用评完 20~40 条（listwise），成本远低于逐条打分，
 * 对一个十来篇语料的知识库完全够用。
 *
 * <p><b>失败必须可降级</b>：精排挂了就退回 RRF 顺序，并且要告诉上层"这批分数不可信"，
 * 否则证据闸门会拿 RRF 的分数去比 0.2 的阈值，把本来能用的资料全丢掉。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KbReranker {

    /** @param reliable 分数是否来自真正的精排（决定证据闸门能不能用） */
    public record RerankResult(List<KbChunk> chunks, boolean reliable) {
    }

    private static final int SNIPPET_CHARS = 220;

    private final LlmClient llm;
    private final LlmProperties llmProperties;
    private final PromptLoader prompts;
    private final ObjectMapper objectMapper;
    private final RagProperties properties;

    public RerankResult rerank(String question, List<KbChunk> candidates) {
        if (candidates.isEmpty()) {
            return new RerankResult(List.of(), false);
        }
        if (!properties.isRerankEnabled()) {
            return new RerankResult(candidates, false);
        }

        try {
            String raw = llm.complete(llmProperties.routerRequest(
                    prompts.load("rerank"), buildInput(question, candidates)));
            Map<Integer, Double> scores = parseScores(raw);
            if (scores.isEmpty()) {
                log.warn("精排返回无法解析，退回 RRF 顺序：{}", truncate(raw, 160));
                return new RerankResult(candidates, false);
            }

            List<KbChunk> scored = new ArrayList<>(candidates.size());
            for (int i = 0; i < candidates.size(); i++) {
                Double score = scores.get(i + 1);
                // 模型漏打分的片段按 0 处理：宁可排到后面，也别让它凭 RRF 名次插队
                scored.add(candidates.get(i).withScore(score == null ? 0 : score / 10.0));
            }
            scored.sort(Comparator.comparingDouble(KbChunk::score).reversed());
            log.info("精排完成：{} 条，最高分 {}，最低分 {}", scored.size(),
                    scored.isEmpty() ? 0 : scored.get(0).score(),
                    scored.isEmpty() ? 0 : scored.get(scored.size() - 1).score());
            return new RerankResult(scored, true);
        } catch (Exception e) {
            log.warn("精排失败，退回 RRF 顺序：{}", e.getMessage());
            return new RerankResult(candidates, false);
        }
    }

    private String buildInput(String question, List<KbChunk> candidates) {
        StringBuilder builder = new StringBuilder();
        builder.append("【用户问题】\n").append(question).append("\n\n【候选资料】\n");
        for (int i = 0; i < candidates.size(); i++) {
            KbChunk chunk = candidates.get(i);
            builder.append(i + 1).append(". [").append(chunk.label()).append("] ")
                    .append(truncate(chunk.content(), SNIPPET_CHARS)).append('\n');
        }
        return builder.toString();
    }

    private Map<Integer, Double> parseScores(String raw) {
        Map<Integer, Double> scores = new LinkedHashMap<>();
        if (raw == null || raw.isBlank()) {
            return scores;
        }
        try {
            JsonNode root = objectMapper.readTree(stripFence(raw));
            JsonNode array = root.isArray() ? root : root.path("scores");
            if (!array.isArray()) {
                return scores;
            }
            for (JsonNode node : array) {
                int index = node.path("i").asInt(node.path("index").asInt(-1));
                double value = node.path("s").asDouble(node.path("score").asDouble(-1));
                if (index > 0 && value >= 0) {
                    scores.put(index, Math.min(value, 10));
                }
            }
        } catch (Exception e) {
            log.debug("精排输出解析失败：{}", e.getMessage());
        }
        return scores;
    }

    private static String stripFence(String raw) {
        String text = raw.strip();
        if (text.startsWith("```")) {
            text = text.replaceFirst("^```[a-zA-Z]*\\n?", "").replaceFirst("\\n?```$", "");
        }
        return text;
    }

    private static String truncate(String text, int max) {
        if (text == null) {
            return "";
        }
        String flat = text.replaceAll("\\s+", " ").strip();
        return flat.length() <= max ? flat : flat.substring(0, max) + "…";
    }
}
