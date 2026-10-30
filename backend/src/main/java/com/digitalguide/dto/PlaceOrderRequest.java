package com.digitalguide.dto;

import jakarta.validation.constraints.Size;

/**
 * 下单请求。
 *
 * @param idemKey 客户端生成的幂等键。同一个键重复提交只会落一单——
 *                这是为了让"用户连点两下"和"网络重发"不会变成两张订单。
 */
public record PlaceOrderRequest(
        @Size(max = 64, message = "idemKey 过长")
        String idemKey
) {
}
