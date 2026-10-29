package com.digitalguide.ai.llm;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 模型配置：一个 provider 开关 + 两套端点。
 *
 * <p>不引 Spring AI / LangChain4j，直接用 JDK 的 {@link java.net.http.HttpClient}
 * 对接 OpenAI 兼容协议。理由：DeepSeek 和 Ollama 都是 OpenAI 兼容接口，
 * 一层薄封装就能覆盖，少一个依赖就少一处版本冲突（顺带也符合 ragent 当年的选择）。
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.llm")
public class LlmProperties {

    /** deepseek | ollama，决定 active() 返回哪一端 */
    private String provider = "deepseek";
    private Endpoint deepseek = new Endpoint();
    private Endpoint ollama = new Endpoint();

    /** 解析节点：温度 0，要的是稳定结构不是文采 */
    private double routerTemperature = 0.0;
    private int routerMaxTokens = 700;
    /** 回答节点：温度 0.3，要一点口语感 */
    private double answerTemperature = 0.3;
    private int answerMaxTokens = 900;

    private int connectTimeoutSeconds = 10;
    private int readTimeoutSeconds = 90;

    public Endpoint active() {
        return "ollama".equalsIgnoreCase(provider) ? ollama : deepseek;
    }

    public LlmRequest routerRequest(String system, String user) {
        return new LlmRequest(system, user, routerTemperature, routerMaxTokens, true);
    }

    public LlmRequest answerRequest(String system, String user) {
        return new LlmRequest(system, user, answerTemperature, answerMaxTokens, false);
    }

    @Data
    public static class Endpoint {
        /** 不带 /chat/completions；带不带 /v1 都可以，客户端会自己补 */
        private String baseUrl = "";
        private String apiKey = "";
        private String chatModel = "";
        /** Ollama 兼容端对 response_format 支持不一，可关掉只靠 prompt 约束 */
        private boolean jsonMode = true;
    }
}
