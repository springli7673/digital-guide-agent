package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.dto.LoginRequest;
import com.digitalguide.dto.LoginResponse;
import com.digitalguide.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @PostMapping("/login")
    public R<LoginResponse> login(@RequestBody @Valid LoginRequest request) {
        return R.ok(userService.login(request.username(), request.password()));
    }
}
