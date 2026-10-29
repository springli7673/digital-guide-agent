package com.digitalguide.ai.scoring;

import com.digitalguide.domain.Category;
import com.digitalguide.service.CategoryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * 从 {@code biz.category.spec_schema} 读打分权重，读不到就退回兜底。
 *
 * <p>单独抽一个组件，是为了让 {@link ScoringService} 保持"零依赖纯函数"——
 * 打分算法能被单测直接钉死，不用起 Spring、不用连库。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SpecSchemaProvider {

    private final CategoryService categoryService;
    private final ObjectMapper objectMapper;

    public Map<String, SpecSchema.Dim> schemaFor(String categoryCode) {
        try {
            Category category = categoryService.getByCode(categoryCode);
            return SpecSchema.parseOrDefault(category.getSpecSchema(), objectMapper);
        } catch (Exception e) {
            // 类目不存在 / 库连不上 / JSON 坏了，都不该让一次推荐挂掉
            log.warn("读取类目 {} 的 spec_schema 失败，使用兜底权重：{}", categoryCode, e.getMessage());
            return "phone".equals(categoryCode) ? SpecSchema.DEFAULT_SPEC_SCHEMA : Map.of();
        }
    }
}
