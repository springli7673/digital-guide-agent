package com.digitalguide.ai.eval;

import com.digitalguide.ai.graph.ChatGraph;
import com.digitalguide.ai.graph.ChatState;
import com.digitalguide.ai.graph.EventSink;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * 评测 runner：**进程内**直接调 {@link ChatGraph}，不走 HTTP、不解析 SSE。
 *
 * <p>这是从 Python 版迁过来最大的收益：旧版每条 case 要发一次 SSE、逐行解析、
 * 再拼回事件；现在就是一次方法调用，事件用记录型 sink 收进列表。
 * 少一层网络和一层协议，跑批更快，失败栈也更直接。
 *
 * <p>产出 {@code eval/report.json}（完整轨迹）+ {@code eval/report.md}（人看的）。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EvalRunner {

    private final ChatGraph chatGraph;
    private final ObjectMapper objectMapper;

    public int run(EvalOptions options) throws IOException {
        List<EvalCase> cases = loadCases(options.casesPath());
        if (options.only() != null && !options.only().isBlank()) {
            cases = cases.stream().filter(c -> options.only().equals(c.cat())).toList();
        }
        if (options.limit() > 0 && cases.size() > options.limit()) {
            cases = cases.subList(0, options.limit());
        }

        EvalThresholds thresholds = EvalThresholds.load(options.productsPath());
        System.out.printf("评测 %d 条 case（repeat=%d，基准 %d 款商品）%n",
                cases.size(), options.repeat(), thresholds.productCount());

        List<EvalResult> results = new ArrayList<>();
        int index = 0;
        for (EvalCase evalCase : cases) {
            index++;
            EvalResult best = null;
            long totalLatency = 0;
            List<String> notes = new ArrayList<>();
            for (int attempt = 1; attempt <= options.repeat(); attempt++) {
                EvalResult single = runOnce(evalCase, thresholds);
                totalLatency += single.latencyMs();
                notes.add(single.passed() ? "PASS" : "FAIL:" + single.note());
                if (single.passed()) {
                    best = single;
                    break;
                }
                if (best == null) {
                    best = single;
                }
            }
            EvalResult merged = best == null
                    ? new EvalResult(evalCase.id(), evalCase.cat(), evalCase.query(), 0,
                    List.of(), List.of(), "", "未执行", false, Map.of(), false, "未执行")
                    : new EvalResult(best.id(), best.cat(), best.query(),
                    Math.round((double) totalLatency / options.repeat()),
                    best.events(), best.candidates(), best.answer(), best.error(),
                    best.clarified(), best.intent(), best.passed(),
                    options.repeat() > 1 ? best.note() + "｜" + String.join(",", notes) : best.note());
            results.add(merged);

            System.out.printf("[%2d/%d] %s  %-4s %-24s %5.1fs  %s%n",
                    index, cases.size(),
                    merged.passed() ? "PASS" : "FAIL",
                    evalCase.id(),
                    shorten(evalCase.query(), 22),
                    merged.latencyMs() / 1000.0,
                    merged.note());
        }

        writeReports(results, options, thresholds);
        int passed = (int) results.stream().filter(EvalResult::passed).count();
        System.out.printf("%n结果：%d/%d 通过（%.1f%%）%n", passed, results.size(),
                results.isEmpty() ? 0 : passed * 100.0 / results.size());
        System.out.println("报告：" + options.outDir().resolve("report.md"));
        return passed == results.size() ? 0 : 1;
    }

    // ------------------------------------------------------------------ 单条

    private EvalResult runOnce(EvalCase evalCase, EvalThresholds thresholds) {
        RecordingSink sink = new RecordingSink();
        long started = System.nanoTime();
        try {
            chatGraph.run(new ChatState(evalCase.query(), "eval", List.of(), 0), sink);
        } catch (RuntimeException e) {
            log.warn("case {} 执行异常：{}", evalCase.id(), e.getMessage());
            sink.error = "运行异常：" + e.getMessage();
        }
        long latencyMs = (System.nanoTime() - started) / 1_000_000;

        EvalResult raw = new EvalResult(
                evalCase.id(), evalCase.cat(), evalCase.query(), latencyMs,
                sink.sortedEvents(), sink.candidates, sink.answer.toString(),
                sink.error, sink.clarified, sink.intent, false, "");
        EvalJudge.Verdict verdict = EvalJudge.judge(evalCase, raw, thresholds);
        return raw.withVerdict(verdict.passed(), verdict.note());
    }

    // ------------------------------------------------------------------ 报告

    private void writeReports(List<EvalResult> results, EvalOptions options,
                              EvalThresholds thresholds) throws IOException {
        int total = results.size();
        int passed = (int) results.stream().filter(EvalResult::passed).count();
        List<Long> latencies = results.stream().map(EvalResult::latencyMs).sorted().toList();
        long p50 = latencies.isEmpty() ? 0 : latencies.get(latencies.size() / 2);

        Map<String, int[]> byCat = new TreeMap<>();
        for (EvalResult result : results) {
            int[] stat = byCat.computeIfAbsent(result.cat(), k -> new int[2]);
            stat[0]++;
            if (result.passed()) {
                stat[1]++;
            }
        }
        Map<String, Object> byCatPayload = new LinkedHashMap<>();
        byCat.forEach((cat, stat) -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("total", stat[0]);
            item.put("pass", stat[1]);
            byCatPayload.put(cat, item);
        });

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("total", total);
        summary.put("passed", passed);
        summary.put("pass_rate", total == 0 ? 0 : Math.round(passed * 1000.0 / total) / 10.0);
        summary.put("p50_latency_ms", p50);
        summary.put("repeat", options.repeat());
        summary.put("by_cat", byCatPayload);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("generated_at", LocalDateTime.now()
                .format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")));
        payload.put("engine", "in-process ChatGraph");
        payload.put("benchmark_products", thresholds.productCount());
        payload.put("summary", summary);
        payload.put("results", results);

        Path jsonOut = options.outDir().resolve("report.json");
        Files.createDirectories(options.outDir());
        Files.writeString(jsonOut, objectMapper.writerWithDefaultPrettyPrinter()
                .writeValueAsString(payload), StandardCharsets.UTF_8);

        StringBuilder md = new StringBuilder();
        md.append("# 评测报告\n\n");
        md.append("- 生成时间：").append(payload.get("generated_at")).append('\n');
        md.append("- 执行方式：进程内调用 `ChatGraph`（不走 HTTP）\n");
        md.append("- 判定基准：`data/normalized/products.json` ")
                .append(thresholds.productCount()).append(" 款\n");
        md.append("- 总览：**").append(passed).append('/').append(total).append("** 通过（")
                .append(summary.get("pass_rate")).append("%），P50 延迟 ")
                .append(String.format("%.1f", p50 / 1000.0)).append("s\n");
        if (options.repeat() > 1) {
            md.append("- 重复次数：").append(options.repeat()).append("（pass@").append(options.repeat()).append("）\n");
        }
        md.append("\n| 类别 | 通过 / 总数 | 通过率 |\n|---|---|---|\n");
        byCat.forEach((cat, stat) -> md.append("| ").append(cat).append(" | ")
                .append(stat[1]).append(" / ").append(stat[0]).append(" | ")
                .append(stat[0] == 0 ? 0 : Math.round(stat[1] * 100.0 / stat[0])).append("% |\n"));

        List<EvalResult> failed = results.stream().filter(r -> !r.passed()).toList();
        md.append("\n## 失败 case（").append(failed.size()).append(" 条）\n\n");
        if (failed.isEmpty()) {
            md.append("无。\n");
        } else {
            md.append("| id | 提问 | 原因 |\n|---|---|---|\n");
            for (EvalResult result : failed) {
                md.append("| ").append(result.id()).append(" | ")
                        .append(result.query()).append(" | ")
                        .append(result.note().replace("|", "\\|")).append(" |\n");
            }
        }
        Files.writeString(options.outDir().resolve("report.md"), md.toString(), StandardCharsets.UTF_8);
    }

    private List<EvalCase> loadCases(Path path) throws IOException {
        String json = Files.readString(path, StandardCharsets.UTF_8);
        return objectMapper.readValue(json, objectMapper.getTypeFactory()
                .constructCollectionType(List.class, EvalCase.class));
    }

    private static String shorten(String text, int max) {
        if (text == null) {
            return "";
        }
        return text.length() <= max ? text : text.substring(0, max);
    }

    // ------------------------------------------------------------------ sink

    /** 把图推出的事件收进字段，供判定用 */
    @SuppressWarnings("unchecked")
    private static final class RecordingSink implements EventSink {

        private final List<String> events = new ArrayList<>();
        private List<Map<String, Object>> candidates = List.of();
        private final StringBuilder answer = new StringBuilder();
        private String error;
        private Map<String, Object> intent = Map.of();
        private boolean clarified;

        @Override
        public void emit(String event, Object data) {
            events.add(event);
            if (!(data instanceof Map<?, ?> map)) {
                return;
            }
            switch (event) {
                case "token" -> {
                    Object text = map.get("text");
                    if (text != null) {
                        answer.append(text);
                    }
                }
                case "candidates" -> {
                    Object items = map.get("items");
                    if (items instanceof List<?> list) {
                        candidates = (List<Map<String, Object>>) list;
                    }
                }
                case "error" -> error = String.valueOf(map.get("msg"));
                case "clarify" -> clarified = true;
                case "intent" -> intent = (Map<String, Object>) map;
                default -> {
                    // status / done 之类不需要留存
                }
            }
        }

        private List<String> sortedEvents() {
            return events.stream().distinct().sorted().toList();
        }
    }
}
