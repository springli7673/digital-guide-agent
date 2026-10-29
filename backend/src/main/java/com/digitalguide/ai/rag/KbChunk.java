package com.digitalguide.ai.rag;

/**
 * 一条知识片段。{@code source} 是文档标题 + 小标题，用于回答里的引用角标 [1][2]。
 */
public record KbChunk(
        long id,
        String docTitle,
        String heading,
        String content,
        double score
) {

    public KbChunk withScore(double newScore) {
        return new KbChunk(id, docTitle, heading, content, newScore);
    }

    /** 引用角标里展示的名字 */
    public String label() {
        return heading == null || heading.isBlank() ? docTitle : docTitle + " · " + heading;
    }
}
