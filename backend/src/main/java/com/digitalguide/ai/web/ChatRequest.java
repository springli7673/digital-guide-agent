package com.digitalguide.ai.web;

import java.util.List;

import com.digitalguide.ai.graph.ChatMessage;

/**
 * POST /v1/chat 的请求体。字段名与前端 web/src/agent.js 完全一致（含 camelCase）。
 *
 * @param history      最近几轮对话，让"不限预算，只看参数"这类补充回答能接上上文
 * @param clarifyCount 本次对话已经追问过几次；≥1 时服务端不再追问，直接给结果
 */
public record ChatRequest(
        String message,
        String sessionId,
        List<ChatMessage> history,
        Integer clarifyCount
) {

    public int clarifyCountOrDefault() {
        return clarifyCount == null ? 0 : clarifyCount;
    }
}
