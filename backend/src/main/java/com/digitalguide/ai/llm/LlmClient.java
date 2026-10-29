package com.digitalguide.ai.llm;

import java.util.function.Consumer;

/** 模型客户端。阻塞式：调用发生在 SSE 的工作线程里，不需要响应式。 */
public interface LlmClient {

    /** 一次性拿完（解析节点用）。 */
    String complete(LlmRequest request);

    /** 边生成边回调（回答节点用）。回调里抛异常会中断流。 */
    void stream(LlmRequest request, Consumer<String> onToken);

    /** 当前生效的模型名，给 /healthz 显示。 */
    String modelName();

    /** 端点是否可达，给 /healthz 用。 */
    boolean healthy();
}
