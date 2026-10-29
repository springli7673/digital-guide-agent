package com.digitalguide.ai.guard;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 幻觉护栏：程序校验回答里的型号和价格是不是都来自候选集。
 *
 * <p>为什么需要有这一层：prompt 里写了"只能用候选里的型号和价格"，但那是**请求**，不是**保证**。
 * 模型完全可能把 2199 写成 2199 元起、把 Redmi K80 写成 K80 Pro。这类错误人眼很难一眼发现，
 * 但程序一个正则就能抓。
 *
 * <p>这个类同时被两处使用：
 * <ul>
 *   <li>{@code AnswerNode}：生成后即时校验，发现违例就补一句更正；</li>
 *   <li>{@code EvalJudge}：评测里的 fabricate 判定。</li>
 * </ul>
 * 共用一个实现是刻意的——**评测的口径就是线上的口径**，否则"评测 10/10 通过"和"线上会胡说"
 * 可以同时成立，评测就失去意义了。
 */
public final class AnswerGuard {

    /** 回答里这些不像型号，别误判成编造 */
    private static final Set<String> IGNORE_TOKENS = Set.of(
            "5g", "4g", "wifi", "nfc", "ip68", "ip69", "ip67", "120hz", "165hz", "144hz",
            "90hz", "mah", "gb", "tb", "w", "wifi6", "wifi7", "type-c", "usb", "pd", "qc", "ufs",
            "lpddr", "ois", "dc", "pwm", "cpt", "ltpo", "amoled", "oled", "lcd");

    /**
     * 技术名词前缀：LPDDR5X、UFS4.0、WiFi7、USB3.2 这类 token 会被型号正则扫到，
     * 但它们不是机型。按前缀放行比逐个枚举版本号靠谱（版本号会一直变）。
     */
    private static final List<String> IGNORE_PREFIXES = List.of(
            "lpddr", "ufs", "wifi", "usb", "type", "pd", "qc", "ip6", "ip5",
            "amoled", "ltpo", "oled", "hdr", "nfc", "hifi", "dac", "usf",
            "android", "ios", "harmony", "coloros", "originos", "hyperos", "magicos");

    private static final Pattern PRICE = Pattern.compile("[¥￥]\\s?([\\d,]+)");
    /**
     * 像型号的 token：两个以上字母紧跟数字。
     * <p>已知盲区：S99、K90 这种「单字母+数字」抓不到。这条正则和旧版评测脚本一致，
     * 保持口径可比；要补强就两边一起改。
     */
    private static final Pattern MODEL = Pattern.compile("[A-Za-z]{2,}[0-9][A-Za-z0-9]*");

    /**
     * @param models 回答里出现、但候选里没有的型号
     * @param prices 回答里出现、但候选里没有的价格
     */
    public record Violation(List<String> models, List<Double> prices) {

        public boolean isEmpty() {
            return models.isEmpty() && prices.isEmpty();
        }

        /** 给用户看的一句更正 */
        public String describe() {
            StringBuilder builder = new StringBuilder();
            if (!prices.isEmpty()) {
                builder.append("价格 ").append(prices.subList(0, Math.min(2, prices.size())));
            }
            if (!models.isEmpty()) {
                if (builder.length() > 0) {
                    builder.append('、');
                }
                builder.append("型号 ").append(models.subList(0, Math.min(2, models.size())));
            }
            return builder.toString();
        }
    }

    private AnswerGuard() {
    }

    /**
     * @param answer     模型生成的话术
     * @param candidates 本轮候选（含 brand / model / priceRef）
     */
    public static Violation check(String answer, List<Map<String, Object>> candidates) {
        if (answer == null || answer.isBlank() || candidates == null || candidates.isEmpty()) {
            return new Violation(List.of(), List.of());
        }

        Set<Long> allowedPrices = new LinkedHashSet<>();
        StringBuilder haystack = new StringBuilder();
        for (Map<String, Object> candidate : candidates) {
            Object price = candidate.get("priceRef");
            if (price instanceof Number number) {
                long rounded = Math.round(number.doubleValue());
                allowedPrices.add(rounded);
                // 允许整百的取整说法（2199 → 2200）
                allowedPrices.add(Math.round(number.doubleValue() / 100) * 100);
            }
            haystack.append(String.valueOf(candidate.getOrDefault("brand", "")))
                    .append(String.valueOf(candidate.getOrDefault("model", "")))
                    .append(' ');
        }
        String normalizedHaystack = haystack.toString().toLowerCase().replace(" ", "");

        List<Double> badPrices = new ArrayList<>();
        Matcher priceMatcher = PRICE.matcher(answer);
        while (priceMatcher.find()) {
            long value;
            try {
                value = Long.parseLong(priceMatcher.group(1).replace(",", ""));
            } catch (NumberFormatException e) {
                continue;
            }
            long target = value;
            boolean matched = allowedPrices.stream().anyMatch(p -> Math.abs(target - p) <= 1);
            if (!matched) {
                badPrices.add((double) value);
            }
        }

        List<String> badModels = new ArrayList<>();
        Matcher modelMatcher = MODEL.matcher(answer);
        while (modelMatcher.find()) {
            String token = modelMatcher.group();
            String lower = token.toLowerCase();
            if (lower.length() < 4 || IGNORE_TOKENS.contains(lower) || isTechTerm(lower)) {
                continue;
            }
            if (!normalizedHaystack.contains(lower)) {
                badModels.add(token);
            }
        }

        return new Violation(badModels, badPrices);
    }

    private static boolean isTechTerm(String lowerToken) {
        return IGNORE_PREFIXES.stream().anyMatch(lowerToken::startsWith);
    }
}
