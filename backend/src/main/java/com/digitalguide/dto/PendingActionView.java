package com.digitalguide.dto;

import java.math.BigDecimal;

/**
 * 待确认动作（给前端渲染"确认"按钮用）。
 *
 * <p>{@code confirmId} 同时是下单的幂等键，所以重复点确认只会落一单。
 */
public record PendingActionView(
        String confirmId,
        String type,
        String summary,
        BigDecimal total,
        int itemCount
) {
}
