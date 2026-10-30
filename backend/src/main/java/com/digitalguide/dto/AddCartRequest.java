package com.digitalguide.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/** 加入购物车。 */
public record AddCartRequest(
        @NotNull(message = "productId 不能为空")
        @Positive(message = "productId 非法")
        Long productId,

        @Min(value = 1, message = "数量至少 1 件")
        @Max(value = 99, message = "单次最多 99 件")
        Integer qty
) {

    public int qtyOrDefault() {
        return qty == null ? 1 : qty;
    }
}
