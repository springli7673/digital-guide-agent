package com.digitalguide.ai.rag;

import java.util.List;

/**
 * 证据闸门。
 *
 * <p>检索的天然缺陷是：它保证返回"最像的 N 条"，但库里**根本没有答案**时也照样满额返回。
 * 于是模型拿到一堆无关片段，仍然会被要求"根据资料回答"——这就是 RAG 幻觉的最大来源。
 *
 * <p>这里补一道相关度下限：整批的最高精排分都低于阈值，说明这批资料不值得用，
 * 整批丢掉，让上层如实回答"我这里没有这个信息"。
 *
 * <p>阈值随 rerank 模型而变，换模型必须重测（ragent 的做法是打"检索归因 - 精排分布"日志）。
 */
public final class EvidenceGate {

    private EvidenceGate() {
    }

    /**
     * @param chunks   已按相关度降序
     * @param minScore 最低可接受分，<=0 表示不设闸门
     * @return 通过闸门的全量，或空列表
     */
    public static List<KbChunk> apply(List<KbChunk> chunks, double minScore) {
        if (chunks == null || chunks.isEmpty()) {
            return List.of();
        }
        if (minScore <= 0) {
            return chunks;
        }
        double best = chunks.stream().mapToDouble(KbChunk::score).max().orElse(0);
        return best < minScore ? List.of() : chunks;
    }
}
