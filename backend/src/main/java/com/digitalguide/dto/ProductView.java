package com.digitalguide.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record ProductView(Long id,
                          String brand,
                          String category,
                          String model,
                          String title,
                          BigDecimal priceRef,
                          List<String> highlights,
                          String imageUrl,
                          LocalDate launchDate) {
}
