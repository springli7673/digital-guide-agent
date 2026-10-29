package com.digitalguide.ai.llm;

/** 模型调用失败（网络、超时、非 2xx、返回体不合法）。调用方负责降级。 */
public class LlmException extends RuntimeException {

    private final int statusCode;

    public LlmException(String message) {
        this(message, 0);
    }

    public LlmException(String message, int statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public LlmException(String message, Throwable cause) {
        super(message, cause);
        this.statusCode = 0;
    }

    public int statusCode() {
        return statusCode;
    }
}
