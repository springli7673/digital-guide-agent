package com.digitalguide.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * 购物车视图。
 *
 * <p>金额一律由 SQL/Java 按 {@code biz.product.price_ref} 算出来，**不接受前端传价格**。
 * {@code price} 是当前价，{@code priceChanged} 表示它和加购时的快照不一致——
 * 前端据此提示"价格有变动"，而不是自己比较。
 */
public record CartView(List<Line> items, BigDecimal total, int totalQty) {

    /**
     * @param priceChanged 当前价与加购时快照不一致（可能是你改了价，也可能是数据修过）
     */
    public record Line(
            long cartId,
            long productId,
            String brand,
            String model,
            String imageUrl,
            BigDecimal price,
            int qty,
            BigDecimal subtotal,
            boolean priceChanged
    ) {
    }
}
