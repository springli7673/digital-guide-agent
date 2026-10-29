package com.digitalguide.ai.graph;

import com.digitalguide.ai.intent.Intents;
import com.digitalguide.ai.prompt.PromptLoader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * 编排：parse → (追问) / retrieve → (出错) / score → answer。
 *
 * <p>Python 版是 LangGraph 的 StateGraph + 条件边；Java 版就是一段顺序代码 + 两个提前返回。
 * 少了一层框架，换来的是"流程一眼看得完、断点随便打、异常栈就是真栈"。
 * 代价要如实承认：失去了图的通用能力——动态加节点、拓扑可视化、跨节点的 checkpoint 回放。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatGraph {

    private final ParseNode parseNode;
    private final RetrieveNode retrieveNode;
    private final ScoreNode scoreNode;
    private final KnowledgeNode knowledgeNode;
    private final com.digitalguide.ai.agent.ToolAgent toolAgent;
    private final AnswerNode answerNode;

    /** 跑完一轮，事件全部通过 sink 推出。返回的 state 留给调用方/测试断言。 */
    public ChatState run(ChatState state, EventSink sink) {
        long started = System.nanoTime();
        try {
            state.recordTiming("parse", timed(() -> parseNode.run(state, sink)));
            if (state.getClarify() != null) {
                return state;
            }

            // 意图分流：问"知识"走 RAG，问"买什么"走商品检索，
            // 问"这两款比一下 / 某款详细参数"走工具模式（多步、需要模型自己组合）。
            // 三条路的判据完全不同（语义相似度 / 价格谓词 / 工具调用），混在一起会互相污染。
            if (state.isKnowledgeQuery()) {
                state.recordTiming("knowledge", timed(() -> knowledgeNode.run(state, sink)));
                state.recordTiming("answer", timed(() -> answerNode.run(state, sink)));
                return state;
            }

            if (state.isFollowupQuery()) {
                state.recordTiming("tool", timed(() -> toolAgent.run(state, sink)));
                return state;
            }

            state.recordTiming("retrieve", timed(() -> retrieveNode.run(state, sink)));
            if (state.getError() != null) {
                return state;
            }

            state.recordTiming("score", timed(() -> scoreNode.run(state, sink)));
            state.recordTiming("answer", timed(() -> answerNode.run(state, sink)));
            return state;
        } catch (RuntimeException e) {
            // 图内部异常也要以事件形式告诉前端，别让它只看到连接断开
            log.error("Agent 执行失败", e);
            sink.emit("error", Map.of("msg", "Agent 执行失败：" + e.getMessage()));
            state.setError(e.getMessage());
            return state;
        } finally {
            long elapsedMs = (System.nanoTime() - started) / 1_000_000;
            sink.emit("done", donePayload(state, elapsedMs));
        }
    }

    /** 跑一个节点并返回耗时（毫秒）；把埋点压成一行，不干扰主流程的可读性 */
    private static long timed(Runnable action) {
        long start = System.nanoTime();
        action.run();
        return (System.nanoTime() - start) / 1_000_000;
    }

    /**
     * done 事件只保证有 latencyMs（前端只读这个）；附带 sources 是纯增量，
     * 前端不认识就忽略，认识就能做引用面板。
     */
    private static Map<String, Object> donePayload(ChatState state, long elapsedMs) {        Map<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("latencyMs", elapsedMs);
        if (!state.getKbChunks().isEmpty()) {
            java.util.List<Map<String, Object>> sources = new java.util.ArrayList<>();
            int index = 1;
            for (com.digitalguide.ai.rag.KbChunk chunk : state.getKbChunks()) {
                Map<String, Object> source = new java.util.LinkedHashMap<>();
                source.put("n", index++);
                source.put("label", chunk.label());
                source.put("score", Math.round(chunk.score() * 100) / 100.0);
                sources.add(source);
            }
            payload.put("sources", sources);
        }
        return payload;
    }

    /** 给"只想拿结果、不关心流"的调用方（评测、单测）用：把事件收进一个列表 */
    public List<String> runAndCollectEvents(ChatState state) {
        List<String> events = new java.util.ArrayList<>();
        run(state, (event, data) -> events.add(event));
        return events;
    }

    /** 供日志/调试：一句话描述当前意图 */
    static String describeIntent(ChatState state) {
        if (state.getIntent() == null) {
            return "(no intent)";
        }
        return state.getIntent().categoryLabel() + " / " + Intents.priceRangeText(state.getIntent())
                + " / " + Intents.describePrefs(state.getIntent());
    }

    /** 提示词是否装载成功（启动自检用） */
    public static void assertPrompts(PromptLoader prompts) {
        for (String name : List.of("parse", "answer")) {
            String content = prompts.load(name);
            if (content.isBlank()) {
                throw new IllegalStateException("提示词 prompts/" + name + ".txt 为空或未打包");
            }
        }
    }
}
