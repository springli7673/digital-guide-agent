package com.digitalguide.dto;

public record LoginResponse(String token, Long userId, String nickname) {
}
