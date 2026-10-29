package com.digitalguide.ai.cache;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.UUID;

/**
 * 会话级互斥锁。
 *
 * <p>解决的是真实存在的一个问题：用户连点两次发送，或前端重连重发，
 * 两个请求会同时读到同一份历史、各自生成摘要、各自覆盖槽位，
 * 结果就是上下文错乱——表现为"它怎么忘了我刚说的预算"。
 *
 * <p>三个细节：
 * <ul>
 *   <li><b>带 token 释放</b>：只删自己加的锁。否则 A 超时释放时会把 B 刚拿到的锁删掉；</li>
 *   <li><b>带过期时间</b>：进程被 kill 时锁不会永久占住，最多卡 30 秒；</li>
 *   <li><b>短暂自旋</b>：用户连点两下时，第二次等 800ms 往往就能排上，
 *       比直接报错体验好得多。</li>
 * </ul>
 *
 * <p>Redis 不可用时返回"无需加锁"，让对话照常进行——退化成可能串话，
 * 也好过整个接口不可用。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SessionLock {

    /** 只删自己那把锁：GET 到的值和 ARGV[1] 一致才 DEL */
    private static final DefaultRedisScript<Long> RELEASE = new DefaultRedisScript<>("""
            if redis.call('get', KEYS[1]) == ARGV[1] then
                return redis.call('del', KEYS[1])
            else
                return 0
            end
            """, Long.class);

    private static final long SPIN_INTERVAL_MS = 50L;

    private final StringRedisTemplate redis;
    private final CacheProperties properties;

    /**
     * @return 加锁成功返回 token（释放时要用）；无需加锁返回空串；
     *         等待超时返回 {@code null}（调用方据此告诉前端"上一轮还在生成"）。
     */
    public String acquire(String sessionId) {
        if (!properties.isEnabled() || sessionId == null || sessionId.isBlank()) {
            return "";
        }
        String key = CacheKeys.sessionLock(sessionId);
        String token = UUID.randomUUID().toString();
        long deadline = System.currentTimeMillis() + properties.getSessionLockWaitMs();
        try {
            do {
                Boolean ok = redis.opsForValue().setIfAbsent(key, token,
                        Duration.ofSeconds(properties.getSessionLockSeconds()));
                if (Boolean.TRUE.equals(ok)) {
                    return token;
                }
                if (System.currentTimeMillis() >= deadline) {
                    break;
                }
                Thread.sleep(SPIN_INTERVAL_MS);
            } while (System.currentTimeMillis() < deadline);
            return null;
        } catch (Exception e) {
            log.debug("会话锁不可用，跳过互斥：{}", e.getMessage());
            return "";
        }
    }

    /** 释放；token 为空串表示当初没加锁，直接返回 */
    public void release(String sessionId, String token) {
        if (token == null || token.isEmpty() || sessionId == null || sessionId.isBlank()) {
            return;
        }
        try {
            redis.execute(RELEASE, List.of(CacheKeys.sessionLock(sessionId)), token);
        } catch (Exception e) {
            // 释放失败最坏是锁等到 30 秒自然过期，不值得打断请求
            log.debug("会话锁释放失败（等它自然过期）：{}", e.getMessage());
        }
    }
}
