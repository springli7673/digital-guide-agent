package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.common.UserContext;
import com.digitalguide.dto.OrderView;
import com.digitalguide.dto.PlaceOrderRequest;
import com.digitalguide.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 订单接口。下单只是"把购物车结算掉"，没有独立的下单页参数。 */
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /**
     * 从购物车下单。
     *
     * <p>{@code idemKey} 由前端在点"提交"时生成一次，重试/连点都带同一个。
     * 不带也能下单（当成非幂等），但前端应该总是带上。
     */
    @PostMapping
    public R<OrderView> place(@RequestBody(required = false) @Valid PlaceOrderRequest request) {
        String idemKey = request == null ? null : request.idemKey();
        return R.ok(orderService.placeFromCart(UserContext.require(), idemKey));
    }

    @GetMapping
    public R<List<OrderView>> myOrders() {
        return R.ok(orderService.myOrders(UserContext.require()));
    }
}
