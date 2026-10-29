package com.digitalguide.ai.web;

import com.digitalguide.ai.cache.ChatRateLimiter;
import com.digitalguide.ai.cache.SessionLock;
import com.digitalguide.ai.graph.ChatGraph;
import com.digitalguide.ai.graph.ChatState;
import com.digitalguide.ai.graph.EventSink;
import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.common.BizException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import javax.sql.DataSource;
import java.sql.Connection;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 对话接口。路由保持在 {@code /v1/chat}，前端一行都不用改——
 * 只是原来代理到 Python :8000 的这条路径，现在由 Java 自己接。
 *
 * <p>为什么用 {@link SseEmitter} 而不是 WebFlux：模型客户端是阻塞式的（JDK HttpClient），
 * 用 SseEmitter + 工作线程让"阻塞"这件事留在业务代码里，别为了流式把整条链路改成响应式。
 *
 * <p><b>已知限制</b>：浏览器关闭后图还会跑完当前一轮（没有做取消传播）。
 * 要做得更好，得把取消信号传进 LlmClient 的流式循环里，留到后面加。
 */
@Slf4j
@RestController
public class AiChatController {

    private static final long SSE_TIMEOUT_MS = 180_000L;

    private final ChatGraph chatGraph;
    private final ObjectMapper objectMapper;
    private final LlmClient llmClient;
    private final LlmProperties llmProperties;
    private final DataSource dataSource;
    private final com.digitalguide.ai.trace.TraceService traceService;
    private final com.digitalguide.ai.memory.MemoryService memoryService;
    private final ChatRateLimiter rateLimiter;
    private final SessionLock sessionLock;
    private final org.springframework.data.redis.core.StringRedisTemplate redis;

    /**
     * 有界队列 + CallerRuns：队列满时把活压回 Tomcat 线程，
     * 让上游自然变慢，而不是把内存吃穿。
     */
    private final ExecutorService chatPool;

    public AiChatController(ChatGraph chatGraph,
                            ObjectMapper objectMapper,
                            LlmClient llmClient,
                            LlmProperties llmProperties,
                            DataSource dataSource,
                            com.digitalguide.ai.trace.TraceService traceService,
                            com.digitalguide.ai.memory.MemoryService memoryService,
                            ChatRateLimiter rateLimiter,
                            SessionLock sessionLock,
                            org.springframework.data.redis.core.StringRedisTemplate redis) {
        this.chatGraph = chatGraph;
        this.objectMapper = objectMapper;
        this.llmClient = llmClient;
        this.llmProperties = llmProperties;
        this.dataSource = dataSource;
        this.traceService = traceService;
        this.memoryService = memoryService;
        this.rateLimiter = rateLimiter;
        this.sessionLock = sessionLock;
        this.redis = redis;

        AtomicInteger counter = new AtomicInteger();
        this.chatPool = new ThreadPoolExecutor(
                4, 16, 60L, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(64),
                runnable -> {
                    Thread thread = new Thread(runnable, "ai-chat-" + counter.incrementAndGet());
                    thread.setDaemon(true);
                    return thread;
                },
                new ThreadPoolExecutor.CallerRunsPolicy());
    }

    @PreDestroy
    public void shutdown() {
        chatPool.shutdownNow();
    }

    /*
     * 一定要显式声明 charset=UTF-8：只写 text/event-stream 时，
     * 部分客户端（IDEA 的 HTTP Client 就是）会按 ISO-8859-1 解码，
     * 中文全变成「OLED å LCD」这种乱码。服务端发的其实一直是 UTF-8 字节——
     * 浏览器用 TextDecoder 默认按 UTF-8 解，所以前端看不出来，只有调试工具会中招。
     */
    @PostMapping(value = "/v1/chat", produces = "text/event-stream;charset=UTF-8")
    public SseEmitter chat(@RequestBody ChatRequest request,
                           jakarta.servlet.http.HttpServletRequest httpRequest) {
        String message = request.message() == null ? "" : request.message().trim();
        if (message.isEmpty()) {
            throw new BizException(400, "message 不能为空");
        }

        /*
         * 入口限流：按会话计次，没有会话就按 IP。
         * 放在建 emitter 之前——被限的请求连流都不开，省下一条 SSE 连接和一个工作线程。
         */
        String scope = request.sessionId() == null || request.sessionId().isBlank()
                ? "ip:" + clientIp(httpRequest)
                : request.sessionId();
        if (!rateLimiter.tryAcquire(scope)) {
            throw new BizException(429, "问得太快了，歇一分钟再试");
        }

        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        AtomicBoolean clientGone = new AtomicBoolean(false);
        EventSink sink = (event, data) -> send(emitter, clientGone, event, data);

        // 记忆优先用库里的（滑动窗口 + 摘要 + 槽位锚点），库不可用时退回前端传的 history
        com.digitalguide.ai.memory.MemoryContext memory =
                memoryService.load(request.sessionId(), request.history());
        ChatState state = new ChatState(message, request.sessionId(),
                memory.recent(), request.clarifyCountOrDefault());
        state.setSummary(memory.summary());
        state.setAnchor(memory.anchor());

        Runnable task = () -> {
            String lockToken = null;
            try {
                /*
                 * 同一会话串行化。连点两次"发送"时，第二次最多等 800ms 就能排上；
                 * 排不上说明上一轮真在生成，就明确告诉用户，
                 * 而不是让两个请求各读一份历史、各写一次摘要，把上下文搞乱。
                 */
                lockToken = sessionLock.acquire(request.sessionId());
                if (lockToken == null) {
                    send(emitter, clientGone, "error",
                            Map.of("msg", "这个会话上一轮还没生成完，等它说完再发"));
                    return;
                }
                chatGraph.run(state, sink);
            } catch (Exception e) {
                log.error("对话执行失败", e);
                send(emitter, clientGone, "error", Map.of("msg", "服务内部错误：" + e.getMessage()));
            } finally {
                // 没拿到锁就退出时，这一轮什么都没跑，不该写埋点也不该写记忆
                if (lockToken != null) {
                    traceService.record(state);
                    memoryService.append(request.sessionId(), message, state.getAnswer(),
                            state.getIntent(), memory);
                }
                sessionLock.release(request.sessionId(), lockToken);
                try {
                    emitter.complete();
                } catch (Exception ignored) {
                    // 客户端已经断开，complete 抛异常是正常的
                }
            }
        };

        try {
            chatPool.execute(task);
        } catch (RejectedExecutionException e) {
            emitter.completeWithError(e);
        }
        return emitter;
    }

    @GetMapping("/healthz")
    public Map<String, Object> health() {
        boolean dbOk = checkDb();
        boolean redisOk = checkRedis();
        boolean llmOk = llmClient.healthy();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("status", dbOk && llmOk ? "ok" : "degraded");
        payload.put("db", dbOk);
        // Redis 挂了不影响对话（缓存/限流/会话锁全是 fail-open），
        // 但少了缓存和限流就是隐患，所以这里单独暴露出来
        payload.put("redis", redisOk);
        payload.put("llm", llmOk);
        payload.put("provider", llmProperties.getProvider());
        payload.put("chatModel", llmClient.modelName());
        return payload;
    }

    private boolean checkRedis() {
        try (org.springframework.data.redis.connection.RedisConnection connection =
                     redis.getConnectionFactory().getConnection()) {
            return "PONG".equalsIgnoreCase(connection.ping());
        } catch (Exception e) {
            return false;
        }
    }

    private boolean checkDb() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(2);
        } catch (Exception e) {
            return false;
        }
    }

    /** 取客户端 IP。刻意不解析 X-Forwarded-For：前面没有网关时它可被客户端伪造 */
    private static String clientIp(jakarta.servlet.http.HttpServletRequest request) {
        if (request == null) {
            return "unknown";
        }
        String remote = request.getRemoteAddr();
        return remote == null || remote.isBlank() ? "unknown" : remote;
    }

    /** 写一个 SSE 事件；客户端断了就置标记，后面的事件直接丢弃 */
    private void send(SseEmitter emitter, AtomicBoolean clientGone, String event, Object data) {
        if (clientGone.get()) {
            return;
        }
        try {
            String json = objectMapper.writeValueAsString(data);
            emitter.send(SseEmitter.event().name(event).data(json));
        } catch (Exception e) {
            clientGone.set(true);
            log.debug("SSE 写出失败（客户端可能已断开）：{}", e.getMessage());
        }
    }
}
