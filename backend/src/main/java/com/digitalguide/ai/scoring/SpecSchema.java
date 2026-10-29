package com.digitalguide.ai.scoring;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 参数打分用的维度定义。
 *
 * <p>权重优先读 {@code biz.category.spec_schema}（库里的那份是唯一的真相），
 * 读不到才退回这里的兜底，兜底值必须和 db/seed_products.sql 里的手机类目保持一致。
 */
public final class SpecSchema {

    /** 一个打分维度 */
    public record Dim(String label, String unit, String better, double weight) {

        public boolean lowerIsBetter() {
            return "lower".equals(better);
        }
    }

    /** 兜底权重（与库里手机类目一致） */
    public static final Map<String, Dim> DEFAULT_SPEC_SCHEMA;

    /** 偏好的中文名，用于话术 */
    public static final Map<String, String> PREF_LABELS;

    static {
        Map<String, Dim> dims = new LinkedHashMap<>();
        dims.put("battery_mah", new Dim("电池容量", "mAh", "higher", 1.0));
        dims.put("charge_w", new Dim("充电功率", "W", "higher", 0.7));
        dims.put("image_score", new Dim("影像梯队", "分", "higher", 1.0));
        dims.put("dxo_camera", new Dim("DXO 影像", "分", "higher", 0.5));
        dims.put("rear_mp", new Dim("后置主摄", "万像素", "higher", 0.6));
        dims.put("cpu_score", new Dim("处理器", "分", "higher", 0.8));
        dims.put("weight_g", new Dim("重量", "g", "lower", 0.5));
        dims.put("refresh_hz", new Dim("刷新率", "Hz", "higher", 0.4));
        dims.put("screen_inch", new Dim("屏幕尺寸", "英寸", "higher", 0.3));
        dims.put("ram", new Dim("运行内存", "GB", "higher", 0.6));
        // 用 LinkedHashMap 包一层而不是 Map.copyOf：后者不保证迭代顺序，
        // 而维度顺序会进到"优势"文案的排序里，顺序不稳会让测试时好时坏
        DEFAULT_SPEC_SCHEMA = Collections.unmodifiableMap(new LinkedHashMap<>(dims));

        Map<String, String> labels = new LinkedHashMap<>();
        labels.put("battery_mah", "续航");
        labels.put("charge_w", "快充");
        labels.put("image_score", "影像");
        labels.put("dxo_camera", "DXO 影像");
        labels.put("rear_mp", "高像素");
        labels.put("cpu_score", "性能");
        labels.put("weight_g", "轻薄");
        labels.put("refresh_hz", "高刷");
        labels.put("screen_inch", "大屏");
        labels.put("ram", "性能");
        PREF_LABELS = Collections.unmodifiableMap(new LinkedHashMap<>(labels));
    }

    private SpecSchema() {
    }

    public static String labelOf(String key) {
        return PREF_LABELS.getOrDefault(key, key);
    }

    /**
     * 把 {@code biz.category.spec_schema} 的 JSON 解析成维度表。
     * 解析不出来或空的，退回兜底——类目配置坏了不能让整个推荐挂掉。
     */
    public static Map<String, Dim> parseOrDefault(String json, ObjectMapper objectMapper) {
        if (json == null || json.isBlank()) {
            return DEFAULT_SPEC_SCHEMA;
        }
        try {
            JsonNode root = objectMapper.readTree(json);
            if (!root.isObject()) {
                return DEFAULT_SPEC_SCHEMA;
            }
            Map<String, Dim> dims = new LinkedHashMap<>();
            root.fields().forEachRemaining(entry -> {
                JsonNode node = entry.getValue();
                if (!node.isObject()) {
                    return;
                }
                String label = node.path("label").asText(entry.getKey());
                String unit = node.path("unit").asText("");
                String better = node.path("better").asText("higher");
                double weight = node.path("weight").asDouble(1.0);
                dims.put(entry.getKey(), new Dim(label, unit, better, weight));
            });
            return dims.isEmpty() ? DEFAULT_SPEC_SCHEMA : Map.copyOf(dims);
        } catch (Exception e) {
            return DEFAULT_SPEC_SCHEMA;
        }
    }
}
