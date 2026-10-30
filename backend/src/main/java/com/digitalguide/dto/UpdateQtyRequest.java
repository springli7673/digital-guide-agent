package com.digitalguide.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** 修改购物车某行的数量（绝对值，不是增量）。 */
public record UpdateQtyRequest(
        @NotNull(message = "qty 不能为空")
        @Min(value = 1, message = "数量至少 1 件")
        @Max(value = 99, message = "单件最多 99 件")
        Integer qty
) {
}
