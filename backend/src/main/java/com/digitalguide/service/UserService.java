package com.digitalguide.service;

import com.digitalguide.auth.TokenService;
import com.digitalguide.common.BizException;
import com.digitalguide.common.HashUtil;
import com.digitalguide.domain.User;
import com.digitalguide.dto.LoginResponse;
import com.digitalguide.mapper.UserMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final TokenService tokenService;

    public LoginResponse login(String username, String password) {
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
        if (user == null || !HashUtil.sha256(password).equals(user.getPasswordHash())) {
            throw new BizException(401, "账号或密码错误");
        }
        String token = tokenService.issue(user.getId());
        return new LoginResponse(token, user.getId(), user.getNickname());
    }
}
