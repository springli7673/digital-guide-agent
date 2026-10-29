package com.digitalguide.ai.tool;

import com.digitalguide.service.ProductService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 工具集的回归测试。
 *
 * <p>工具是模型能碰到的唯一"手脚"，它返回的文本就是模型的全部事实来源。
 * 所以这里重点钉两件事：<b>数据要对</b>（价格/参数别串行）、<b>说法要对</b>（找不到就说找不到）。
 */
class ProductToolsTest {

    private static final List<Map<String, Object>> ROWS = List.of(
            row("小米", "Redmi K80", 2199, Map.of("battery_mah", 6550, "cpu_score", 300)),
            row("小米", "Redmi K80 Pro Max", 3999, Map.of("battery_mah", 6000, "cpu_score", 400)),
            row("vivo", "iQOO Neo10", 2399, Map.of("battery_mah", 6100, "cpu_score", 320)));

    private final ProductTools tools = new ProductTools(new FakeProductService(ROWS));

    @Test
    @DisplayName("检索结果带型号、参考价和关键参数")
    void searchFormatsRows() {
        String text = tools.searchPhones(0, 0, "");

        assertThat(text).contains("Redmi K80");
        assertThat(text).contains("¥2,199");
        assertThat(text).contains("电池 6550");
        // 编号从 1 开始，方便模型引用
        assertThat(text).startsWith("1. ");
    }

    @Test
    @DisplayName("没有命中时明确说没有，不要让模型去猜")
    void searchEmpty() {
        ProductTools empty = new ProductTools(new FakeProductService(List.of()));
        assertThat(empty.searchPhones(9000, 12000, "欧珀")).contains("没有符合条件");
    }

    @Test
    @DisplayName("查详情：型号对上就返回参数，对不上就说没有")
    void detail() {
        String hit = tools.phoneDetail("iPhone 不存在");
        assertThat(hit).contains("没有找到");

        String found = tools.phoneDetail("Neo10");
        assertThat(found).contains("iQOO Neo10").contains("参考价").contains("参数：");
    }

    @Test
    @DisplayName("型号模糊匹配要选最短的那个，别让 K80 命中 K80 Pro Max")
    void shortestModelWins() {
        String detail = tools.phoneDetail("Redmi K80");
        assertThat(detail).contains("参考价 ¥2,199");
        assertThat(detail).doesNotContain("Pro Max");
    }

    @Test
    @DisplayName("对比：两款都列出来，缺数据的维度跳过")
    void compare() {
        String text = tools.comparePhones("K80", "Neo10");

        assertThat(text).contains("Redmi K80").contains("iQOO Neo10");
        assertThat(text).contains("电池：6550 vs 6100");
        assertThat(text).contains("处理器：300 vs 320");
        // 重量这批数据里没有，就该整行不出现，而不是写 "null vs null"
        assertThat(text).doesNotContain("重量：");
    }

    @Test
    @DisplayName("对比时任一款找不到都要说清楚是哪一款")
    void compareMissing() {
        assertThat(tools.comparePhones("K80", "不存在机型")).contains("没有找到「不存在机型」");
        assertThat(tools.comparePhones("不存在机型", "K80")).contains("没有找到「不存在机型」");
    }

    // ------------------------------------------------------------------ 构造

    private static Map<String, Object> row(String brand, String model, int price, Map<String, Object> metrics) {
        Map<String, Object> specs = new LinkedHashMap<>();
        specs.put("metrics", metrics);
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("brand", brand);
        item.put("model", model);
        item.put("priceRef", BigDecimal.valueOf(price));
        item.put("specs", specs);
        item.put("highlights", List.of("大电池"));
        return item;
    }

    private static final class FakeProductService extends ProductService {

        private final List<Map<String, Object>> rows;

        private FakeProductService(List<Map<String, Object>> rows) {
            super(null, null, null, null, null, null, null);
            this.rows = rows;
        }

        @Override
        public List<Map<String, Object>> searchForAgent(String categoryCode, BigDecimal minPrice,
                                                        BigDecimal maxPrice, List<String> brands, int limit) {
            return rows;
        }
    }
}
