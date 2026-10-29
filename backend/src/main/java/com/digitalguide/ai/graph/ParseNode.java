package com.digitalguide.ai.graph;

import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.intent.IntentNormalizer;
import com.digitalguide.ai.intent.Intents;
import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.ai.prompt.PromptLoader;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * parse：自然语言 → 结构化需求。
 *
 * <p>模型只负责"理解"，不负责"决定"：它给出的维度键、品牌、预算区间全部要过
 * {@link IntentNormalizer} 的白名单和边界校验，否则模型编一个不存在的维度名
 * 就能把打分带偏。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ParseNode {

    /** 模型偶尔会带 ```json 包裹或前后废话，这里做一次兜底 */
    private static final Pattern JSON_OBJECT = Pattern.compile("\\{.*}", Pattern.DOTALL);
    private static final Pattern FENCE_START = Pattern.compile("^```[a-zA-Z]*\\n?");
    private static final Pattern FENCE_END = Pattern.compile("\\n?```$");

    private static final int HISTORY_LIMIT = 6;
    private static final int HISTORY_CONTENT_LIMIT = 160;

    private final LlmClient llm;
    private final LlmProperties llmProperties;
    private final PromptLoader prompts;
    private final ObjectMapper objectMapper;

    public void run(ChatState state, EventSink sink) {
        sink.emit("status", Map.of("stage", "parsing", "text", "正在理解你的需求…"));

        Map<String, Object> raw = Map.of();
        try {
            String output = llm.complete(llmProperties.routerRequest(
                    prompts.load("parse"), buildParseInput(state)));
            raw = extractJson(output);
        } catch (Exception e) {
            // 模型挂了也要能往下走：退化成"什么都不限定"，由 retrieve 兜住
            log.warn("解析节点调用模型失败，按空需求继续：{}", e.getMessage());
        }

        Intent intent = IntentNormalizer.normalize(raw, state.getClarifyCount());
        intent = IntentNormalizer.applyLowerBoundGuard(intent, state.getMessage());
        state.setIntent(intent);

        sink.emit("intent", Intents.wire(intent));

        if (intent.needClarify()) {
            Map<String, Object> payload = Intents.clarify(intent);
            sink.emit("clarify", payload);
            state.setClarify(payload);
        }
    }

    /**
     * 把"摘要 + 槽位锚点 + 最近几轮对话"拼进解析输入。
     *
     * <p>三层都要给，缺一层就会出对应的问题：
     * <ul>
     *   <li>不给历史 → "不限预算，只看参数"这种补充回答被当成新问题，同一个追问反复出现；</li>
     *   <li>不给摘要 → 第 10 轮时早先的约束已经滚出窗口，模型不知道用户早就说过不要华为；</li>
     *   <li>不给槽位锚点 → 摘要只记得"大概三千"，精确的 1800~3450 丢了，解析结果会漂。</li>
     * </ul>
     */
    static String buildParseInput(ChatState state) {
        String message = state.getMessage();
        List<ChatMessage> history = state.getHistory();
        boolean hasSummary = state.getSummary() != null && !state.getSummary().isBlank();
        String anchorText = anchorText(state.getAnchor());

        if ((history == null || history.isEmpty()) && !hasSummary && anchorText.isEmpty()) {
            return message;
        }

        StringBuilder builder = new StringBuilder();
        if (hasSummary) {
            builder.append("【早前对话摘要】\n").append(state.getSummary()).append("\n\n");
        }
        if (!anchorText.isEmpty()) {
            builder.append("【已确认的槽位】\n").append(anchorText)
                    .append("\n（用户本轮没说到的槽位，默认沿用这些值）\n\n");
        }
        if (history != null && !history.isEmpty()) {
            builder.append("【最近对话】\n");
            List<ChatMessage> recent = history.size() > HISTORY_LIMIT
                    ? history.subList(history.size() - HISTORY_LIMIT, history.size())
                    : history;
            for (ChatMessage item : recent) {
                String content = item.content() == null ? "" : item.content().trim().replace("\n", " ");
                if (content.isEmpty()) {
                    continue;
                }
                if (content.length() > HISTORY_CONTENT_LIMIT) {
                    content = content.substring(0, HISTORY_CONTENT_LIMIT);
                }
                builder.append(item.roleLabel()).append("：").append(content).append('\n');
            }
        }
        builder.append("\n【用户本轮】\n").append(message);
        return builder.toString();
    }

    /** 槽位锚点渲染成人能读的一行；空锚点返回空串 */
    static String anchorText(java.util.Map<String, Object> anchor) {
        if (anchor == null || anchor.isEmpty()) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        Object min = anchor.get("budgetMin");
        Object max = anchor.get("budgetMax");
        if (min != null || max != null) {
            builder.append("预算 ").append(min == null ? "不限" : min)
                    .append("–").append(max == null ? "不限" : max).append('；');
        }
        List<String> must = asTextList(anchor.get("mustHave"));
        if (!must.isEmpty()) {
            builder.append("重点 ").append(String.join("、", must)).append('；');
        }
        List<String> nice = asTextList(anchor.get("niceToHave"));
        if (!nice.isEmpty()) {
            builder.append("次要 ").append(String.join("、", nice)).append('；');
        }
        List<String> brands = asTextList(anchor.get("brands"));
        if (!brands.isEmpty()) {
            builder.append("品牌 ").append(String.join("、", brands)).append('；');
        }
        return builder.toString();
    }

    private static List<String> asTextList(Object raw) {
        if (!(raw instanceof List<?> list)) {
            return List.of();
        }
        return list.stream().map(String::valueOf).filter(s -> !s.isBlank()).toList();
    }

    @SuppressWarnings("unchecked")
    Map<String, Object> extractJson(String raw) {
        if (raw == null || raw.isBlank()) {
            return Map.of();
        }
        String text = raw.trim();
        if (text.startsWith("```")) {
            text = FENCE_START.matcher(text).replaceFirst("");
            text = FENCE_END.matcher(text).replaceFirst("");
        }
        Map<String, Object> parsed = tryParse(text);
        if (parsed != null) {
            return parsed;
        }
        Matcher matcher = JSON_OBJECT.matcher(text);
        if (matcher.find()) {
            parsed = tryParse(matcher.group());
            if (parsed != null) {
                return parsed;
            }
        }
        log.warn("模型输出不是合法 JSON，按空需求处理：{}", text.length() > 200 ? text.substring(0, 200) : text);
        return Map.of();
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> tryParse(String text) {
        try {
            Object value = objectMapper.readValue(text, Object.class);
            if (value instanceof Map<?, ?> map) {
                return new LinkedHashMap<>((Map<String, Object>) map);
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }
}
