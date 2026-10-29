package com.digitalguide.service;

import com.digitalguide.common.BizException;
import com.digitalguide.domain.Brand;
import com.digitalguide.domain.Category;
import com.digitalguide.domain.Product;
import com.digitalguide.domain.ProductSku;
import com.digitalguide.dto.PageResult;
import com.digitalguide.dto.ProductRequest;
import com.digitalguide.dto.ProductView;
import com.digitalguide.mapper.BrandMapper;
import com.digitalguide.mapper.CategoryMapper;
import com.digitalguide.mapper.ProductMapper;
import com.digitalguide.mapper.ProductSkuMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductMapper productMapper;
    private final ProductSkuMapper skuMapper;
    private final BrandMapper brandMapper;
    private final CategoryMapper categoryMapper;
    private final CategoryService categoryService;
    private final BrandService brandService;
    private final ObjectMapper objectMapper;

    public PageResult<ProductView> page(String categoryCode, String brandName, String keyword,
                                        BigDecimal minPrice, BigDecimal maxPrice, int pageNo, int pageSize) {
        LambdaQueryWrapper<Product> query = Wrappers.<Product>lambdaQuery()
                .eq(Product::getStatus, "ON_SALE")
                .orderByDesc(Product::getCreatedAt);

        if (StringUtils.hasText(categoryCode)) {
            query.eq(Product::getCategoryId, categoryService.getByCode(categoryCode).getId());
        }
        if (StringUtils.hasText(brandName)) {
            Brand brand = brandService.findByName(brandName);
            if (brand == null) {
                return new PageResult<>(0, pageNo, pageSize, List.of());
            }
            query.eq(Product::getBrandId, brand.getId());
        }
        if (StringUtils.hasText(keyword)) {
            query.and(w -> w.like(Product::getModel, keyword).or().like(Product::getTitle, keyword));
        }
        if (minPrice != null) {
            query.ge(Product::getPriceRef, minPrice);
        }
        if (maxPrice != null) {
            query.le(Product::getPriceRef, maxPrice);
        }

        Page<Product> result = productMapper.selectPage(new Page<>(pageNo, pageSize), query);
        return new PageResult<>(result.getTotal(), pageNo, pageSize, toViews(result.getRecords()));
    }

    public Map<String, Object> detail(Long id) {
        Product product = productMapper.selectById(id);
        if (product == null) {
            throw new BizException(404, "商品不存在");
        }
        Brand brand = brandMapper.selectById(product.getBrandId());
        Category category = categoryMapper.selectById(product.getCategoryId());
        List<ProductSku> skus = skuMapper.selectList(
                Wrappers.<ProductSku>lambdaQuery().eq(ProductSku::getProductId, id).orderByAsc(ProductSku::getPriceRef));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", product.getId());
        data.put("brand", brand == null ? null : brand.getName());
        data.put("category", category == null ? null : category.getCode());
        data.put("model", product.getModel());
        data.put("title", product.getTitle());
        data.put("priceRef", product.getPriceRef());
        data.put("priceSource", product.getPriceSource());
        data.put("launchDate", product.getLaunchDate());
        data.put("imageUrl", product.getImageUrl());
        data.put("specs", readJson(product.getSpecs(), new TypeReference<Map<String, Object>>() {
        }, Map.of()));
        data.put("highlights", readJson(product.getHighlights(), new TypeReference<List<String>>() {
        }, List.of()));
        data.put("skus", skus.stream().map(s -> Map.of(
                "storage", s.getStorage() == null ? "" : s.getStorage(),
                "color", s.getColor() == null ? "" : s.getColor(),
                "priceRef", s.getPriceRef() == null ? BigDecimal.ZERO : s.getPriceRef(),
                "stock", s.getStock() == null ? 0 : s.getStock()
        )).toList());
        return data;
    }

    public Long create(ProductRequest request) {
        Product product = new Product();
        apply(product, request);
        product.setStatus("ON_SALE");
        product.setDataSource("manual");
        product.setCreatedAt(OffsetDateTime.now());
        product.setPriceUpdatedAt(OffsetDateTime.now());
        productMapper.insert(product);
        return product.getId();
    }

    public void update(Long id, ProductRequest request) {
        Product product = productMapper.selectById(id);
        if (product == null) {
            throw new BizException(404, "商品不存在");
        }
        apply(product, request);
        product.setPriceUpdatedAt(OffsetDateTime.now());
        productMapper.updateById(product);
    }

    public void delete(Long id) {
        if (productMapper.deleteById(id) == 0) {
            throw new BizException(404, "商品不存在");
        }
    }

    /** 候选上限：147 款全库都装得下，涨到 500 款也够 */
    private static final int AGENT_CANDIDATE_LIMIT = 500;

    /**
     * 给 Agent 用的候选检索：硬条件在这里过滤，软排序交给 ScoringService。
     *
     * <p>候选集的完整性很重要——以前 Python 通过内部接口拿货，limit 被限死在 50，
     * 不限预算的查询只能拿到最便宜的 50 款，旗舰机根本进不了候选。
     * 进程内调用后这个限制没有了，那套"按 4 个价位段分别查再合并"的绕行逻辑也一起删掉了。
     */
    public List<Map<String, Object>> searchForAgent(String categoryCode, BigDecimal minPrice,
                                                    BigDecimal maxPrice, List<String> brands, int limit) {
        LambdaQueryWrapper<Product> query = Wrappers.<Product>lambdaQuery()
                .eq(Product::getStatus, "ON_SALE")
                .orderByAsc(Product::getPriceRef)
                .last("limit " + Math.min(Math.max(limit, 1), AGENT_CANDIDATE_LIMIT));

        if (StringUtils.hasText(categoryCode)) {
            query.eq(Product::getCategoryId, categoryService.getByCode(categoryCode).getId());
        }
        if (minPrice != null) {
            query.ge(Product::getPriceRef, minPrice);
        }
        if (maxPrice != null) {
            query.le(Product::getPriceRef, maxPrice);
        }
        if (brands != null && !brands.isEmpty()) {
            List<Long> ids = brands.stream()
                    .map(brandService::findByName)
                    .filter(java.util.Objects::nonNull)
                    .map(Brand::getId)
                    .toList();
            if (ids.isEmpty()) {
                return List.of();
            }
            query.in(Product::getBrandId, ids);
        }

        List<Product> products = productMapper.selectList(query);
        List<Map<String, Object>> result = new ArrayList<>();
        for (Product product : products) {
            Brand brand = brandMapper.selectById(product.getBrandId());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", product.getId());
            item.put("imageUrl", product.getImageUrl());
            item.put("brand", brand == null ? null : brand.getName());
            item.put("model", product.getModel());
            item.put("priceRef", product.getPriceRef());
            item.put("specs", readJson(product.getSpecs(), new TypeReference<Map<String, Object>>() {
            }, Map.of()));
            item.put("highlights", readJson(product.getHighlights(), new TypeReference<List<String>>() {
            }, List.of()));
            result.add(item);
        }
        return result;
    }

    private void apply(Product product, ProductRequest request) {
        product.setBrandId(request.brandId());
        product.setCategoryId(request.categoryId());
        product.setModel(request.model());
        product.setTitle(request.title());
        product.setLaunchDate(request.launchDate());
        product.setPriceRef(request.priceRef());
        product.setPriceSource(request.priceSource());
        product.setImageUrl(request.imageUrl());
        try {
            product.setSpecs(objectMapper.writeValueAsString(
                    request.specs() == null ? Map.of() : request.specs()));
            product.setHighlights(objectMapper.writeValueAsString(
                    request.highlights() == null ? List.of() : request.highlights()));
        } catch (Exception e) {
            throw new BizException(400, "specs / highlights 序列化失败");
        }
    }

    private List<ProductView> toViews(List<Product> products) {
        if (products.isEmpty()) {
            return List.of();
        }
        List<Long> brandIds = products.stream().map(Product::getBrandId).distinct().toList();
        List<Long> categoryIds = products.stream().map(Product::getCategoryId).distinct().toList();
        Map<Long, Brand> brands = brandMapper.selectBatchIds(brandIds).stream()
                .collect(Collectors.toMap(Brand::getId, Function.identity()));
        Map<Long, Category> categories = categoryMapper.selectBatchIds(categoryIds).stream()
                .collect(Collectors.toMap(Category::getId, Function.identity()));

        return products.stream().map(p -> new ProductView(
                p.getId(),
                brands.containsKey(p.getBrandId()) ? brands.get(p.getBrandId()).getName() : null,
                categories.containsKey(p.getCategoryId()) ? categories.get(p.getCategoryId()).getCode() : null,
                p.getModel(), p.getTitle(), p.getPriceRef(),
                readJson(p.getHighlights(), new TypeReference<List<String>>() {
                }, List.of()),
                p.getImageUrl(), p.getLaunchDate()
        )).toList();
    }

    private <T> T readJson(String json, TypeReference<T> type, T fallback) {
        if (!StringUtils.hasText(json)) {
            return fallback;
        }
        try {
            return objectMapper.readValue(json, type);
        } catch (Exception e) {
            return fallback;
        }
    }
}
