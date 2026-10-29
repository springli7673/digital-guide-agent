package com.digitalguide.dto;

import jakarta.validation.constraints.NotBlank;

public record BrandRequest(@NotBlank String name, String nameEn, String country, String logoUrl) {
}
