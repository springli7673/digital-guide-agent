package com.digitalguide.ai.memory;

import com.digitalguide.ai.cache.CacheKeys;
import com.digitalguide.ai.graph.ChatMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * 会话记忆的<b>热存</b>：PostgreSQL 是权威，Redis 只是它前面的一层缓存。
 *
 * <p>分工是这么划的：
 * <pre>
 *   Redis  dg:mem:{sid}  整段上下文一个 JSON，TTL 30 分钟  → 一小时内连续追问全部命中
 *   PG     ai.chat_message / ai.chat_session              → 权威、可回放、进程重启不丢
 * </pre>
 *
 * <p>为什么整段存成一条 JSON 而不是拆三个 key：载入记忆永远是"要就全要"，
 * 拆开就是三次往返；而它的体积很小（8 条消息 + 400 字摘要），一条足够。
 *
 * <p>与 PG 的一致性靠<b>写穿</b>而不是回填：append 时两边一起写，
 * 所以正常情况下 Redis 里就是最新状态；只有 Redis 重启后第一次读才会回源 PG。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RedisMemoryStore {

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final MemoryProperties properties;

    /** 命中返回上下文；未命中（或 Redis 不可用）返回 null，由调用方回源 PG */
    public MemoryContext load(String sessionId) {
        if (!properties.isRedisEnabled() || sessionId == null || sessionId.isBlank()) {
            return null;
        }
        try {
            String json = redis.opsForValue().get(CacheKeys.memory(sessionId));
            if (json == null || json.isBlank()) {
                return null;
            }
            Snapshot snapshot = objectMapper.readValue(json, Snapshot.class);
            if (snapshot == null) {
                return null;
            }
            List<ChatMessage> recent = snapshot.recent() == null ? List.of() : snapshot.recent();
            String summary = snapshot.summary() == null ? "" : snapshot.summary();
            Map<String, Object> anchor = snapshot.anchor() == null ? Map.of() : snapshot.anchor();
            // 三样全空说明这条缓存没有信息量，当作未命中，让调用方去 PG 拿 history 兜底
            if (summary.isBlank() && recent.isEmpty() && anchor.isEmpty()) {
                return null;
            }
            return new MemoryContext(summary, recent, anchor);
        } catch (Exception e) {
            log.debug("记忆热存读取失败，回源 PG：{}", e.getMessage());
            return null;
        }
    }

    public void save(String sessionId, MemoryContext context) {
        if (!properties.isRedisEnabled() || sessionId == null || sessionId.isBlank()
                || context == null) {
            return;
        }
        try {
            Snapshot snapshot = new Snapshot(context.summary(), context.recent(), context.anchor());
            redis.opsForValue().set(CacheKeys.memory(sessionId),
                    objectMapper.writeValueAsString(snapshot),
                    Duration.ofMinutes(properties.getRedisTtlMinutes()));
        } catch (Exception e) {
            log.debug("记忆热存写入失败（PG 里仍是准的）：{}", e.getMessage());
        }
    }

    public void evict(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) {
            return;
        }
        try {
            redis.delete(CacheKeys.memory(sessionId));
        } catch (Exception e) {
            log.debug("记忆热存清理失败：{}", e.getMessage());
        }
    }

    /** 磁盘上的形态；和 PG 里的三块（摘要 / 消息 / 槽位）一一对应 */
    public record Snapshot(String summary, List<ChatMessage> recent, Map<String, Object> anchor) {
    }
}
