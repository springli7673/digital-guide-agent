package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.common.UserContext;
import com.digitalguide.dto.ConfirmRequest;
import com.digitalguide.dto.OrderView;
import com.digitalguide.dto.PendingActionView;
import com.digitalguide.dto.PlaceOrderRequest;
import com.digitalguide.service.OrderService;
import com.digitalguide.service.PendingActionService;
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
    private final PendingActionService pendingActions;

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

    /**
     * 当前待确认动作（聊天结束后查一次）。
     *
     * <p>为什么不把 confirmId 塞进 SSE：那是"模型说的话"，容易被改写成别的样子；
     * 单独一个接口读出来，前端才知道该渲染哪个按钮。
     */
    @GetMapping("/pending")
    public R<PendingActionView> pending() {
        return R.ok(pendingActions.current(UserContext.require()));
    }

    /**
     * 确认并执行。
     *
     * <p>这是**唯一**真正会写订单的入口（除了直接调 POST /api/orders）。
     * confirmId 作废是原子的，且它同时被当作幂等键，所以连点也只会落一单。
     */
    @PostMapping("/confirm")
    public R<OrderView> confirm(@RequestBody @Valid ConfirmRequest request) {
        long userId = UserContext.require();
        PendingActionView action = pendingActions.consume(request.confirmId(), userId);
        // confirmId 就是幂等键：万一 consume 之后下游重试，第二次会命中同一单
        return R.ok(orderService.placeFromCart(userId, action.confirmId()));
    }
}
