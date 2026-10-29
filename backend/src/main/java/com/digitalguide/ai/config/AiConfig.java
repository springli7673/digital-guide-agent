package com.digitalguide.ai.config;

import com.digitalguide.ai.llm.LlmProperties;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.document.MetadataMode;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.ai.openai.OpenAiEmbeddingModel;
import org.springframework.ai.openai.OpenAiEmbeddingOptions;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 按配置装配一个 ChatModel 和一个 EmbeddingModel。
 *
 * <p>对话和向量化是**两套端点**，这是有意的：
 * <ul>
 *   <li>chat：DeepSeek 云端（也可以用 Ollama 本地）；</li>
 *   <li>embedding：只能本地，因为 DeepSeek 没有 embedding 接口，而 bge-m3 在 Ollama 上就够了。</li>
 * </ul>
 * Ollama 也提供 OpenAI 兼容的 {@code /v1}，所以一个 {@link OpenAiChatModel} +
 * 一个 {@link OpenAiEmbeddingModel} 就能覆盖两种情况，不用引第二个供应商实现。
 *
 * <p>默认参数给的是"解析档"（温度 0、token 少）；回答节点会在每次调用时用
 * per-request options 覆盖成温度 0.3 / token 更多。
 */
@Configuration
public class AiConfig {

    @Bean
    public ChatModel chatModel(LlmProperties properties) {
        LlmProperties.Endpoint endpoint = properties.active();
        // 空 key 也允许启动：这样没配 key 时服务能起来、/healthz 会报 llm=false，
        // 而不是在 Bean 装配阶段就抛异常、连日志都看不清
        String apiKey = endpoint.getApiKey() == null || endpoint.getApiKey().isBlank()
                ? "not-configured"
                : endpoint.getApiKey();

        OpenAiApi api = OpenAiApi.builder()
                .baseUrl(endpoint.getBaseUrl())
                .apiKey(apiKey)
                .build();

        return OpenAiChatModel.builder()
                .openAiApi(api)
                // 显式给一个 ToolCallingManager：我们自己 new 的 ChatModel 不走 starter 自动装配，
                // 不指定的话工具调用在运行时才炸（而且报错很难懂）
                .toolCallingManager(org.springframework.ai.model.tool.ToolCallingManager.builder().build())
                .defaultOptions(OpenAiChatOptions.builder()
                        .model(endpoint.getChatModel())
                        .temperature(properties.getRouterTemperature())
                        .maxTokens(properties.getRouterMaxTokens())
                        .build())
                .build();
    }

    @Bean
    public ChatClient chatClient(ChatModel chatModel) {
        return ChatClient.builder(chatModel).build();
    }

    @Bean
    public EmbeddingModel embeddingModel(EmbeddingProperties properties) {
        String apiKey = properties.getApiKey() == null || properties.getApiKey().isBlank()
                ? "local"
                : properties.getApiKey();
        OpenAiApi api = OpenAiApi.builder()
                .baseUrl(properties.getBaseUrl())
                .apiKey(apiKey)
                .build();

        // OpenAiEmbeddingModel 只有构造器，没有 builder（1.1.8 的 API）
        return new OpenAiEmbeddingModel(api, MetadataMode.NONE,
                OpenAiEmbeddingOptions.builder()
                        .model(properties.getModel())
                        .dimensions(properties.getDimensions())
                        .build());
    }
}
