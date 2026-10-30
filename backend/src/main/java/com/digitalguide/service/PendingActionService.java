package com.digitalguide.service;

import com.digitalguide.common.BizException;
import com.digitalguide.dto.PendingActionView;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * 待确认动作（写操作的"确认凭证"）。
 *
 * <p>为什么要这一层：模型可以提议"帮你下单"，但**不能自己下单**。
 * 所以写操作被拆成两步：
 * <pre>
 *   agent 调 prepareOrder → 只生成一个 confirmId（不写库）
 *   前端渲染"确认下单"按钮 → 用户点 → POST /api/orders/confirm {confirmId} → 才真正执行
 * </pre>
 *
 * <p>{@code confirmId} 就是下单的幂等键（{@code orders.idem_key}），
 * 所以"连点两次确认"天然只会落一单——不需要再写一套去重逻辑。
 *
 * <p>放 Redis 而不是 PG：待确认动作的生命周期只有 5 分钟，
 * <b>过期作废是正确语义</b>，不是数据丢失。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PendingActionService {

    private static final Duration TTL = Duration.ofMinutes(5);
    private static final String ACTION_PREFIX = "dg:pending:action:";
    private static final String USER_PREFIX = "dg:pending:user:";

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

    /**
     * 生成一个待确认动作，返回 confirmId。
     *
     * <p>同一用户同一时刻只保留一个待确认（后生成的覆盖前一个），
     * 否则用户连问三次"帮我下单"会攒出三个待确认按钮，点哪个都尴尬。
     */
    public String create(long userId, String type, String summary, BigDecimal total, int itemCount) {
        String confirmId = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        PendingActionView view = new PendingActionView(confirmId, type, summary, total, itemCount);
        try {
            String json = objectMapper.writeValueAsString(new Stored(userId, view));
            redis.opsForValue().set(USER_PREFIX + userId, confirmId, TTL);
            redis.opsForValue().set(ACTION_PREFIX + confirmId, json, TTL);
        } catch (Exception e) {
            log.warn("待确认动作写入失败：{}", e.getMessage());
            throw new BizException(500, "生成确认凭证失败，请重试");
        }
        return confirmId;
    }

    /** 前端聊天结束后查一次：有就渲染确认按钮 */
    public PendingActionView current(long userId) {
        try {
            String confirmId = redis.opsForValue().get(USER_PREFIX + userId);
            if (confirmId == null) {
                return null;
            }
            String json = redis.opsForValue().get(ACTION_PREFIX + confirmId);
            if (json == null) {
                return null;
            }
            Stored stored = objectMapper.readValue(json, Stored.class);
            return stored.userId() == userId ? stored.view() : null;
        } catch (Exception e) {
            log.debug("读取待确认动作失败：{}", e.getMessage());
            return null;
        }
    }

    /**
     * 取出并作废（原子操作）。
     *
     * <p>用 {@code getAndDelete} 而不是"先读后删"：两个并发确认只能有一个拿到值，
     * 这是"同一 confirmId 只生效一次"的第一道闸门，数据库唯一索引是第二道。
     *
     * <p>代价：如果取出后执行失败，这个凭证就没了，用户得重新让 agent 发起。
     * 这样换来的确定性（绝不重复执行）是值得的。
     */
    public PendingActionView consume(String confirmId, long userId) {
        if (confirmId == null || confirmId.isBlank()) {
            throw new BizException(400, "confirmId 不能为空");
        }
        String json;
        try {
            // 先读出来校验归属，再原子删除：
            // 如果先删再校验，别人拿到一个 confirmId 就能把你的凭证"烧掉"（拒绝服务）。
            json = redis.opsForValue().get(ACTION_PREFIX + confirmId);
        } catch (Exception e) {
            log.warn("读取确认凭证失败：{}", e.getMessage());
            throw new BizException(500, "确认服务暂时不可用，请重试");
        }
        if (json == null) {
            throw new BizException(410, "这个确认已经失效（用过或超时），请重新发起");
        }
        Stored stored;
        try {
            stored = objectMapper.readValue(json, Stored.class);
        } catch (Exception e) {
            throw new BizException(410, "确认凭证已损坏，请重新发起");
        }
        if (stored.userId() != userId) {
            // 别人的凭证：明确拒绝，且不删除——它还得留给真正的主人
            throw new BizException(403, "这个确认不属于当前账号");
        }
        // 真正"一次性"的保证：两个人同时确认，只有一个能拿到值
        String consumed;
        try {
            consumed = redis.opsForValue().getAndDelete(ACTION_PREFIX + confirmId);
        } catch (Exception e) {
            throw new BizException(500, "确认服务暂时不可用，请重试");
        }
        if (consumed == null) {
            throw new BizException(410, "这个确认刚刚已被使用");
        }
        redis.delete(USER_PREFIX + userId);
        return stored.view();
    }

    /** 磁盘形态：带上归属用户，防止拿别人的 confirmId 执行 */
    public record Stored(long userId, PendingActionView view) {
    }

    /** 给日志用的紧凑描述 */
    public static Map<String, Object> describe(PendingActionView view) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("confirmId", view == null ? null : view.confirmId());
        map.put("type", view == null ? null : view.type());
        return map;
    }
}
