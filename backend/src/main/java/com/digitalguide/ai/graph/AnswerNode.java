package com.digitalguide.ai.graph;

import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.intent.Intents;
import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.ai.prompt.PromptLoader;
import com.digitalguide.ai.scoring.ScoringService;
import com.digitalguide.ai.scoring.SpecSchema;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * answer：把打分结果讲成人话，边生成边推 token。
 *
 * <p>硬约束靠两件事保证：
 * 一是 prompt 里明确"只能用候选里的型号和价格"；
 * 二是<b>模型根本拿不到候选以外的数据</b>——它看到的 user prompt 就是候选清单本身。
 * 程序化的幻觉校验（型号/价格 ⊆ 候选）留给后面的护栏组件，这一层先保证"喂进去的就是对的"。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AnswerNode {

    private final LlmClient llm;
    private final LlmProperties llmProperties;
    private final PromptLoader prompts;

    public void run(ChatState state, EventSink sink) {
        if (state.isKnowledgeQuery()) {
            runKnowledge(state, sink);
            return;
        }
        Intent intent = state.getIntent();
        List<Map<String, Object>> ranked = state.getRanked();

        sink.emit("status", Map.of("stage", "answering", "text", "组织推荐理由…"));

        if (ranked.isEmpty()) {
            String text = Intents.priceRangeText(intent)
                    + " 这个区间没有可推荐的型号，把预算放宽一点再问我一次。";
            sink.emit("token", Map.of("text", text));
            state.setAnswer(text);
            return;
        }

        String userPrompt = buildAnswerInput(state);
        StringBuilder answer = new StringBuilder();
        try {
            llm.stream(llmProperties.answerRequest(prompts.load("answer"), userPrompt), chunk -> {
                answer.append(chunk);
                sink.emit("token", Map.of("text", chunk));
            });
        } catch (Exception e) {
            log.warn("回答节点流式失败：{}", e.getMessage());
            if (answer.length() == 0) {
                // 一个字都没出来才用模板兜底；已经吐了一半就别把半截话删掉重发
                String fallback = fallbackAnswer(state);
                answer.append(fallback);
                sink.emit("token", Map.of("text", fallback));
            }
            sink.emit("status", Map.of("stage", "answering",
                    "text", "模型不可用，改用模板话术（" + e.getMessage() + "）"));
        }

        // 生成后护栏：prompt 里写"只能用候选"是请求，不是保证。
        // 发现候选外的型号/价格就补一句更正，并记进 trace —— 让"胡说率"变成可统计的指标。
        com.digitalguide.ai.guard.AnswerGuard.Violation violation =
                com.digitalguide.ai.guard.AnswerGuard.check(answer.toString(), ranked);
        if (!violation.isEmpty()) {
            String note = "\n\n（更正：上面提到的" + violation.describe()
                    + " 不在本次候选里，请以卡片上的信息为准。）";
            answer.append(note);
            sink.emit("token", Map.of("text", note));
            sink.emit("status", Map.of("stage", "guarding",
                    "text", "检测到候选以外的信息，已补更正"));
            state.setGuardViolation(violation.describe());
            log.warn("护栏拦截：{}", violation.describe());
        }
        state.setAnswer(answer.toString());
    }

    // -------------------------------------------------------------- 知识型回答

    /**
     * 知识型问题：只根据召回的资料作答，并标 [1][2] 角标。
     *
     * <p>资料为空时**不调模型**——没有资料还让模型"根据常识回答"，正是幻觉工厂。
     * 宁可说"我这边没有可靠资料"。
     */
    private void runKnowledge(ChatState state, EventSink sink) {
        sink.emit("status", Map.of("stage", "answering", "text", "整理资料并作答…"));

        if (state.getKbChunks().isEmpty()) {
            String text = "这个话题我这边没有可靠的资料，不想凭空给你一个说法。"
                    + "可以换个更具体的问法（比如具体机型、具体参数），或者直接问我推荐机型。";
            sink.emit("token", Map.of("text", text));
            state.setAnswer(text);
            return;
        }

        String userPrompt = buildKbInput(state);
        StringBuilder answer = new StringBuilder();
        try {
            llm.stream(llmProperties.answerRequest(prompts.load("answer_kb"), userPrompt), chunk -> {
                answer.append(chunk);
                sink.emit("token", Map.of("text", chunk));
            });
        } catch (Exception e) {
            log.warn("知识型回答失败：{}", e.getMessage());
            if (answer.length() == 0) {
                String fallback = kbFallback(state);
                answer.append(fallback);
                sink.emit("token", Map.of("text", fallback));
            }
            sink.emit("status", Map.of("stage", "answering", "text", "模型不可用，改用资料摘录兜底"));
        }
        state.setAnswer(answer.toString());
    }

    private static String buildKbInput(ChatState state) {
        StringBuilder builder = new StringBuilder();
        builder.append("【用户问题】\n").append(state.getMessage()).append("\n\n【参考资料】\n");
        int index = 1;
        for (com.digitalguide.ai.rag.KbChunk chunk : state.getKbChunks()) {
            builder.append('[').append(index++).append("] ").append(chunk.label()).append('\n')
                    .append(chunk.content()).append("\n\n");
        }
        return builder.toString();
    }

    /** 不依赖大模型的兜底：直接摘录资料要点 */
    private static String kbFallback(ChatState state) {
        StringBuilder builder = new StringBuilder("我这边资料里的要点：\n");
        int index = 1;
        for (com.digitalguide.ai.rag.KbChunk chunk : state.getKbChunks()) {
            String content = chunk.content().replaceAll("\\s+", " ").strip();
            String snippet = content.length() > 120 ? content.substring(0, 120) + "…" : content;
            builder.append('[').append(index++).append("] ").append(snippet)
                    .append("（").append(chunk.label()).append("）\n");
        }
        return builder.toString().trim();
    }

    // ------------------------------------------------------------------ 拼输入

    @SuppressWarnings("unchecked")
    static String buildAnswerInput(ChatState state) {
        Intent intent = state.getIntent();
        List<Map<String, Object>> ranked = state.getRanked();
        Map<String, SpecSchema.Dim> schema = state.getSchema();

        StringBuilder builder = new StringBuilder();
        builder.append("【筛选条件】品类：").append(intent.categoryLabel())
                .append("；预算：").append(Intents.priceRangeText(intent))
                .append("；重点：").append(Intents.describePrefs(intent))
                .append("；命中 ").append(state.getCandidates().size())
                .append(" 款，下面是打分后的前 ").append(ranked.size()).append(" 款。\n\n");
        builder.append("【候选商品】\n");

        int index = 1;
        for (Map<String, Object> item : ranked) {
            Object price = item.get("priceRef");
            String priceText = price == null
                    ? "暂无报价"
                    : "参考价 " + Intents.yuan((Number) price);
            builder.append(index++).append(". ")
                    .append(item.get("brand")).append(' ').append(item.get("model"))
                    .append("（").append(priceText)
                    .append("，得分 ").append(item.get("score")).append("）\n");
            builder.append("   参数：")
                    .append(metricsText((Map<String, Double>) item.get("metrics"), schema)).append('\n');
            Object reasons = item.get("reasons");
            if (reasons instanceof List<?> list && !list.isEmpty()) {
                builder.append("   优势：").append(String.join("；",
                        list.stream().map(String::valueOf).toList())).append('\n');
            }
        }
        if (!intent.usage().isBlank()) {
            builder.append("【用户场景】").append(intent.usage()).append('\n');
        }
        return builder.toString();
    }

    private static String metricsText(Map<String, Double> metrics, Map<String, SpecSchema.Dim> schema) {
        StringBuilder builder = new StringBuilder();
        for (Map.Entry<String, SpecSchema.Dim> entry : schema.entrySet()) {
            Double value = metrics.get(entry.getKey());
            if (value == null) {
                continue;
            }
            SpecSchema.Dim dim = entry.getValue();
            String label = "weight_g".equals(entry.getKey()) ? "重量" : dim.label();
            if (builder.length() > 0) {
                builder.append('；');
            }
            builder.append(label).append(' ').append(ScoringService.fmt(value)).append(dim.unit());
        }
        return builder.length() == 0 ? "参数缺失" : builder.toString();
    }

    // ------------------------------------------------------------------ 兜底

    /** 不依赖大模型的兜底话术：数据本身已经能说清结论 */
    static String fallbackAnswer(ChatState state) {
        Intent intent = state.getIntent();
        List<Map<String, Object>> ranked = state.getRanked();
        StringBuilder builder = new StringBuilder("按你的要求，这几款比较合适：\n");

        int index = 1;
        for (Map<String, Object> item : ranked) {
            Object price = item.get("priceRef");
            String priceText = price == null ? "暂无报价" : "参考价 " + Intents.yuan((Number) price);
            Object reasons = item.get("reasons");
            String reason = reasons instanceof List<?> list && !list.isEmpty()
                    ? String.join("；", list.stream().map(String::valueOf).toList())
                    : "参数较均衡";
            builder.append(index++).append(". ")
                    .append(item.get("brand")).append(' ').append(item.get("model"))
                    .append("（").append(priceText).append("）")
                    .append(reason).append("。\n");
        }
        return builder.toString().trim();
    }
}
