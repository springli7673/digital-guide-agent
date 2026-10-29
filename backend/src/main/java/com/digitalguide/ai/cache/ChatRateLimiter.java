package com.digitalguide.ai.cache;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * 入口限流：单会话每分钟 N 次。
 *
 * <p>为什么限"会话"而不是限 IP：这个接口最贵的成本是模型调用，
 * 而一次会话就是一条连续的 token 流水，限会话等于给每个用户一个预算，
 * 限 IP 会把同一间宿舍的四个人算成一个人。
 *
 * <p>实现刻意选"固定窗口 INCR"而不是 Lua 令牌桶：
 * 固定窗口的边界效应（两个窗口交界处能过 2N 次）在问答场景完全可以接受，
 * 而少一段 Lua 脚本，就少一处上线后调不对的坑。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatRateLimiter {

    private final StringRedisTemplate redis;
    private final CacheProperties properties;

    /**
     * @return true 放行，false 拒绝。
     * <p>Redis 不可用时<b>放行</b>——限流器挂了不能顺带把服务带走。
     */
    public boolean tryAcquire(String scope) {
        if (!properties.isEnabled()) {
            return true;
        }
        long bucket = System.currentTimeMillis() / 60_000L;
        String key = CacheKeys.rate(scope, bucket);
        try {
            Long used = redis.opsForValue().increment(key);
            if (used != null && used == 1L) {
                redis.expire(key, Duration.ofSeconds(90));
            }
            if (used != null && used > properties.getRateLimitPerMinute()) {
                log.info("触发限流：scope={} 本分钟第 {} 次", scope, used);
                return false;
            }
            return true;
        } catch (Exception e) {
            log.debug("限流器不可用，放行：{}", e.getMessage());
            return true;
        }
    }
}
