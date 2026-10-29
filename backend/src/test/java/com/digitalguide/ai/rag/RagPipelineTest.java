package com.digitalguide.ai.rag;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RAG 里三段纯逻辑的回归测试：分块、RRF 融合、证据闸门。
 *
 * <p>这三块都不碰数据库和模型，所以能被钉死；接上 pgvector 和 Ollama 之后
 * 出问题，先看这里是不是还绿。
 */
class RagPipelineTest {

    // ------------------------------------------------------------------ 分块

    @Test
    @DisplayName("按标题切小节，不产生空块，块上带小节名")
    void chunkByHeading() {
        String markdown = """
                # 电池与续航

                引言：mAh 只是起点。

                ## 影响续航的因素

                屏幕功耗是第一大项。

                ## 常见误解

                电池大不等于耐用。
                """;

        List<KbChunk> chunks = new KbChunker().chunk("电池与续航", markdown);

        assertThat(chunks).isNotEmpty();
        assertThat(chunks).allSatisfy(chunk -> {
            assertThat(chunk.content()).isNotBlank();
            assertThat(chunk.docTitle()).isEqualTo("电池与续航");
        });
        // 第一个标题之前的引言、以及两个小节，都应有各自的 heading
        assertThat(chunks).extracting(KbChunk::heading)
                .contains("电池与续航", "影响续航的因素", "常见误解");
    }

    @Test
    @DisplayName("超长小节按句号断开，并保留重叠，避免句子被劈两半")
    void longSectionSplitsWithOverlap() {
        StringBuilder body = new StringBuilder("## 长小节\n\n");
        for (int i = 0; i < 30; i++) {
            body.append("这是第").append(i).append("句用于测试分块的话，长度要足够才会触发切分。");
        }
        KbChunker chunker = new KbChunker(200, 40);
        List<KbChunk> chunks = chunker.chunk("长文", body.toString());

        assertThat(chunks.size()).isGreaterThan(1);
        assertThat(chunks).allSatisfy(chunk -> {
            assertThat(chunk.content().length()).isLessThanOrEqualTo(220);
            // 不用在句号中间截断
            assertThat(chunk.content()).doesNotEndWith("第");
        });
    }

    @Test
    @DisplayName("表格整体保留，不从中间切开")
    void tableIsNotSplit() {
        String markdown = """
                ## 对照表

                | 协议 | 功率 |
                |---|---|
                | PD | 240W |
                | QC | 100W |
                """;
        List<KbChunk> chunks = new KbChunker(60, 10).chunk("表格", markdown);

        assertThat(chunks).hasSize(1);
        assertThat(chunks.get(0).content()).contains("| PD | 240W |");
    }

    // ------------------------------------------------------------------ RRF

    @Test
    @DisplayName("两路都命中的片段排第一，单路命中的按名次排后面")
    void rrfPrefersChunksHitByBothChannels() {
        KbChunk a = new KbChunk(1, "文档", "A", "内容 A", 0);
        KbChunk b = new KbChunk(2, "文档", "B", "内容 B", 0);
        KbChunk c = new KbChunk(3, "文档", "C", "内容 C", 0);

        Map<String, List<KbChunk>> channels = new LinkedHashMap<>();
        // 向量路：a 第一，c 第二
        channels.put("vector", List.of(a, c));
        // 关键词路：b 第一，a 第二
        channels.put("keyword", List.of(b, a));

        List<KbChunk> fused = new RrfFusion(20, Map.of()).fuse(channels);

        assertThat(fused).hasSize(3);
        // a 两路都命中（1/21 + 1/22），分数最高
        assertThat(fused.get(0).id()).isEqualTo(1L);
        assertThat(fused.get(0).score()).isGreaterThan(fused.get(1).score());
    }

    @Test
    @DisplayName("通道权重能改变话语权")
    void channelWeightChangesRanking() {
        KbChunk vectorOnly = new KbChunk(1, "文档", "A", "x", 0);
        KbChunk keywordOnly = new KbChunk(2, "文档", "B", "y", 0);

        Map<String, List<KbChunk>> channels = new LinkedHashMap<>();
        channels.put("vector", List.of(vectorOnly));
        channels.put("keyword", List.of(keywordOnly));

        List<KbChunk> keywordHeavy = new RrfFusion(20, Map.of("vector", 0.5, "keyword", 2.0)).fuse(channels);
        assertThat(keywordHeavy.get(0).id()).isEqualTo(2L);

        List<KbChunk> vectorHeavy = new RrfFusion(20, Map.of("vector", 2.0, "keyword", 0.5)).fuse(channels);
        assertThat(vectorHeavy.get(0).id()).isEqualTo(1L);
    }

    @Test
    @DisplayName("截断只留下前 N 条")
    void truncate() {
        List<KbChunk> chunks = List.of(
                new KbChunk(1, "d", "h", "c", 0.9),
                new KbChunk(2, "d", "h", "c", 0.5),
                new KbChunk(3, "d", "h", "c", 0.1));
        assertThat(RrfFusion.truncate(chunks, 2)).hasSize(2);
        assertThat(RrfFusion.truncate(chunks, 0)).hasSize(3);
    }

    // ------------------------------------------------------------------ 闸门

    @Test
    @DisplayName("最高分低于阈值时整批丢弃——库里没答案就该承认没有")
    void gateDropsWholeBatchWhenTooWeak() {
        List<KbChunk> chunks = List.of(
                new KbChunk(1, "d", "h", "c", 0.15),
                new KbChunk(2, "d", "h", "c", 0.10));

        assertThat(EvidenceGate.apply(chunks, 0.2)).isEmpty();
        assertThat(EvidenceGate.apply(chunks, 0.1)).hasSize(2);
        // 0 表示不设闸门
        assertThat(EvidenceGate.apply(chunks, 0)).hasSize(2);
        assertThat(EvidenceGate.apply(List.of(), 0.2)).isEmpty();
    }

    // ------------------------------------------------------------------ 向量字面量

    @Test
    @DisplayName("向量字面量是 pgvector 认识的 '[a,b,c]' 形式")
    void vectorLiteral() {
        assertThat(KbEmbeddingService.toVectorLiteral(new float[]{0.1f, -0.25f, 3f}))
                .isEqualTo("[0.1,-0.25,3.0]");
    }
}
