package com.digitalguide.dto;

import java.util.Map;

public record CategoryRequest(String code, String name, Map<String, Object> specSchema, Integer sort) {
}
