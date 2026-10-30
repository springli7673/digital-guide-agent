package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.common.UserContext;
import com.digitalguide.dto.LoginRequest;
import com.digitalguide.dto.LoginResponse;
import com.digitalguide.dto.RegisterRequest;
import com.digitalguide.dto.UserProfile;
import com.digitalguide.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 账号接口。
 *
 * <p>{@code /login} 与 {@code /register} 是匿名可访问的，
 * {@code /me} 与 {@code /logout} 走拦截器（见 {@code WebConfig} 的排除列表）。
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/login")
    public R<LoginResponse> login(@RequestBody @Valid LoginRequest request) {
        return R.ok(userService.login(request.username(), request.password()));
    }

    /** 注册成功直接返回 token，省掉一次"注册完再登录"的往返 */
    @PostMapping("/register")
    public R<LoginResponse> register(@RequestBody @Valid RegisterRequest request) {
        return R.ok(userService.register(request.username(), request.password(), request.nickname()));
    }

    @GetMapping("/me")
    public R<UserProfile> me() {
        return R.ok(userService.profile(UserContext.require()));
    }

    @PostMapping("/logout")
    public R<Void> logout(HttpServletRequest request) {
        userService.logout(bearer(request));
        return R.ok();
    }

    private static String bearer(HttpServletRequest request) {
        String auth = request.getHeader("Authorization");
        return auth != null && auth.startsWith("Bearer ") ? auth.substring(7) : null;
    }
}
