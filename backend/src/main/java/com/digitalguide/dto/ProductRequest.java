package com.digitalguide.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public record ProductRequest(Long brandId,
                             Long categoryId,
                             String model,
                             String title,
                             LocalDate launchDate,
                             BigDecimal priceRef,
                             String priceSource,
                             Map<String, Object> specs,
                             List<String> highlights,
                             String imageUrl) {
}
