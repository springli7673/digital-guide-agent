package com.digitalguide.ai.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 向量化配置，单独一组。
 *
 * <p>为什么和 chat 分开：DeepSeek **没有 embedding 接口**，所以最实际的组合是
 * "对话走云端、向量化走本地 Ollama"。这个不对称是有意为之，不是遗漏——
 * 顺便还是个合规叙事：原始文档不出本机，只有"问题 + 召回的片段"出网。
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.embedding")
public class EmbeddingProperties {

    private String baseUrl = "http://127.0.0.1:11434";
    /** Ollama 的 OpenAI 兼容端点不需要 key，但 DeepSeek 之外的服务可能要 */
    private String apiKey = "";
    private String model = "bge-m3";
    /** bge-m3 是 1024 维；改模型要同步改 DDL 里的 vector(1024) */
    private int dimensions = 1024;
}
