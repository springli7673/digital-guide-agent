package com.digitalguide.service;

import com.digitalguide.common.BizException;
import com.digitalguide.dto.CartView;
import com.digitalguide.dto.OrderView;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 下单。
 *
 * <p>刻意做成"极简真实"：点一下就 {@code PAID}，不接支付、不做超时关单、不用 MQ。
 * 省掉的正是成本大头（支付流程），留下的是真正有价值的那部分——
 * <b>库存扣减的原子性 + 幂等</b>。
 *
 * <p>和另一个项目（校园生活秒杀）的区别要能说清：
 * 那边考的是"高并发下不超卖"（Redis 预扣 + MQ + 对账），
 * 这边考的是"LLM 触发写操作时不许重复执行"（幂等键 + 事务）。技术点不重叠。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OrderService {

    private static final DateTimeFormatter NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final JdbcTemplate jdbc;
    private final CartService cartService;

    /**
     * 从购物车下单。
     *
     * <p>四步在一个事务里：
     * 扣库存（条件更新）→ 建单 → 写明细 → 清购物车。
     * 任何一步失败整体回滚，不会出现"扣了库存没订单"。
     */
    @Transactional
    public OrderView placeFromCart(long userId, String idemKey) {
        // 快路径：同一个幂等键已经落过单，直接返回原单（不重复扣库存）
        if (idemKey != null && !idemKey.isBlank()) {
            OrderView existing = findByIdemKey(userId, idemKey);
            if (existing != null) {
                log.info("幂等命中，直接返回原订单：user={} idem={}", userId, idemKey);
                return existing;
            }
        }

        List<CartView.Line> lines = cartService.lines(userId);
        if (lines.isEmpty()) {
            throw new BizException(400, "购物车是空的");
        }

        for (CartView.Line line : lines) {
            decrementStock(line);
        }

        BigDecimal total = lines.stream()
                .map(CartView.Line::subtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(2, RoundingMode.HALF_UP);

        String orderNo = nextOrderNo();
        try {
            jdbc.update("""
                            INSERT INTO biz.orders (order_no, user_id, status, total_amount, idem_key, paid_at)
                            VALUES (?, ?, 'PAID', ?, ?, now())
                            """,
                    orderNo, userId, total, blankToNull(idemKey));
        } catch (DuplicateKeyException e) {
            /*
             * 并发下的兜底：两个请求同时通过了上面的"快路径"检查，
             * 第二个会撞 uk_orders_idem。这时不该报错，而是把第一个的单返给它。
             */
            OrderView existing = findByIdemKey(userId, idemKey);
            if (existing != null) {
                return existing;
            }
            throw e;
        }

        Long orderId = jdbc.queryForObject("SELECT id FROM biz.orders WHERE order_no = ?", Long.class, orderNo);
        for (CartView.Line line : lines) {
            jdbc.update("""
                            INSERT INTO biz.order_item (order_id, product_id, model_snapshot, price_snapshot, qty)
                            VALUES (?, ?, ?, ?, ?)
                            """,
                    orderId, line.productId(), line.model(), line.price(), line.qty());
        }

        jdbc.update("DELETE FROM biz.cart_item WHERE user_id = ?", userId);
        log.info("下单成功：user={} order={} 金额={} 行数={}", userId, orderNo, total, lines.size());
        return toView(orderNo);
    }

    public List<OrderView> myOrders(long userId) {
        List<String> orderNos = jdbc.query(
                "SELECT order_no FROM biz.orders WHERE user_id = ? ORDER BY created_at DESC LIMIT 50",
                (rs, rowNum) -> rs.getString(1), userId);
        List<OrderView> views = new ArrayList<>();
        for (String orderNo : orderNos) {
            views.add(toView(orderNo));
        }
        return views;
    }

    // ------------------------------------------------------------------ 内部

    /**
     * 扣一件商品的库存。
     *
     * <p>{@code stock >= ?} 这个条件就是全部并发控制：不需要分布式锁，也不需要 SELECT FOR UPDATE，
     * 因为"判断够不够 + 扣减"是同一个 UPDATE 里的原子动作。
     */
    private void decrementStock(CartView.Line line) {
        List<Long> skuIds = jdbc.query(
                "SELECT id FROM biz.product_sku WHERE product_id = ? ORDER BY id LIMIT 1",
                (rs, rowNum) -> rs.getLong(1), line.productId());
        if (skuIds.isEmpty()) {
            throw new BizException(409, line.model() + " 缺少库存记录，暂时无法下单");
        }
        int affected = jdbc.update(
                "UPDATE biz.product_sku SET stock = stock - ? WHERE id = ? AND stock >= ?",
                line.qty(), skuIds.get(0), line.qty());
        if (affected == 0) {
            throw new BizException(409, line.model() + " 库存不足（要 " + line.qty() + " 件）");
        }
    }

    private OrderView findByIdemKey(long userId, String idemKey) {
        if (idemKey == null || idemKey.isBlank()) {
            return null;
        }
        List<String> orderNos = jdbc.query(
                "SELECT order_no FROM biz.orders WHERE idem_key = ? AND user_id = ?",
                (rs, rowNum) -> rs.getString(1), idemKey, userId);
        return orderNos.isEmpty() ? null : toView(orderNos.get(0));
    }

    private OrderView toView(String orderNo) {
        List<OrderView.Line> items = new ArrayList<>();
        String[] head = new String[3];
        BigDecimal[] total = new BigDecimal[1];
        jdbc.query("""
                        SELECT order_no, status, total_amount, created_at FROM biz.orders WHERE order_no = ?
                        """,
                rs -> {
                    head[0] = rs.getString("order_no");
                    head[1] = rs.getString("status");
                    total[0] = rs.getBigDecimal("total_amount");
                    head[2] = String.valueOf(rs.getObject("created_at"));
                }, orderNo);
        jdbc.query("""
                        SELECT i.model_snapshot, i.price_snapshot, i.qty
                        FROM biz.order_item i JOIN biz.orders o ON o.id = i.order_id
                        WHERE o.order_no = ? ORDER BY i.id
                        """,
                rs -> {
                    items.add(new OrderView.Line(
                            rs.getString("model_snapshot"),
                            rs.getBigDecimal("price_snapshot"),
                            rs.getInt("qty")));
                }, orderNo);
        return new OrderView(head[0], head[1], total[0], head[2], items);
    }

    /** 订单号：时间 + 4 位随机，撞唯一索引的窗口极小；真撞了也会被 catch 住 */
    private static String nextOrderNo() {
        return "DG" + LocalDateTime.now().format(NO_FORMAT)
                + String.format("%04d", ThreadLocalRandom.current().nextInt(10000));
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
