package com.digitalguide.ai.memory;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 记忆参数。
 *
 * <p>三层结构，各管一段：
 * <pre>
 *   滑动窗口（最近 8 条）  →  原封不动的最近上下文，解析节点直接读
 *   摘要（滚动的）          →  更早的历史压缩成一段话，控制 token
 *   槽位锚点（最近一次意图）→  即使历史被压缩，预算/偏好/品牌也不会丢
 * </pre>
 *
 * <p>为什么必须有第三层：只做"窗口 + 摘要"，用户第 10 轮说"再便宜点"时，
 * 预算可能已经被压进摘要，而摘要不会精确到具体数字。槽位锚点是结构化数据，
 * 不参与压缩，所以永远不会丢。
 */
@Data
@Component
@ConfigurationProperties(prefix = "ai.memory")
public class MemoryProperties {

    /** 滑动窗口保留多少条消息（一问一答算 2 条） */
    private int windowSize = 8;
    /** 超过多少条触发摘要压缩 */
    private int summarizeAfter = 16;
    /** 摘要正文上限，控制注入解析节点的 token */
    private int summaryMaxChars = 400;
    /** 关掉就不落库，纯粹靠前端传的 history（本地调试用） */
    private boolean enabled = true;

    /**
     * 是否把上下文缓到 Redis。
     *
     * <p>关掉只是每次都回源 PG，功能不受影响——所以这个开合可以随时动，
     * 不会构成"配置改错就白屏"的风险。
     */
    private boolean redisEnabled = true;

    /** 热存存活时间：略长于"一次会话的自然间隔"即可，太长会让冷数据长期占内存 */
    private int redisTtlMinutes = 30;
}
