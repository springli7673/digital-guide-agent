package com.digitalguide.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.digitalguide.auth.TokenService;
import com.digitalguide.common.BizException;
import com.digitalguide.common.HashUtil;
import com.digitalguide.domain.User;
import com.digitalguide.dto.LoginResponse;
import com.digitalguide.dto.UserProfile;
import com.digitalguide.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

/**
 * 账号相关业务。
 *
 * <p>密码只存 SHA-256，不存明文、也不回显。这里刻意不引 BCrypt：
 * 项目没有额外依赖，而且对课程/个人项目来说 SHA-256 + 足够长的密码已经够用；
 * 生产环境该换成 BCrypt/Argon2（它们带盐和计算成本），这一点要能自己说出来。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final TokenService tokenService;

    public LoginResponse login(String username, String password) {
        User user = findByUsername(username);
        if (user == null || !HashUtil.sha256(password).equals(user.getPasswordHash())) {
            // 账号不存在和密码错误返回同一个错误：不要告诉攻击者"这个用户名存在"
            throw new BizException(401, "账号或密码错误");
        }
        String token = tokenService.issue(user.getId());
        return new LoginResponse(token, user.getId(), user.getNickname());
    }

    public LoginResponse register(String username, String password, String nickname) {
        if (findByUsername(username) != null) {
            throw new BizException(409, "用户名已被占用");
        }
        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(HashUtil.sha256(password));
        user.setNickname(nickname == null || nickname.isBlank() ? username : nickname.trim());
        try {
            userMapper.insert(user);
        } catch (DuplicateKeyException e) {
            // 并发注册同一个名字时，唯一约束会在这里抛出来，
            // 比"先查再插"更可靠——查和插之间的窗口期挡不住并发。
            throw new BizException(409, "用户名已被占用");
        }
        return new LoginResponse(tokenService.issue(user.getId()), user.getId(), user.getNickname());
    }

    public UserProfile profile(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(404, "用户不存在");
        }
        return new UserProfile(user.getId(), user.getUsername(), user.getNickname(), user.getCreatedAt());
    }

    /** 登出：把 token 从 Redis 删掉即可（token 不是 JWT，没有本地校验环节） */
    public void logout(String token) {
        if (token != null && !token.isBlank()) {
            tokenService.revoke(token);
        }
    }

    private User findByUsername(String username) {
        if (username == null || username.isBlank()) {
            return null;
        }
        return userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getUsername, username));
    }
}
