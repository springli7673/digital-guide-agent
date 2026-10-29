package com.digitalguide.ai.intent;

import com.digitalguide.ai.scoring.SpecSchema;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 意图相关的常量与两个转换：wire（内部 → 前端事件）和 clarify（追问话术）。
 *
 * <p>前后端只认 wire 这一种形状，协议见 web/src/agent.js 顶部注释；
 * 改这里必须同步改前端。
 */
public final class Intents {

    public static final Map<String, String> CATEGORY_LABELS = Map.of(
            "phone", "手机",
            "earbuds", "耳机",
            "camera", "相机",
            "powerbank", "充电宝",
            "tablet", "平板",
            // 不是商品品类，而是"问知识"：走 RAG，不查商品库
            "knowledge", "选购知识",
            // 需要多步工具调用的追问：对比两款、查某款详情
            "followup", "机型对比");

    /** 打分维度白名单：模型只能在里面挑，防止它自由发挥造字段 */
    public static final Set<String> DIMENSION_KEYS = SpecSchema.PREF_LABELS.keySet();

    /** 品牌白名单（库里有货的 9 个） */
    public static final List<String> BRANDS = List.of(
            "苹果", "华为", "小米", "红米", "vivo", "OPPO", "荣耀", "一加", "iQOO");

    public static final List<String> BUDGET_OPTIONS =
            List.of("2000 元以内", "3000 元左右", "5000 元以内", "不限预算，只看参数");

    public static final List<String> PREF_OPTIONS =
            List.of("续航优先", "拍照优先", "轻薄优先", "打游戏为主", "都行，按综合参数排");

    private Intents() {
    }

    /**
     * 内部 intent → 前端 intent 事件。
     * budget 为 null 表示"完全没表态"；有 min 或 max 才给对象。
     */
    public static Map<String, Object> wire(Intent intent) {
        List<Map<String, Object>> prefs = new ArrayList<>();
        for (String key : intent.mustHave()) {
            prefs.add(pref(key, "must"));
        }
        for (String key : intent.niceToHave()) {
            prefs.add(pref(key, "nice"));
        }

        Map<String, Object> budget = null;
        if (intent.hasBudget()) {
            budget = new LinkedHashMap<>();
            budget.put("min", intent.budgetMin());
            budget.put("max", intent.budgetMax());
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("category", intent.category());
        payload.put("categoryLabel", intent.categoryLabel());
        payload.put("budget", budget);
        payload.put("prefs", prefs);
        payload.put("brands", intent.brands());
        payload.put("usage", intent.usage());
        return payload;
    }

    /**
     * 追问只问真正缺的那一项。
     * 原来写死成预算四档，导致"问偏好"的时候也弹预算选项。
     */
    public static Map<String, Object> clarify(Intent intent) {
        String question;
        List<String> options;
        if (!intent.budgetKnown()) {
            question = intent.clarifyQuestion().isBlank()
                    ? "预算大概多少？有区间我才能把候选缩到合理范围。"
                    : intent.clarifyQuestion();
            options = BUDGET_OPTIONS;
        } else {
            question = "还有其他偏好吗？没有的话我直接按综合参数排序。";
            options = PREF_OPTIONS;
        }
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("question", question);
        payload.put("options", options);
        return payload;
    }

    /** 去重保序，用于"重点：续航、影像"这类文案 */
    public static String describePrefs(Intent intent) {
        LinkedHashSet<String> labels = new LinkedHashSet<>();
        for (String key : intent.mustHave()) {
            labels.add(SpecSchema.labelOf(key));
        }
        for (String key : intent.niceToHave()) {
            labels.add(SpecSchema.labelOf(key));
        }
        return labels.isEmpty() ? "综合性价比" : String.join("、", labels);
    }

    /** 预算区间的中文描述 */
    public static String priceRangeText(Intent intent) {
        Integer low = intent.budgetMin();
        Integer high = intent.budgetMax();
        if (low != null && high != null) {
            return yuan(low) + "–" + yuan(high);
        }
        if (high != null) {
            return yuan(high) + " 以内";
        }
        if (low != null) {
            return yuan(low) + " 以上";
        }
        return "不限预算";
    }

    public static String yuan(Number value) {
        if (value == null) {
            return "暂无报价";
        }
        return "¥" + String.format("%,d", Math.round(value.doubleValue()));
    }

    private static Map<String, Object> pref(String key, String priority) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("key", key);
        item.put("label", SpecSchema.labelOf(key));
        item.put("priority", priority);
        return item;
    }
}
