package com.digitalguide.ai.rag;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * 双路召回 + RRF 融合。
 *
 * <p>两路各管一件事，互补得很清楚：
 * <ul>
 *   <li><b>向量路</b>：语义相近就算命中，"手机发烫"能召回"散热"那段；</li>
 *   <li><b>关键词路</b>：精确词命中，型号、协议名、专有名词（PD3.1、LTPO）靠它。</li>
 * </ul>
 * 纯向量对专有名词很弱，纯关键词对同义表达很弱，所以要两路。
 *
 * <p><b>关键词路为什么用 pg_trgm 而不是 tsvector</b>：PostgreSQL 自带的分词器不认识中文，
 * {@code to_tsvector('simple', '手机发烫怎么办')} 会把整句当一个词，几乎召不回任何东西。
 * 装 zhparser 能解决，但那是要编译的扩展。先用三元组相似度顶住，够用且零扩展依赖；
 * 上量之后再换 zhparser 或 ES+IK。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KbRetriever {

    private final JdbcTemplate jdbc;
    private final KbEmbeddingService embeddingService;
    private final RagProperties properties;

    /** 返回融合后、已截断到候选池上限的结果 */
    public List<KbChunk> retrieve(String question) {
        if (question == null || question.isBlank()) {
            return List.of();
        }
        List<KbChunk> vectorHits = safe(() -> vectorSearch(question), "向量路");
        List<KbChunk> keywordHits = safe(() -> keywordSearch(question), "关键词路");

        Map<String, List<KbChunk>> channels = new LinkedHashMap<>();
        if (!vectorHits.isEmpty()) {
            channels.put("vector", vectorHits);
        }
        if (!keywordHits.isEmpty()) {
            channels.put("keyword", keywordHits);
        }
        if (channels.isEmpty()) {
            return List.of();
        }

        RrfFusion fusion = new RrfFusion(properties.getRrfK(), properties.getChannelWeights());
        List<KbChunk> fused = fusion.fuse(channels);
        List<KbChunk> truncated = RrfFusion.truncate(fused, properties.getRerankCandidateLimit());

        // 检索归因：哪一路贡献了多少、截断掉了多少，出了问题先看这行
        log.info("检索融合：向量 {} 条 / 关键词 {} 条 → 融合去重 {} 条 → 送精排 {} 条",
                vectorHits.size(), keywordHits.size(), fused.size(), truncated.size());
        return truncated;
    }

    private List<KbChunk> vectorSearch(String question) {
        float[] vector = embeddingService.embed(question);
        String literal = KbEmbeddingService.toVectorLiteral(vector);
        String sql = """
                SELECT id, doc_title, heading, content,
                       1 - (embedding <=> ?::vector) AS score
                FROM ai.kb_chunk
                ORDER BY embedding <=> ?::vector
                LIMIT ?
                """;
        return jdbc.query(sql, (rs, rowNum) -> new KbChunk(
                        rs.getLong("id"),
                        rs.getString("doc_title"),
                        rs.getString("heading"),
                        rs.getString("content"),
                        rs.getDouble("score")),
                literal, literal, properties.getRecallBudget());
    }

    /**
     * 三元组相似度排序。阈值取很低（0.05）是故意的：
     * 这一路的价值在于"把精确命中的捞上来"，不该因为阈值过严而漏掉，
     * 真正的相关性判断交给后面的精排和证据闸门。
     */
    private List<KbChunk> keywordSearch(String question) {
        String sql = """
                SELECT id, doc_title, heading, content,
                       word_similarity(?, content) AS score
                FROM ai.kb_chunk
                WHERE word_similarity(?, content) > 0.05
                ORDER BY score DESC
                LIMIT ?
                """;
        return jdbc.query(sql, (rs, rowNum) -> new KbChunk(
                        rs.getLong("id"),
                        rs.getString("doc_title"),
                        rs.getString("heading"),
                        rs.getString("content"),
                        rs.getDouble("score")),
                question, question, properties.getRecallBudget());
    }

    /** 单路失败不该拖垮整次检索：向量库没建好、pg_trgm 没装，都退化成单路 */
    private List<KbChunk> safe(Supplier<List<KbChunk>> supplier, String channel) {
        try {
            return supplier.get();
        } catch (Exception e) {
            log.warn("{} 召回失败，本次退化为单路：{}", channel, e.getMessage());
            return List.of();
        }
    }
}
