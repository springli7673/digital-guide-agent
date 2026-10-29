package com.digitalguide.ai.llm;

/**
 * 一次模型调用。json=true 时会带上 response_format=json_object。
 */
public record LlmRequest(String system, String user, double temperature, int maxTokens, boolean json) {
}
