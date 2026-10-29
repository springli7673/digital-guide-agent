package com.digitalguide.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TokenService {

    private static final String KEY_PREFIX = "auth:token:";
    private static final Duration TTL = Duration.ofDays(7);

    private final StringRedisTemplate redis;

    public String issue(Long userId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        redis.opsForValue().set(KEY_PREFIX + token, String.valueOf(userId), TTL);
        return token;
    }

    public Long resolve(String token) {
        String value = redis.opsForValue().get(KEY_PREFIX + token);
        return value == null ? null : Long.valueOf(value);
    }

    public void revoke(String token) {
        redis.delete(KEY_PREFIX + token);
    }
}
