package com.digitalguide.dto;

import java.time.OffsetDateTime;

/** 当前登录用户的信息（不含任何密码相关字段）。 */
public record UserProfile(Long id, String username, String nickname, OffsetDateTime createdAt) {
}
