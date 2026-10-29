package com.digitalguide.ai.cache;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Redis 侧的能力开关与参数。
 *
 * <p>这里放的都是"让系统不被打穿"的东西：结果缓存、入口限流、会话串行化。
 * 三个都遵循同一条原则——<b>Redis 挂了就放行，不阻断对话</b>。
 * 缓存没了只是慢一点，限流器挂了只是不设防，会话锁挂了最坏是并发串话；
 * 但如果它们一挂就白屏，那才是真事故。
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.cache")
public class CacheProperties {

    /** 总开关，本地调试想完全绕开 Redis 时关掉 */
    private boolean enabled = true;

    /** 候选集缓存存活时间。商品参数变动不频繁，10 分钟够用 */
    private int candidatesTtlMinutes = 10;

    /** 单会话每分钟允许的请求数（入口限流） */
    private int rateLimitPerMinute = 20;

    /** 会话锁过期时间，防止进程崩溃后锁永久不释放 */
    private int sessionLockSeconds = 30;

    /** 抢锁最多等多久；超时就告诉前端"上一轮还没生成完" */
    private int sessionLockWaitMs = 800;
}
