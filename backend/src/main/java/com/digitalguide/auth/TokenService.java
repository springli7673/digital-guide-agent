package com.digitalguide.auth;

import com.digitalguide.common.BizException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.UUID;

/**
 * token 的签发与校验（存 Redis，7 天）。
 *
 * <p>为什么不是 JWT：JWT 一旦签发就撤不回，登出只能靠黑名单；
 * 存在 Redis 里反而更简单——登出就是删 key。代价是每次校验打一次 Redis（毫秒级）。
 *
 * <p><b>注意：这里不是 fail-open。</b> Redis 连不上时登录会失败，
 * 所以要给出能看懂的错误，而不是笼统的"系统繁忙"。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TokenService {

    private static final String KEY_PREFIX = "auth:token:";
    private static final Duration TTL = Duration.ofDays(7);

    private final StringRedisTemplate redis;

    public String issue(Long userId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        try {
            redis.opsForValue().set(KEY_PREFIX + token, String.valueOf(userId), TTL);
        } catch (DataAccessException e) {
            log.error("token 写入 Redis 失败：{}", e.getMessage());
            throw new BizException(503, "登录服务暂不可用：Redis 未连接（检查 REDIS_PASSWORD）");
        }
        return token;
    }

    public Long resolve(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        try {
            String value = redis.opsForValue().get(KEY_PREFIX + token);
            return value == null ? null : Long.valueOf(value);
        } catch (DataAccessException e) {
            // 校验时连不上就当没登录：请求拿到 401，前端引导重新登录。
            // 这里不抛 503——它被拦截器调用，抛了会让整个接口 500。
            log.warn("token 校验时 Redis 不可用：{}", e.getMessage());
            return null;
        }
    }

    public void revoke(String token) {
        if (token == null || token.isBlank()) {
            return;
        }
        try {
            redis.delete(KEY_PREFIX + token);
        } catch (DataAccessException e) {
            log.warn("登出时 Redis 不可用（7 天后自然过期）：{}", e.getMessage());
        }
    }
}
