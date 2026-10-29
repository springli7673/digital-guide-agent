package com.digitalguide.controller;

import com.digitalguide.common.R;
import com.digitalguide.domain.Brand;
import com.digitalguide.domain.Category;
import com.digitalguide.dto.BrandRequest;
import com.digitalguide.dto.CategoryRequest;
import com.digitalguide.dto.ProductRequest;
import com.digitalguide.service.BrandService;
import com.digitalguide.service.CategoryService;
import com.digitalguide.service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 后台管理接口：品牌 / 类目 / 商品的增删改查。
 * 走 AuthInterceptor，需要登录。
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final BrandService brandService;
    private final CategoryService categoryService;
    private final ProductService productService;

    @GetMapping("/brands")
    public R<List<Brand>> brands() {
        return R.ok(brandService.list());
    }

    @PostMapping("/brands")
    public R<Brand> createBrand(@RequestBody @Valid BrandRequest request) {
        return R.ok(brandService.create(request));
    }

    @GetMapping("/categories")
    public R<List<Category>> categories() {
        return R.ok(categoryService.list());
    }

    @PostMapping("/categories")
    public R<Category> createCategory(@RequestBody CategoryRequest request) {
        return R.ok(categoryService.create(request));
    }

    @PostMapping("/products")
    public R<Long> createProduct(@RequestBody ProductRequest request) {
        return R.ok(productService.create(request));
    }

    @PutMapping("/products/{id}")
    public R<Void> updateProduct(@PathVariable Long id, @RequestBody ProductRequest request) {
        productService.update(id, request);
        return R.ok();
    }

    @DeleteMapping("/products/{id}")
    public R<Void> deleteProduct(@PathVariable Long id) {
        productService.delete(id);
        return R.ok();
    }
}
