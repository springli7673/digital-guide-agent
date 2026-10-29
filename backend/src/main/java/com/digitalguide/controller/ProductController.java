package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.dto.PageResult;
import com.digitalguide.dto.ProductView;
import com.digitalguide.service.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {

    private final ProductService productService;

    @GetMapping
    public R<PageResult<ProductView>> list(@RequestParam(required = false) String category,
                                           @RequestParam(required = false) String brand,
                                           @RequestParam(required = false) String keyword,
                                           @RequestParam(required = false) BigDecimal minPrice,
                                           @RequestParam(required = false) BigDecimal maxPrice,
                                           @RequestParam(defaultValue = "1") int page,
                                           @RequestParam(defaultValue = "20") int size) {
        return R.ok(productService.page(category, brand, keyword, minPrice, maxPrice, page, Math.min(size, 100)));
    }

    @GetMapping("/{id}")
    public R<Map<String, Object>> detail(@PathVariable Long id) {
        return R.ok(productService.detail(id));
    }
}
