package com.digitalguide.ai.web;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 记忆归属键的回归测试。
 *
 * <p>这个键决定"聊天记录归谁"。算错了不会报错，只会表现为
 * "登录和不登录的记忆串在一起"或"换设备后记忆消失"——线上极难发现，所以钉死在这里。
 */
class ConversationKeyTest {

    @Test
    @DisplayName("登录用户按 userId 归档，忽略前端 sessionId")
    void loggedInUsesUserId() {
        assertThat(AiChatController.conversationKey(42L, "local-uuid-abc")).isEqualTo("u:42");
        assertThat(AiChatController.conversationKey(42L, null)).isEqualTo("u:42");
    }

    @Test
    @DisplayName("匿名用户退回前端 sessionId")
    void anonymousUsesSessionId() {
        assertThat(AiChatController.conversationKey(null, "local-uuid-abc"))
                .isEqualTo("a:local-uuid-abc");
    }

    @Test
    @DisplayName("两者都没有时落到固定的 anonymous，不能是空串")
    void fallbackIsAnonymous() {
        assertThat(AiChatController.conversationKey(null, null)).isEqualTo("a:anonymous");
        assertThat(AiChatController.conversationKey(null, "   ")).isEqualTo("a:anonymous");
    }

    @Test
    @DisplayName("登录态与匿名态的键永不冲突")
    void keysNeverCollide() {
        // 故意用"看起来能对上"的 id 去撞：u:1 与 a:1 必须是两把不同的键
        assertThat(AiChatController.conversationKey(1L, "1")).isNotEqualTo("a:1");
        assertThat(AiChatController.conversationKey(null, "u:1")).isNotEqualTo("u:1");
    }
}
