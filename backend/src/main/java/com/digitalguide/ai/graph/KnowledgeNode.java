package com.digitalguide.ai.graph;

import com.digitalguide.ai.rag.EvidenceGate;
import com.digitalguide.ai.rag.KbChunk;
import com.digitalguide.ai.rag.KbReranker;
import com.digitalguide.ai.rag.KbRetriever;
import com.digitalguide.ai.rag.RagProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * 知识型问题的检索节点：双路召回 → 精排 → 证据闸门 → 取 topK。
 *
 * <p>和商品的 {@link RetrieveNode} 是两条独立的路：
 * 一个查数据库里的结构化参数，一个查向量库里的散文。混在一起会让"预算 3000"这种
 * 硬条件被语义相似度污染，所以显式按意图分流。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KnowledgeNode {

    private final KbRetriever retriever;
    private final KbReranker reranker;
    private final RagProperties properties;

    public void run(ChatState state, EventSink sink) {
        String question = state.getMessage();
        sink.emit("status", Map.of("stage", "searching",
                "text", "在选购知识库里检索相关资料…"));

        List<KbChunk> candidates = retriever.retrieve(question);
        if (candidates.isEmpty()) {
            sink.emit("status", Map.of("stage", "searching",
                    "text", "知识库里没有检索到相关内容"));
            state.setKbChunks(List.of());
            return;
        }

        KbReranker.RerankResult reranked = reranker.rerank(question, candidates);
        List<KbChunk> top = reranked.chunks().size() > properties.getTopK()
                ? reranked.chunks().subList(0, properties.getTopK())
                : reranked.chunks();

        if (reranked.reliable()) {
            // 只有真精排分了才过闸门；降级时分数不可信，硬套阈值会把能用的资料丢掉
            int before = top.size();
            top = EvidenceGate.apply(top, properties.getMinRerankScore());
            if (top.isEmpty()) {
                log.info("证据闸门拦截：最高精排分低于 {}，整批丢弃（原 {} 条）",
                        properties.getMinRerankScore(), before);
                sink.emit("status", Map.of("stage", "searching",
                        "text", "检索到的资料与问题相关性不足，已丢弃"));
            }
        }

        state.setKbChunks(top);
        if (!top.isEmpty()) {
            log.info("知识检索完成：{} 条进提示词（首条 {}）", top.size(), top.get(0).label());
        }
    }
}
