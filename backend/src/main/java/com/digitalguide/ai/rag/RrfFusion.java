package com.digitalguide.ai.rag;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 倒数名次融合（Reciprocal Rank Fusion）。
 *
 * <p>为什么需要它：向量分是余弦（0~1），关键词分是 trgm 相似度（0~1 但量纲不同），
 * 两路分数不可直接相加。RRF 只看名次，天然跨模态可比：
 *
 * <pre>score(chunk) = Σ_channel  weight / (k + rank)</pre>
 *
 * <p><b>k 取 20 不取论文默认的 60</b>：我们的候选池通常只有 20~40 条，
 * k=60 会把名次差异压得过平，头部没有区分度。这个值是 ragent 那套配置里
 * 明确写了理由的一处（"配合检索归因日志校准"），照抄了它的判断。
 */
public final class RrfFusion {

    public static final int DEFAULT_K = 20;

    private final int k;
    private final Map<String, Double> channelWeights;

    public RrfFusion() {
        this(DEFAULT_K, Map.of());
    }

    /**
     * @param k              平滑常数，越大名次差异越小
     * @param channelWeights 各通道权重，缺省 1.0
     */
    public RrfFusion(int k, Map<String, Double> channelWeights) {
        if (k <= 0) {
            throw new IllegalArgumentException("k 必须为正");
        }
        this.k = k;
        this.channelWeights = channelWeights == null ? Map.of() : Map.copyOf(channelWeights);
    }

    /**
     * @param channels 通道名 → 该通道按相关度降序的候选
     * @return 融合后按分数降序、已去重（按 id）的候选
     */
    public List<KbChunk> fuse(Map<String, List<KbChunk>> channels) {
        if (channels == null || channels.isEmpty()) {
            return List.of();
        }
        Map<Long, KbChunk> byId = new LinkedHashMap<>();
        Map<Long, Double> scores = new LinkedHashMap<>();

        channels.forEach((channel, hits) -> {
            if (hits == null) {
                return;
            }
            double weight = channelWeights.getOrDefault(channel, 1.0);
            for (int rank = 0; rank < hits.size(); rank++) {
                KbChunk hit = hits.get(rank);
                byId.putIfAbsent(hit.id(), hit);
                scores.merge(hit.id(), weight / (k + rank + 1), Double::sum);
            }
        });

        List<KbChunk> fused = new ArrayList<>(byId.size());
        byId.forEach((id, chunk) -> fused.add(chunk.withScore(scores.getOrDefault(id, 0.0))));
        fused.sort((a, b) -> Double.compare(b.score(), a.score()));
        return fused;
    }

    /** 截断到前 n 条（送精排的候选池上限） */
    public static List<KbChunk> truncate(List<KbChunk> chunks, int limit) {
        if (limit <= 0 || chunks.size() <= limit) {
            return chunks;
        }
        return List.copyOf(chunks.subList(0, limit));
    }
}
