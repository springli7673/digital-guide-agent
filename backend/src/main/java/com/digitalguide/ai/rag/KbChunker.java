package com.digitalguide.ai.rag;

import java.util.ArrayList;
import java.util.List;

/**
 * 标题感知的分块器。
 *
 * <p>为什么不按固定字数硬切：选购指南的信息是按小节组织的（"PWM 调光"、"快充协议"…），
 * 硬切会把一个小节劈成两半，检索回来的片段既答不全也说不清出处。
 * 这里先按 markdown 标题切成小节，再在小节内部按段落打包，超过 maxChars 才二次切分。
 *
 * <p>目标是"一个块 ≈ 一个完整的小论点"：太大检索不精准，太小上下文丢失。
 */
public final class KbChunker {

    /** 目标块大小（字符）。中文按字符算，420 字大约 300 token */
    public static final int DEFAULT_MAX_CHARS = 420;
    /** 相邻块的重叠，避免一句话被切断后两边都读不懂 */
    public static final int DEFAULT_OVERLAP = 80;

    private final int maxChars;
    private final int overlap;

    public KbChunker() {
        this(DEFAULT_MAX_CHARS, DEFAULT_OVERLAP);
    }

    public KbChunker(int maxChars, int overlap) {
        if (maxChars <= 0) {
            throw new IllegalArgumentException("maxChars 必须为正");
        }
        if (overlap < 0 || overlap >= maxChars) {
            throw new IllegalArgumentException("overlap 必须在 [0, maxChars) 之间");
        }
        this.maxChars = maxChars;
        this.overlap = overlap;
    }

    /**
     * @param docTitle 文档标题（取自文件名或一级标题）
     * @param markdown  原文
     * @return 按顺序排好的块；不产生空白块
     */
    public List<KbChunk> chunk(String docTitle, String markdown) {
        List<KbChunk> chunks = new ArrayList<>();
        if (markdown == null || markdown.isBlank()) {
            return chunks;
        }

        String currentHeading = docTitle;
        StringBuilder body = new StringBuilder();

        for (String rawLine : markdown.split("\\R", -1)) {
            String line = rawLine.strip();
            if (isHeading(line)) {
                // 先落盘上一节，再换标题
                flush(docTitle, currentHeading, body, chunks);
                body.setLength(0);
                currentHeading = stripHeadingMark(line);
                continue;
            }
            if (line.isEmpty()) {
                // 段落分隔保留一个空行，让后面的打包能按段落断开
                body.append('\n').append('\n');
                continue;
            }
            body.append(line).append('\n');
        }
        flush(docTitle, currentHeading, body, chunks);
        return chunks;
    }

    /** 把一节正文按段落打包成若干块 */
    private void flush(String docTitle, String heading, StringBuilder body, List<KbChunk> out) {
        String text = body.toString().replaceAll("\\n{3,}", "\n\n").strip();
        if (text.isEmpty()) {
            return;
        }
        // 表格整体不切：切开的表格行毫无意义
        if (looksLikeTable(text) && text.length() <= maxChars * 2) {
            out.add(new KbChunk(0, docTitle, heading, text, 0));
            return;
        }
        int start = 0;
        while (start < text.length()) {
            int end = Math.min(start + maxChars, text.length());
            if (end < text.length()) {
                end = breakPoint(text, start, end);
            }
            String piece = text.substring(start, end).strip();
            if (!piece.isEmpty()) {
                out.add(new KbChunk(0, docTitle, heading, piece, 0));
            }
            if (end >= text.length()) {
                break;
            }
            start = Math.max(end - overlap, start + 1);
        }
    }

    /**
     * 找一个"像样的"断点：优先段落结尾，其次句号，再次逗号；都找不到就硬切。
     * 从 end 往前找，最多回退 40% 的窗口——回退太多会让块大小失控。
     */
    private int breakPoint(String text, int start, int end) {
        int floor = start + (int) ((end - start) * 0.6);
        int paragraph = text.lastIndexOf("\n\n", end);
        if (paragraph > floor) {
            return paragraph;
        }
        for (String mark : new String[]{"。", "！", "？", "；", "\n"}) {
            int index = text.lastIndexOf(mark, end);
            if (index > floor) {
                return index + mark.length();
            }
        }
        return end;
    }

    private static boolean isHeading(String line) {
        return line.startsWith("#");
    }

    private static String stripHeadingMark(String line) {
        return line.replaceFirst("^#+\\s*", "").strip();
    }

    private static boolean looksLikeTable(String text) {
        long pipeLines = text.lines().filter(l -> l.strip().startsWith("|")).count();
        return pipeLines >= 2;
    }
}
