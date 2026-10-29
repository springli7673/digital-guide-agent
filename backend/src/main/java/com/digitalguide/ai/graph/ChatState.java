package com.digitalguide.ai.graph;

import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.scoring.SpecSchema;

import java.util.List;
import java.util.Map;

/**
 * 图的状态。
 *
 * <p>Python 版是 TypedDict + LangGraph 的 channel 机制；Java 版退化成一个可变的上下文对象。
 * 这是刻意的取舍：换来的是"没有框架、分支写在明面上、断点就在 run() 里"，
 * 代价是失去了图的通用性（比如动态加节点、可视化拓扑）。
 *
 * <p>状态里只放数据，不放 IO——节点自己持有依赖，状态只被读写。
 */
public class ChatState {

    // 输入
    private final String message;
    private final String sessionId;
    private final List<ChatMessage> history;
    private final int clarifyCount;

    // parse
    private Intent intent;

    // retrieve
    private List<Map<String, Object>> candidates = List.of();

    // score
    private List<Map<String, Object>> ranked = List.of();
    private Map<String, SpecSchema.Dim> schema = Map.of();

    // answer
    private String answer = "";

    // 知识型问题：RAG 召回的片段（商品推荐路径下为空）
    private List<com.digitalguide.ai.rag.KbChunk> kbChunks = List.of();

    /** 生成后护栏发现的违例（型号/价格不在候选里），为空表示没发现问题 */
    private String guardViolation;

    /** 各节点耗时（毫秒），用于 trace */
    private final Map<String, Long> nodeTimings = new java.util.LinkedHashMap<>();

    /** 被压缩掉的历史摘要（记忆层给的，可能为空） */
    private String summary = "";

    /** 槽位锚点：上一轮确认过的预算/偏好/品牌，历史被压缩也不会丢 */
    private Map<String, Object> anchor = Map.of();

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary == null ? "" : summary;
    }

    public Map<String, Object> getAnchor() {
        return anchor;
    }

    public void setAnchor(Map<String, Object> anchor) {
        this.anchor = anchor == null ? Map.of() : anchor;
    }

    public void recordTiming(String node, long millis) {
        nodeTimings.merge(node, millis, Long::sum);
    }

    public Map<String, Long> getNodeTimings() {
        return nodeTimings;
    }

    public String getGuardViolation() {
        return guardViolation;
    }

    public void setGuardViolation(String guardViolation) {
        this.guardViolation = guardViolation;
    }

    // 提前结束的分支
    private Map<String, Object> clarify;
    private String error;

    public ChatState(String message, String sessionId, List<ChatMessage> history, int clarifyCount) {
        this.message = message;
        this.sessionId = sessionId == null || sessionId.isBlank() ? "anonymous" : sessionId;
        this.history = history == null ? List.of() : List.copyOf(history);
        this.clarifyCount = clarifyCount;
    }

    public String getMessage() {
        return message;
    }

    public String getSessionId() {
        return sessionId;
    }

    public List<ChatMessage> getHistory() {
        return history;
    }

    public int getClarifyCount() {
        return clarifyCount;
    }

    public Intent getIntent() {
        return intent;
    }

    public void setIntent(Intent intent) {
        this.intent = intent;
    }

    public List<Map<String, Object>> getCandidates() {
        return candidates;
    }

    public void setCandidates(List<Map<String, Object>> candidates) {
        this.candidates = candidates == null ? List.of() : candidates;
    }

    public List<Map<String, Object>> getRanked() {
        return ranked;
    }

    public void setRanked(List<Map<String, Object>> ranked) {
        this.ranked = ranked == null ? List.of() : ranked;
    }

    public Map<String, SpecSchema.Dim> getSchema() {
        return schema;
    }

    public void setSchema(Map<String, SpecSchema.Dim> schema) {
        this.schema = schema == null ? Map.of() : schema;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer == null ? "" : answer;
    }

    public Map<String, Object> getClarify() {
        return clarify;
    }

    public void setClarify(Map<String, Object> clarify) {
        this.clarify = clarify;
    }

    public List<com.digitalguide.ai.rag.KbChunk> getKbChunks() {
        return kbChunks;
    }

    public void setKbChunks(List<com.digitalguide.ai.rag.KbChunk> kbChunks) {
        this.kbChunks = kbChunks == null ? List.of() : List.copyOf(kbChunks);
    }

    /** 走知识库路径（由 parse 出的 category 决定） */
    public boolean isKnowledgeQuery() {
        return intent != null && "knowledge".equals(intent.category());
    }

    /** 走工具模式（对比两款 / 查某款详情），由 parse 出的 category 决定 */
    public boolean isFollowupQuery() {
        return intent != null && "followup".equals(intent.category());
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }
}
