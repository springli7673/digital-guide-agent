package com.digitalguide.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;

/**
 * 启动自检。
 *
 * <p>存在的理由很具体：所有 Redis 用法都是 <b>fail-open</b>，
 * 连不上时不会报错、只会静默退化（缓存不生效、限流放行、会话锁失效）。
 * 但<b>登录不是 fail-open</b>——token 存在 Redis 里，连不上就登录不了。
 * 所以启动时必须把这件事吼出来，而不是等用户点登录时看到"系统繁忙"。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StartupCheck implements ApplicationRunner {

    private final DataSource dataSource;
    private final StringRedisTemplate redis;

    @Override
    public void run(ApplicationArguments args) {
        if (dbOk()) {
            log.info("[自检] PostgreSQL 连接正常");
        } else {
            log.error("[自检] PostgreSQL 连不上：所有查库接口都会失败");
        }
        if (redisOk()) {
            log.info("[自检] Redis 连接正常");
        } else {
            log.error("""
                    [自检] Redis 连不上 —— 会影响两件事：
                      1) 登录 / 注册会失败（token 存在 Redis 里）；
                      2) 缓存、限流、会话锁会静默失效（fail-open，不报错）。
                    本机 Redis 是带密码的，启动环境里要设 REDIS_PASSWORD=123456；
                    或者直接跑 `redis-cli -a 123456 ping` 确认一下能通。""");
        }
    }

    private boolean dbOk() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(2);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean redisOk() {
        try (var connection = redis.getConnectionFactory().getConnection()) {
            return "PONG".equalsIgnoreCase(connection.ping());
        } catch (Exception e) {
            return false;
        }
    }
}
