package com.digitalguide.ai.graph;

/** 一轮对话里的历史消息（前端只传 role / content）。 */
public record ChatMessage(String role, String content) {

    public boolean isUser() {
        return "user".equalsIgnoreCase(role);
    }

    public String roleLabel() {
        return isUser() ? "用户" : "助手";
    }
}
