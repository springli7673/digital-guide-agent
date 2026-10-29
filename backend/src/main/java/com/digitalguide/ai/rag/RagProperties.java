package com.digitalguide.ai.rag;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * RAG 参数。
 *
 * <p>三段预算，各自独立、单调收窄——这是 ragent 那套配置里最值得抄的一个设计：
 *
 * <pre>
 *   recallBudget(20)  →  rerankCandidateLimit(40)  →  topK(5)
 *   每个通道召回多少条      融合后送精排的池子上限        最终进提示词的条数
 * </pre>
 *
 * <p>不这么分层，就会出现"检索召回 5 条、精排也只能在 5 条里挑"的自欺欺人。
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.rag")
public class RagProperties {

    /** ① 每个通道的召回条数 */
    private int recallBudget = 20;
    /** ② 融合后送精排的候选池上限 */
    private int rerankCandidateLimit = 40;
    /** ③ 最终进提示词的条数 */
    private int topK = 5;

    /** RRF 的 k；候选池只有几十条，取 20 比论文默认 60 更有区分度 */
    private int rrfK = 20;
    private Map<String, Double> channelWeights = defaultWeights();

    /** 精排：用 LLM 给"资料与问题的相关性"打 0~10 分，失败就退回 RRF 顺序 */
    private boolean rerankEnabled = true;
    /** 证据闸门：整批最高精排分（归一化到 0~1）低于此值就整批丢弃 */
    private double minRerankScore = 0.2;

    private int chunkSize = 420;
    private int chunkOverlap = 80;

    private static Map<String, Double> defaultWeights() {
        Map<String, Double> weights = new LinkedHashMap<>();
        weights.put("vector", 1.0);
        weights.put("keyword", 1.0);
        return weights;
    }
}
