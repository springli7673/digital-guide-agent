package com.digitalguide.dto;

import jakarta.validation.constraints.NotBlank;

/** 确认执行。 */
public record ConfirmRequest(@NotBlank(message = "confirmId 不能为空") String confirmId) {
}
