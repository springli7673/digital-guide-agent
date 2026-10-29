package com.digitalguide.ai.tool;

import com.digitalguide.ai.intent.Intents;
import com.digitalguide.ai.mcp.McpToolTarget;
import com.digitalguide.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 给模型用的工具集。
 *
 * <p>设计原则（都是踩过坑才这么写的）：
 * <ul>
 *   <li><b>工具少</b>：只有 3 个。工具一多，模型选错的概率直线上升，
 *       而每个工具的描述成本也会摊薄它自己的注意力；</li>
 *   <li><b>参数少且类型简单</b>：int / String，不用枚举和嵌套对象——
 *       小模型对复杂 schema 的生成准确率明显更差；</li>
 *   <li><b>「不限」用 0 或空串表示</b>，而不是 null 或可选参数：
 *       可选参数最容易被模型漏填或瞎填；</li>
 *   <li><b>返回值是给人读的文本</b>，不是 JSON：模型接下来要基于它组织话术，
 *       结构化数据反而增加它的转换负担（要 JSON 的场合另说）。</li>
 * </ul>
 *
 * <p>工具内部全部走已有的 {@link ProductService}，不新开查询路径——
 * 工具层只是"把手伸出去让模型能调用"，不应该自己再实现一套业务。
 *
 * <p>同时实现 {@link McpToolTarget}：同一份实现既作为进程内 {@code @Tool} 暴露给本地模型，
 * 也能被 {@code McpServer} 包成跨进程 MCP 工具给外部 Agent 用。
 * 两条路径共用一套逻辑，不存在"两处实现慢慢漂移"的问题。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ProductTools implements McpToolTarget {

    /** 工具返回里最多列几款，太多会挤占模型的上下文 */
    private static final int MAX_ROWS = 5;

    private final ProductService productService;

    @Tool(description = """
            按预算和品牌检索在售手机，返回机型、参考价和关键参数。
            用户想买手机、或在问"有什么推荐""这个价位有什么"时用这个工具。""")
    public String searchPhones(
            @ToolParam(description = "最低价（元），不限就传 0") int minPrice,
            @ToolParam(description = "最高价（元），不限就传 0") int maxPrice,
            @ToolParam(description = "品牌名，多个用逗号分隔，如「小米,vivo」；不限就传空字符串") String brands) {

        BigDecimal min = minPrice > 0 ? BigDecimal.valueOf(minPrice) : null;
        BigDecimal max = maxPrice > 0 ? BigDecimal.valueOf(maxPrice) : null;
        List<String> brandList = brands == null || brands.isBlank()
                ? null
                : Arrays.stream(brands.split("[,，、\\s]+")).filter(s -> !s.isBlank()).toList();

        List<Map<String, Object>> rows = productService.searchForAgent("phone", min, max, brandList, 20);
        if (rows.isEmpty()) {
            return "没有符合条件的机型。可以放宽预算或去掉品牌限制。";
        }
        return formatRows(rows, MAX_ROWS);
    }

    @Tool(description = """
            查询某个具体机型的完整参数。用户提到一款具体手机、想知道它的详细配置时用这个工具。
            型号要来自检索结果，不要自己编。""")
    public String phoneDetail(
            @ToolParam(description = "机型名，如「Redmi K80」") String model) {
        Map<String, Object> found = findOne(model);
        if (found == null) {
            return "库里没有找到「" + model + "」这款机型。可以先用 searchPhones 查一下有哪些型号。";
        }
        StringBuilder builder = new StringBuilder();
        builder.append(found.get("brand")).append(' ').append(found.get("model"))
                .append("，参考价 ").append(priceText(found.get("priceRef"))).append('\n');
        builder.append("参数：").append(metricsText(found)).append('\n');
        Object highlights = found.get("highlights");
        if (highlights instanceof List<?> list && !list.isEmpty()) {
            builder.append("卖点：").append(String.join("；", list.stream().map(String::valueOf).toList()));
        }
        return builder.toString().trim();
    }

    @Tool(description = """
            对比两款机型的参数差异。用户问"这两个哪个好""有什么区别"时用这个工具。
            两个型号都要来自检索结果。""")
    public String comparePhones(
            @ToolParam(description = "第一款机型名") String modelA,
            @ToolParam(description = "第二款机型名") String modelB) {
        Map<String, Object> a = findOne(modelA);
        Map<String, Object> b = findOne(modelB);
        if (a == null) {
            return "库里没有找到「" + modelA + "」。";
        }
        if (b == null) {
            return "库里没有找到「" + modelB + "」。";
        }

        Map<String, Object> metricsA = metricsOf(a);
        Map<String, Object> metricsB = metricsOf(b);
        Map<String, String> labels = Map.of(
                "image_score", "影像梯队", "cpu_score", "处理器", "battery_mah", "电池",
                "charge_w", "充电", "weight_g", "重量", "screen_inch", "屏幕",
                "refresh_hz", "刷新率", "ram", "内存", "rom", "存储", "rear_mp", "主摄");

        StringBuilder builder = new StringBuilder();
        builder.append(a.get("brand")).append(' ').append(a.get("model"))
                .append("（").append(priceText(a.get("priceRef"))).append("） vs ")
                .append(b.get("brand")).append(' ').append(b.get("model"))
                .append("（").append(priceText(b.get("priceRef"))).append("）\n");

        for (Map.Entry<String, String> entry : new java.util.TreeMap<>(labels).entrySet()) {
            Object va = metricsA.get(entry.getKey());
            Object vb = metricsB.get(entry.getKey());
            if (va == null && vb == null) {
                continue;
            }
            builder.append(entry.getValue()).append('：')
                    .append(va == null ? "无数据" : va)
                    .append(" vs ")
                    .append(vb == null ? "无数据" : vb)
                    .append('\n');
        }
        return builder.toString().trim();
    }

    // ------------------------------------------------------------------ 内部

    /** 按型号模糊匹配一款；先精确包含，再退化为忽略大小写 */
    private Map<String, Object> findOne(String modelName) {
        if (modelName == null || modelName.isBlank()) {
            return null;
        }
        String needle = modelName.trim().toLowerCase().replace(" ", "");
        List<Map<String, Object>> all = productService.searchForAgent("phone", null, null, null, 500);

        Map<String, Object> fallback = null;
        for (Map<String, Object> row : all) {
            String brand = String.valueOf(row.getOrDefault("brand", ""));
            String model = String.valueOf(row.getOrDefault("model", ""));
            String combined = (brand + model).toLowerCase().replace(" ", "");
            if (combined.contains(needle)) {
                // 选最短的那个：防止 "K80" 命中 "K80 Pro Max" 这类更长的型号
                if (fallback == null || combined.length() <
                        String.valueOf(fallback.get("brand")).length()
                                + String.valueOf(fallback.get("model")).length()) {
                    fallback = row;
                }
            }
        }
        return fallback;
    }

    private String formatRows(List<Map<String, Object>> rows, int limit) {
        StringBuilder builder = new StringBuilder();
        int index = 1;
        for (Map<String, Object> row : rows) {
            if (index > limit) {
                break;
            }
            builder.append(index++).append(". ")
                    .append(row.get("brand")).append(' ').append(row.get("model"))
                    .append("，参考价 ").append(priceText(row.get("priceRef")))
                    .append("；").append(metricsText(row)).append('\n');
        }
        return builder.toString().trim();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> metricsOf(Map<String, Object> row) {
        Object specs = row.get("specs");
        if (!(specs instanceof Map<?, ?> specMap)) {
            return Map.of();
        }
        Object metrics = specMap.get("metrics");
        return metrics instanceof Map<?, ?> map ? (Map<String, Object>) map : Map.of();
    }

    private String metricsText(Map<String, Object> row) {
        Map<String, Object> metrics = metricsOf(row);
        Map<String, String> labels = new LinkedHashMap<>();
        labels.put("image_score", "影像");
        labels.put("cpu_score", "处理器");
        labels.put("battery_mah", "电池");
        labels.put("charge_w", "充电");
        labels.put("weight_g", "重量");

        List<String> parts = new ArrayList<>();
        labels.forEach((key, label) -> {
            Object value = metrics.get(key);
            if (value != null) {
                parts.add(label + " " + value);
            }
        });
        return parts.isEmpty() ? "参数缺失" : String.join("、", parts);
    }

    private String priceText(Object price) {
        return price instanceof Number number
                ? Intents.yuan(number)
                : "暂无报价";
    }
}
