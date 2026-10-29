package com.digitalguide.ai.rag;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * 知识库入库：读 {@code classpath:kb/*.md} → 分块 → 向量化 → 写 pgvector。
 *
 * <p>幂等策略是"按文档整篇替换"：同一 doc_title 先删后插。
 * 不做增量 diff——十来篇选购指南，全量重建的成本比维护一套 diff 逻辑低得多，
 * 而且不会出现"旧块残留导致检索到已删内容"这种脏数据。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KbIngestor {

    private final JdbcTemplate jdbc;
    private final KbEmbeddingService embeddingService;
    private final RagProperties properties;

    public record IngestResult(int docs, int chunks, List<String> titles) {
    }

    public IngestResult ingest() throws IOException {
        Resource[] resources = new PathMatchingResourcePatternResolver()
                .getResources("classpath*:kb/*.md");
        if (resources.length == 0) {
            log.warn("classpath:kb/ 下没有 .md 语料，跳过入库");
            return new IngestResult(0, 0, List.of());
        }

        KbChunker chunker = new KbChunker(properties.getChunkSize(), properties.getChunkOverlap());
        List<String> titles = new ArrayList<>();
        int totalChunks = 0;

        for (Resource resource : resources) {
            String markdown = read(resource);
            String title = titleOf(resource, markdown);
            List<KbChunk> chunks = chunker.chunk(title, markdown);
            if (chunks.isEmpty()) {
                continue;
            }
            titles.add(title);

            jdbc.update("DELETE FROM ai.kb_chunk WHERE doc_title = ?", title);
            for (KbChunk chunk : chunks) {
                float[] vector = embeddingService.embed(chunk.content());
                jdbc.update("""
                                INSERT INTO ai.kb_chunk (doc_title, heading, content, embedding)
                                VALUES (?, ?, ?, ?::vector)
                                """,
                        chunk.docTitle(), chunk.heading(), chunk.content(),
                        KbEmbeddingService.toVectorLiteral(vector));
            }
            totalChunks += chunks.size();
            log.info("入库《{}》：{} 块", title, chunks.size());
        }

        log.info("知识库入库完成：{} 篇 / {} 块", titles.size(), totalChunks);
        return new IngestResult(titles.size(), totalChunks, titles);
    }

    private String read(Resource resource) throws IOException {
        try (InputStream in = resource.getInputStream()) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    /** 优先取一级标题，取不到就用文件名 */
    private String titleOf(Resource resource, String markdown) {
        for (String line : markdown.split("\\R")) {
            String stripped = line.strip();
            if (stripped.startsWith("# ")) {
                return stripped.substring(2).strip();
            }
        }
        String filename = resource.getFilename();
        return filename == null ? "未命名文档" : filename.replaceFirst("\\.md$", "");
    }
}
