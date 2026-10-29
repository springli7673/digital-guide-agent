package com.digitalguide.service;

import com.digitalguide.common.BizException;
import com.digitalguide.domain.Category;
import com.digitalguide.dto.CategoryRequest;
import com.digitalguide.mapper.CategoryMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryMapper categoryMapper;
    private final ObjectMapper objectMapper;

    public List<Category> list() {
        return categoryMapper.selectList(Wrappers.<Category>lambdaQuery().orderByAsc(Category::getSort));
    }

    public Category getByCode(String code) {
        Category category = categoryMapper.selectOne(Wrappers.<Category>lambdaQuery().eq(Category::getCode, code));
        if (category == null) {
            throw new BizException(404, "类目不存在：" + code);
        }
        return category;
    }

    public Category create(CategoryRequest request) {
        Category category = new Category();
        category.setCode(request.code());
        category.setName(request.name());
        category.setSort(request.sort() == null ? 0 : request.sort());
        try {
            category.setSpecSchema(objectMapper.writeValueAsString(
                    request.specSchema() == null ? java.util.Map.of() : request.specSchema()));
        } catch (Exception e) {
            throw new BizException(400, "specSchema 不是合法 JSON");
        }
        categoryMapper.insert(category);
        return category;
    }
}
