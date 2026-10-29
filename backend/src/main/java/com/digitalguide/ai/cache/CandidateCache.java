package com.digitalguide.ai.cache;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * 候选集缓存。
 *
 * <p>缓存的是 retrieve 节点 SQL 过滤出来的<b>原始候选</b>，不是打分结果——
 * 因为打分依赖 must_have / nice_to_have，而这部分每轮都不同，缓存了反而错。
 *
 * <p>命中率来源很实际：用户会反复问"3000 以内拍照好的"，换说法但条件相同；
 * 连问几轮时每轮都要重跑一次全表过滤，缓存能把这部分省掉。
 *
 * <p>失败语义：<b>任何异常都当作未命中</b>。缓存是加速，不是数据源。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CandidateCache {

    private static final TypeReference<List<Map<String, Object>>> ROWS =
            new TypeReference<>() {
            };

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final CacheProperties properties;

    /** 命中返回列表，未命中/值损坏/Redis 不可用返回 null */
    public List<Map<String, Object>> get(String key) {
        if (!properties.isEnabled() || key == null) {
            return null;
        }
        try {
            String cached = redis.opsForValue().get(key);
            if (cached == null || cached.isBlank()) {
                return null;
            }
            List<Map<String, Object>> rows = objectMapper.readValue(cached, ROWS);
            return rows == null || rows.isEmpty() ? null : rows;
        } catch (Exception e) {
            // 反序列化失败多半是缓存里的结构跟当前代码不一致（改过字段），当未命中处理即可
            log.debug("候选缓存读取失败，按未命中处理：{}", e.getMessage());
            return null;
        }
    }

    public void put(String key, List<Map<String, Object>> rows) {
        if (!properties.isEnabled() || key == null || rows == null || rows.isEmpty()) {
            return;
        }
        try {
            redis.opsForValue().set(key, objectMapper.writeValueAsString(rows),
                    Duration.ofMinutes(properties.getCandidatesTtlMinutes()));
        } catch (Exception e) {
            log.debug("候选缓存写入失败（不影响本次结果）：{}", e.getMessage());
        }
    }
}
