package com.digitalguide.ai.llm;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.ChatOptions;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.function.Consumer;

/**
 * 模型客户端，基于 Spring AI 的 {@link ChatClient}。
 *
 * <p>DeepSeek 与 Ollama 走同一个 OpenAI 兼容实现，切换只改配置
 * （{@code ai.llm.provider} + 各自的 base-url / api-key / chat-model）。
 *
 * <p>这里只做两件事：把 {@link LlmRequest} 翻译成每次调用的 options，
 * 以及把流式 Flux 收敛成"逐 token 回调"——节点是阻塞式的，
 * 不想让整条链路为了流式改成响应式。
 */
@Slf4j
@Component
public class SpringAiLlmClient implements LlmClient {

    private final ChatClient chatClient;
    private final LlmProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient probeHttp;

    public SpringAiLlmClient(ChatClient chatClient, LlmProperties properties, ObjectMapper objectMapper) {
        this.chatClient = chatClient;
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.probeHttp = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(Math.max(properties.getConnectTimeoutSeconds(), 1)))
                .build();
    }

    @Override
    public String complete(LlmRequest request) {
        try {
            String content = chatClient.prompt()
                    .system(request.system())
                    .user(request.user())
                    .options(optionsFor(request))
                    .call()
                    .content();
            if (content == null || content.isBlank()) {
                throw new LlmException("模型返回空内容");
            }
            return content;
        } catch (LlmException e) {
            throw e;
        } catch (RuntimeException e) {
            throw new LlmException("模型调用失败：" + e.getMessage(), e);
        }
    }

    @Override
    public void stream(LlmRequest request, Consumer<String> onToken) {
        try {
            // Spring AI 返回 Flux<String>；toIterable() 把它拉回阻塞迭代，
            // 这样节点代码不用感知响应式类型
            Iterable<String> tokens = chatClient.prompt()
                    .system(request.system())
                    .user(request.user())
                    .options(optionsFor(request))
                    .stream()
                    .content()
                    .toIterable();
            for (String token : tokens) {
                if (token != null && !token.isEmpty()) {
                    onToken.accept(token);
                }
            }
        } catch (RuntimeException e) {
            throw new LlmException("模型流式调用失败：" + e.getMessage(), e);
        }
    }

    @Override
    public String modelName() {
        return properties.active().getChatModel();
    }

    /**
     * 端点可达性。故意不走 ChatClient：真正发一次对话既慢又花钱，
     * 健康检查只关心"这个 base-url + key 能不能通"。
     */
    @Override
    public boolean healthy() {
        LlmProperties.Endpoint endpoint = properties.active();
        String base = endpoint.getBaseUrl() == null ? "" : endpoint.getBaseUrl().trim();
        while (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        if (base.isEmpty()) {
            return false;
        }
        String url = (base.endsWith("/v1") ? base : base + "/v1") + "/models";
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(url))
                .GET()
                .timeout(Duration.ofSeconds(5));
        String apiKey = endpoint.getApiKey();
        if (apiKey != null && !apiKey.isBlank()) {
            builder.header("Authorization", "Bearer " + apiKey.trim());
        }
        try {
            return probeHttp.send(builder.build(), HttpResponse.BodyHandlers.discarding()).statusCode() / 100 == 2;
        } catch (IOException e) {
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    /** 每次调用的参数：解析档温度 0，回答档温度 0.3，token 上限也不同 */
    private ChatOptions optionsFor(LlmRequest request) {
        OpenAiChatOptions.Builder builder = OpenAiChatOptions.builder()
                .model(properties.active().getChatModel())
                .temperature(request.temperature())
                .maxTokens(request.maxTokens());
        if (request.json() && properties.active().isJsonMode()) {
            // DeepSeek / Ollama 都认 response_format=json_object；
            // 具体枚举在 Spring AI 里是 OpenAiApi.ResponseFormat
            builder.responseFormat(org.springframework.ai.openai.api.ResponseFormat.builder()
                    .type(org.springframework.ai.openai.api.ResponseFormat.Type.JSON_OBJECT)
                    .build());
        }
        return builder.build();
    }
}
