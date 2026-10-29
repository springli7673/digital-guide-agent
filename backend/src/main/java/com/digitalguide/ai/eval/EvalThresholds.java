package com.digitalguide.ai.eval;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 判定基准：各维度的 P25 / P50 / P75，按"全库"和"预算内"两种口径准备。
 *
 * <p>必须用全库分位而不是候选集分位：接口只回 top3，在 3 个数上算 P75 等于取最大值，
 * 要求"top3 里 2 个 ≥ 最大值"永远不可能达成（旧版实测误判了 6 条）。
 * 预算条件存在时改用预算内的分布，否则"5000 以内拍照好"会拿全库旗舰当基准。
 *
 * <p>数据源是 {@code data/normalized/products.json}（和旧版 Python 一致），
 * 不是数据库——评测基准应该独立于被测服务，服务挂了也要能算线。
 */
@Slf4j
public final class EvalThresholds {

    /** 参与判定线的维度（和旧版一致） */
    public static final List<String> DIMS = List.of(
            "image_score", "cpu_score", "battery_mah", "weight_g",
            "charge_w", "screen_inch", "refresh_hz");

    public record Stats(double p25, double p50, double p75, int count) {
    }

    private final List<Map<String, Object>> products;

    private EvalThresholds(List<Map<String, Object>> products) {
        this.products = products;
    }

    @SuppressWarnings("unchecked")
    public static EvalThresholds load(Path productsJson) {
        if (productsJson == null || !Files.exists(productsJson)) {
            log.warn("找不到 {}，prefer 类判定会退化成「没有分布数据」", productsJson);
            return new EvalThresholds(List.of());
        }
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(Files.readString(productsJson));
            JsonNode list = root.has("products") ? root.get("products") : root;
            List<Map<String, Object>> rows = new ArrayList<>();
            for (JsonNode node : list) {
                rows.add(mapper.convertValue(node, Map.class));
            }
            log.info("评测基准：{} 款商品（{}）", rows.size(), productsJson);
            return new EvalThresholds(rows);
        } catch (Exception e) {
            log.warn("读取 {} 失败：{}", productsJson, e.getMessage());
            return new EvalThresholds(List.of());
        }
    }

    public boolean isEmpty() {
        return products.isEmpty();
    }

    public int productCount() {
        return products.size();
    }

    /** 全库分位 */
    public Map<String, Stats> global() {
        return quantiles(null, null);
    }

    /** 预算内分位；两个边界都为 null 时等价于全库 */
    public Map<String, Stats> within(Integer low, Integer high) {
        if (low == null && high == null) {
            return global();
        }
        return quantiles(low, high);
    }

    private Map<String, Stats> quantiles(Integer low, Integer high) {
        Map<String, Stats> out = new LinkedHashMap<>();
        for (String dim : DIMS) {
            List<Double> values = new ArrayList<>();
            for (Map<String, Object> product : products) {
                Double value = metric(product, dim);
                if (value == null) {
                    continue;
                }
                Double price = priceOf(product);
                if (low != null && (price == null || price < low)) {
                    continue;
                }
                if (high != null && (price == null || price > high)) {
                    continue;
                }
                values.add(value);
            }
            if (values.size() < 4) {
                continue;
            }
            Collections.sort(values);
            out.put(dim, new Stats(
                    Quantiles.at(values, 0.25),
                    Quantiles.at(values, 0.50),
                    Quantiles.at(values, 0.75),
                    values.size()));
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private static Double metric(Map<String, Object> product, String dim) {
        Object metrics = product.get("metrics");
        if (!(metrics instanceof Map<?, ?> map)) {
            return null;
        }
        Object value = map.get(dim);
        return value instanceof Number number ? number.doubleValue() : null;
    }

    private static Double priceOf(Map<String, Object> product) {
        Object price = product.get("price_ref");
        return price instanceof Number number ? number.doubleValue() : null;
    }
}
