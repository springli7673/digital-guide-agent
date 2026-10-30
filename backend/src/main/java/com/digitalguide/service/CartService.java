package com.digitalguide.service;

import com.digitalguide.common.BizException;
import com.digitalguide.dto.CartView;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * 购物车。
 *
 * <p>三个刻意的决定：
 * <ol>
 *   <li><b>价格只认 {@code biz.product.price_ref}</b>。{@code product_sku.price_ref} 里有
 *       86 条还是顶配价（历史遗留），一律不读，否则用户会看到 20499 的 iPhone 18 Pro；</li>
 *   <li><b>金额由这里算</b>，不接受前端传价格——前端算合计和订单金额对不上是电商经典 bug；</li>
 *   <li><b>不加 Redis</b>。购物车要的是一致性，不是速度；记错了比慢更糟。</li>
 * </ol>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CartService {

    private static final int MAX_QTY = 99;

    private final JdbcTemplate jdbc;

    public CartView view(long userId) {
        List<CartView.Line> lines = lines(userId);
        BigDecimal total = BigDecimal.ZERO;
        int totalQty = 0;
        for (CartView.Line line : lines) {
            total = total.add(line.subtotal());
            totalQty += line.qty();
        }
        return new CartView(lines, total.setScale(2, RoundingMode.HALF_UP), totalQty);
    }

    /** 购物车明细（不含合计）。下单也复用它，避免两处算法不一致。 */
    public List<CartView.Line> lines(long userId) {
        List<CartView.Line> lines = new ArrayList<>();
        jdbc.query("""
                        SELECT c.id, c.product_id, c.qty, c.price_snapshot,
                               p.model, p.image_url, p.price_ref, b.name AS brand
                        FROM biz.cart_item c
                        JOIN biz.product p ON p.id = c.product_id
                        JOIN biz.brand b   ON b.id = p.brand_id
                        WHERE c.user_id = ?
                        ORDER BY c.created_at DESC
                        """,
                rs -> {
                    BigDecimal price = rs.getBigDecimal("price_ref");
                    int qty = rs.getInt("qty");
                    BigDecimal snapshot = rs.getBigDecimal("price_snapshot");
                    // 价格缺失（1 款商品没有报价）按 0 处理，不阻断查看购物车
                    BigDecimal effective = price == null ? BigDecimal.ZERO : price;
                    lines.add(new CartView.Line(
                            rs.getLong("id"),
                            rs.getLong("product_id"),
                            rs.getString("brand"),
                            rs.getString("model"),
                            rs.getString("image_url"),
                            effective,
                            qty,
                            effective.multiply(BigDecimal.valueOf(qty)).setScale(2, RoundingMode.HALF_UP),
                            snapshot == null || effective.compareTo(snapshot) != 0));
                },
                userId);
        return lines;
    }

    /** 加入购物车：已存在就走 qty 累加，靠唯一约束保证同一商品的同一用户只有一行 */
    public void add(long userId, long productId, int qty) {
        if (qty <= 0 || qty > MAX_QTY) {
            throw new BizException(400, "数量必须在 1-99 之间");
        }
        BigDecimal price = findOnSalePrice(productId);
        int affected = jdbc.update("""
                        INSERT INTO biz.cart_item (user_id, product_id, qty, price_snapshot)
                        VALUES (?, ?, ?, ?)
                        ON CONFLICT (user_id, product_id) DO UPDATE
                        SET qty = LEAST(biz.cart_item.qty + EXCLUDED.qty, 99), updated_at = now()
                        """,
                userId, productId, qty, price);
        log.debug("加入购物车：user={} product={} qty={} affected={}", userId, productId, qty, affected);
    }

    /** 改成绝对数量；归属校验放在 WHERE 里，别人的行改不动 */
    public void updateQty(long userId, long cartId, int qty) {
        if (qty <= 0 || qty > MAX_QTY) {
            throw new BizException(400, "数量必须在 1-99 之间");
        }
        int affected = jdbc.update(
                "UPDATE biz.cart_item SET qty = ?, updated_at = now() WHERE id = ? AND user_id = ?",
                qty, cartId, userId);
        if (affected == 0) {
            throw new BizException(404, "购物车里没有这一行");
        }
    }

    public void remove(long userId, long cartId) {
        int affected = jdbc.update("DELETE FROM biz.cart_item WHERE id = ? AND user_id = ?", cartId, userId);
        if (affected == 0) {
            throw new BizException(404, "购物车里没有这一行");
        }
    }

    public void clear(long userId) {
        jdbc.update("DELETE FROM biz.cart_item WHERE user_id = ?", userId);
    }

    /** 商品必须在售；顺便把价格取出来当快照 */
    private BigDecimal findOnSalePrice(long productId) {
        List<BigDecimal> prices = jdbc.query(
                "SELECT price_ref FROM biz.product WHERE id = ? AND status = 'ON_SALE'",
                (rs, rowNum) -> rs.getBigDecimal(1), productId);
        if (prices.isEmpty()) {
            throw new BizException(404, "商品不存在或已下架");
        }
        BigDecimal price = prices.get(0);
        return price == null ? BigDecimal.ZERO : price;
    }
}
