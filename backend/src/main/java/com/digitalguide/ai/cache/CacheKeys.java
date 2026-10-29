package com.digitalguide.ai.cache;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Locale;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 所有 Redis key 的唯一出口。
 *
 * <p>集中在一个类里，是为了让"改一个前缀"变成改一行，而不是全局搜索字符串。
 * key 的计算必须是<b>纯函数</b>：同样的入参必须得到同样的 key，
 * 尤其是品牌列表——用户说"小米,红米"和"红米,小米"必须命中同一条缓存，
 * 所以这里排序 + 去重 + 转小写，而不是直接用 {@code List.toString()}。
 */
public final class CacheKeys {

    private static final String PREFIX = "dg:";
    private static final int MAX_SESSION_LEN = 128;

    private CacheKeys() {
    }

    /**
     * 候选集缓存：只由「品类 + 预算区间 + 品牌集合」决定。
     *
     * <p>注意不包含 must_have / nice_to_have——那两个只影响打分，不影响 SQL 过滤，
     * 放进 key 会让缓存命中率掉一半而收益为零。
     */
    public static String candidates(String category, BigDecimal min, BigDecimal max,
                                    Collection<String> brands) {
        String cat = blank(category) ? "any" : category.trim().toLowerCase(Locale.ROOT);
        return PREFIX + "cand:" + cat + ":" + number(min) + "-" + number(max) + ":" + brandsPart(brands);
    }

    /** 会话记忆热存：整段上下文一个 JSON，读改一次搞定 */
    public static String memory(String sessionId) {
        return PREFIX + "mem:" + sanitize(sessionId);
    }

    /** 会话锁：同一 session 的请求串行化，防止多轮上下文互相覆盖 */
    public static String sessionLock(String sessionId) {
        return PREFIX + "lock:" + sanitize(sessionId);
    }

    /**
     * 限流：按分钟分桶。
     * 用"分桶 + INCR"而不是滑动窗口，是因为后者的 key 数量会随并发线性膨胀，
     * 而这里只要一个 60 秒的计数器就够把突发流量挡住。
     */
    public static String rate(String scope, long epochMinute) {
        return PREFIX + "rate:" + sanitize(scope) + ":" + epochMinute;
    }

    // ------------------------------------------------------------------ 内部

    /** 数字统一成无科学计数法、无尾零的形式；null 表示"不限" */
    private static String number(BigDecimal value) {
        return value == null ? "*" : value.stripTrailingZeros().toPlainString();
    }

    private static String brandsPart(Collection<String> brands) {
        if (brands == null || brands.isEmpty()) {
            return "*";
        }
        String joined = brands.stream()
                .filter(Objects::nonNull)
                .map(brand -> brand.trim().toLowerCase(Locale.ROOT))
                .filter(brand -> !brand.isEmpty())
                .distinct()
                .sorted()
                .collect(Collectors.joining(","));
        return joined.isEmpty() ? "*" : joined;
    }

    /** sessionId 来自客户端，必须截断——否则一个超长 id 就能把 Redis 的 key 内存撑爆 */
    private static String sanitize(String raw) {
        if (raw == null || raw.isBlank()) {
            return "anonymous";
        }
        String trimmed = raw.trim();
        return trimmed.length() <= MAX_SESSION_LEN ? trimmed : trimmed.substring(0, MAX_SESSION_LEN);
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }
}
