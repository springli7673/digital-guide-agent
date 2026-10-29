package com.digitalguide.ai.cache;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Redis key 的回归测试。
 *
 * <p>key 是缓存的契约：算错了不会报错，只会<b>永远不命中</b>——而"缓存不生效"
 * 这种问题监控看不出来、日志也没有异常，只能靠这里钉住。
 */
class CacheKeysTest {

    @Test
    @DisplayName("品牌顺序不影响 key：小米,红米 与 红米,小米 必须同一条缓存")
    void brandOrderDoesNotMatter() {
        String a = CacheKeys.candidates("phone", BigDecimal.valueOf(2000), BigDecimal.valueOf(3000),
                List.of("小米", "红米"));
        String b = CacheKeys.candidates("phone", BigDecimal.valueOf(2000), BigDecimal.valueOf(3000),
                List.of("红米", "小米"));

        assertThat(a).isEqualTo(b);
    }

    @Test
    @DisplayName("预算或品类不同就是不同的 key")
    void differentScopeDifferentKey() {
        String base = CacheKeys.candidates("phone", BigDecimal.valueOf(2000), BigDecimal.valueOf(3000),
                List.of("小米"));

        assertThat(CacheKeys.candidates("phone", BigDecimal.valueOf(2000), BigDecimal.valueOf(4000),
                List.of("小米"))).isNotEqualTo(base);
        assertThat(CacheKeys.candidates("earbuds", BigDecimal.valueOf(2000), BigDecimal.valueOf(3000),
                List.of("小米"))).isNotEqualTo(base);
    }

    @Test
    @DisplayName("不限预算用 * 占位，且不会和某个具体价格撞车")
    void nullBudgetUsesWildcard() {
        String unbounded = CacheKeys.candidates("phone", null, null, List.of());

        assertThat(unbounded).contains(":*-*:*");
        assertThat(unbounded).isNotEqualTo(
                CacheKeys.candidates("phone", BigDecimal.ZERO, BigDecimal.ZERO, List.of()));
    }

    @Test
    @DisplayName("价格去掉尾零，3000 与 3000.00 是同一条缓存")
    void priceTrailingZerosDropped() {
        assertThat(CacheKeys.candidates("phone", BigDecimal.valueOf(3000), null, null))
                .isEqualTo(CacheKeys.candidates("phone", new BigDecimal("3000.00"), null, null));
    }

    @Test
    @DisplayName("超长 sessionId 被截断，防止客户端把 key 撑大")
    void longSessionIdTruncated() {
        String key = CacheKeys.memory("x".repeat(500));

        assertThat(key.length()).isLessThan(160);
        assertThat(CacheKeys.memory("")).endsWith("anonymous");
    }

    @Test
    @DisplayName("限流 key 按分钟分桶，跨分钟自动换桶")
    void rateKeyBucketsByMinute() {
        assertThat(CacheKeys.rate("s1", 100)).isNotEqualTo(CacheKeys.rate("s1", 101));
        assertThat(CacheKeys.rate("s1", 100)).isEqualTo(CacheKeys.rate("s1", 100));
    }

    @Test
    @DisplayName("记忆、会话锁、限流的 key 前缀互不冲突")
    void prefixesAreDisjoint() {
        assertThat(CacheKeys.memory("s1")).isNotEqualTo(CacheKeys.sessionLock("s1"));
        assertThat(CacheKeys.sessionLock("s1")).isNotEqualTo(CacheKeys.rate("s1", 1));
    }
}
