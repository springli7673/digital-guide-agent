package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.common.UserContext;
import com.digitalguide.dto.AddCartRequest;
import com.digitalguide.dto.CartView;
import com.digitalguide.dto.UpdateQtyRequest;
import com.digitalguide.service.CartService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 购物车接口。
 *
 * <p>每个写操作都返回**整个购物车**，而不是只返回 204：
 * 前端改完数量要立刻刷新合计，多一次往返没有意义。
 *
 * <p>身份一律从 {@link UserContext} 取（拦截器已校验 token），
 * 不接受请求体里传 userId —— 那样改个参数就能操作别人的购物车。
 */
@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @GetMapping
    public R<CartView> view() {
        return R.ok(cartService.view(UserContext.require()));
    }

    @PostMapping
    public R<CartView> add(@RequestBody @Valid AddCartRequest request) {
        long userId = UserContext.require();
        cartService.add(userId, request.productId(), request.qtyOrDefault());
        return R.ok(cartService.view(userId));
    }

    @PutMapping("/{id}")
    public R<CartView> updateQty(@PathVariable long id, @RequestBody @Valid UpdateQtyRequest request) {
        long userId = UserContext.require();
        cartService.updateQty(userId, id, request.qty());
        return R.ok(cartService.view(userId));
    }

    @DeleteMapping("/{id}")
    public R<CartView> remove(@PathVariable long id) {
        long userId = UserContext.require();
        cartService.remove(userId, id);
        return R.ok(cartService.view(userId));
    }

    @DeleteMapping
    public R<CartView> clear() {
        long userId = UserContext.require();
        cartService.clear(userId);
        return R.ok(cartService.view(userId));
    }
}
