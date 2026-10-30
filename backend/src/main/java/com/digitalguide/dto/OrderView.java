package com.digitalguide.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * 订单视图。
 *
 * <p>明细里的 {@code model} / {@code price} 来自 {@code order_item} 的快照，
 * 不是现查商品表——商品改名或调价后，历史订单必须原样显示。
 */
public record OrderView(
        String orderNo,
        String status,
        BigDecimal totalAmount,
        String createdAt,
        List<Line> items
) {

    public record Line(String model, BigDecimal price, int qty) {
    }
}
