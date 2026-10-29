package com.digitalguide.ai.intent;

import com.digitalguide.ai.scoring.SpecSchema;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 把模型输出清洗成可用的 Intent：白名单、数值边界、缺字段补默认值。
 *
 * <p>这里是"模型说了不算"的第一道闸门。模型可能返回不存在的维度键、
 * 负数预算、"3000 万"这种离谱区间，全部在这里被规整或丢弃。
 *
 * <p>另外补了一道程序化的预算边界守卫（{@link #lowerBoundOf(String)}）：
 * "一万以上" 这种说法交给 prompt 也能对，但实测模型偶尔会把它折算成某个分档，
 * 于是 b09 那条评测就返回了 ¥8999。能用正则兜住的就别指望模型。
 */
public final class IntentNormalizer {

    private static final int MIN_SANE_PRICE = 100;
    private static final int MAX_SANE_PRICE = 100_000;

    /** "3000以上 / 5000起 / 8000往上" */
    private static final Pattern DIGIT_LOWER_BOUND =
            Pattern.compile("(\\d{2,6})\\s*(?:元|块|rmb|¥)?\\s*(?:以上|起|往上|朝上|打底|起步)");

    /** "一万以上 / 两万起" */
    private static final Pattern WAN_LOWER_BOUND =
            Pattern.compile("([一二两三四五六七八九十]{1,2})\\s*万\\s*(?:元)?\\s*(?:以上|起|往上|朝上|打底)");

    /** "1.5万以上" */
    private static final Pattern WAN_DECIMAL_LOWER_BOUND =
            Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*万\\s*(?:元)?\\s*(?:以上|起|往上|朝上|打底)");

    private static final Map<String, Integer> CHINESE_DIGITS;

    static {
        // 11 组，超过 Map.of 的 10 组上限，用 Map.ofEntries
        CHINESE_DIGITS = Map.ofEntries(
                Map.entry("一", 1), Map.entry("二", 2), Map.entry("两", 2), Map.entry("三", 3),
                Map.entry("四", 4), Map.entry("五", 5), Map.entry("六", 6), Map.entry("七", 7),
                Map.entry("八", 8), Map.entry("九", 9), Map.entry("十", 10));
    }

    private IntentNormalizer() {
    }

    public static Intent normalize(Map<String, Object> raw, int clarifyCount) {
        String category = asText(raw.get("category"), "phone").toLowerCase();
        if (!Intents.CATEGORY_LABELS.containsKey(category)) {
            category = "phone";
        }

        Integer low = asInt(raw.get("budget_min"));
        Integer high = asInt(raw.get("budget_max"));
        if (low != null && high != null && low > high) {
            Integer swap = low;
            low = high;
            high = swap;
        }
        if (low != null && (low < MIN_SANE_PRICE || low > MAX_SANE_PRICE)) {
            low = null;
        }
        if (high != null && (high < MIN_SANE_PRICE || high > MAX_SANE_PRICE)) {
            high = null;
        }

        List<String> must = whitelist(raw.get("must_have"));
        List<String> nice = whitelist(raw.get("nice_to_have")).stream()
                .filter(key -> !must.contains(key))
                .toList();
        List<String> brands = whitelistBrands(raw.get("brands"));

        boolean budgetKnown = asBool(raw.get("budget_known")) || low != null || high != null;
        boolean hasPref = !must.isEmpty() || !nice.isEmpty();

        // 只有"预算没表态 + 没有任何偏好 + 没提品牌"才值得追问
        boolean needClarify = !budgetKnown && !hasPref && brands.isEmpty();
        // 已经追问过一次就直接给结果，不许来回问同一个问题
        if (clarifyCount >= 1) {
            needClarify = false;
        }
        // 用户已经点明别的品类时先去库里查，缺数据由 retrieve 如实报告，
        // 别用"预算多少"把话题岔开
        if (!"phone".equals(category)) {
            needClarify = false;
        }

        return new Intent(
                category,
                Intents.CATEGORY_LABELS.get(category),
                budgetKnown,
                low,
                high,
                must,
                nice,
                brands,
                asText(raw.get("usage"), "").trim(),
                needClarify,
                asText(raw.get("clarify_question"), "").trim());
    }

    /**
     * "X 以上 / 超过 X / 不低于 X" 的下界。
     * 匹配不到返回 null，调用方据此决定要不要覆盖模型给的区间。
     */
    public static Integer lowerBoundOf(String message) {
        if (message == null || message.isBlank()) {
            return null;
        }
        Matcher decimalWan = WAN_DECIMAL_LOWER_BOUND.matcher(message);
        if (decimalWan.find()) {
            return (int) Math.round(Double.parseDouble(decimalWan.group(1)) * 10_000);
        }
        Matcher digit = DIGIT_LOWER_BOUND.matcher(message);
        if (digit.find()) {
            int value = Integer.parseInt(digit.group(1));
            return value >= MIN_SANE_PRICE ? value : null;
        }
        Matcher wan = WAN_LOWER_BOUND.matcher(message);
        if (wan.find()) {
            Integer unit = CHINESE_DIGITS.get(wan.group(1).substring(0, 1));
            if (unit != null) {
                // "二十万" 这类两位数字只认首位，够用且不会误判成 2 万
                int multiplier = wan.group(1).length() > 1 && "十".equals(wan.group(1).substring(1, 2))
                        ? 10
                        : 1;
                return unit * multiplier * 10_000;
            }
        }
        return null;
    }

    /**
     * 用正则把"X 以上"钉成 min=X、max=null。
     * 只在正则命中且模型给的区间与下界矛盾时才覆盖，避免误伤正常区间。
     */
    public static Intent applyLowerBoundGuard(Intent intent, String message) {
        Integer lower = lowerBoundOf(message);
        if (lower == null) {
            return intent;
        }
        boolean contradict = intent.budgetMax() != null
                || intent.budgetMin() == null
                || intent.budgetMin() < lower;
        if (!contradict) {
            return intent;
        }
        return new Intent(
                intent.category(),
                intent.categoryLabel(),
                true,
                lower,
                null,
                intent.mustHave(),
                intent.niceToHave(),
                intent.brands(),
                intent.usage(),
                false,
                "");
    }

    // ------------------------------------------------------------------ 小工具

    private static List<String> whitelist(Object raw) {
        Set<String> result = new LinkedHashSet<>();
        if (raw instanceof List<?> list) {
            for (Object item : list) {
                String key = String.valueOf(item);
                if (Intents.DIMENSION_KEYS.contains(key)) {
                    result.add(key);
                }
            }
        }
        return new ArrayList<>(result);
    }

    private static List<String> whitelistBrands(Object raw) {
        Set<String> result = new LinkedHashSet<>();
        if (raw instanceof List<?> list) {
            for (Object item : list) {
                String brand = String.valueOf(item);
                if (Intents.BRANDS.contains(brand)) {
                    result.add(brand);
                }
            }
        }
        return new ArrayList<>(result);
    }

    static Integer asInt(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return (int) Math.round(number.doubleValue());
        }
        String text = String.valueOf(value).trim();
        if (text.isEmpty()) {
            return null;
        }
        try {
            return (int) Math.round(Double.parseDouble(text));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static boolean asBool(Object value) {
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value != null && Boolean.parseBoolean(String.valueOf(value).trim());
    }

    private static String asText(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String text = String.valueOf(value);
        return text.isBlank() ? fallback : text;
    }
}
