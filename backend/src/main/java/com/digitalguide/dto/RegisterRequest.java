package com.digitalguide.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * 注册请求。
 *
 * <p>校验只放在 DTO 上，业务代码不再重复判断格式——但**唯一性必须在库里判**，
 * 因为"查一次再插入"在并发下挡不住重复注册，真正的兜底是 {@code biz.users.username} 的唯一约束。
 */
public record RegisterRequest(
        @NotBlank(message = "用户名不能为空")
        @Pattern(regexp = "^[A-Za-z0-9_]{3,32}$", message = "用户名只能是 3-32 位字母、数字或下划线")
        String username,

        @NotBlank(message = "密码不能为空")
        @Size(min = 6, max = 64, message = "密码长度需在 6-64 之间")
        String password,

        @Size(max = 32, message = "昵称最长 32 位")
        String nickname
) {
}
