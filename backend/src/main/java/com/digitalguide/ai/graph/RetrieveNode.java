package com.digitalguide.ai.graph;

import com.digitalguide.ai.cache.CacheKeys;
import com.digitalguide.ai.cache.CandidateCache;
import com.digitalguide.ai.intent.Intent;
import com.digitalguide.ai.intent.Intents;
import com.digitalguide.service.ProductService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * retrieve：硬条件过滤，走 SQL，绝不让模型参与。
 *
 * <p>和 Python 版最大的差别：<b>不再有跨进程的 limit 上限</b>。
 * 以前 Python 只能通过内部接口拿货且上限 50，只好按 4 个价位段分别查再合并，
 * 才能让旗舰机进候选（否则"拍照最好的手机"永远只拿到最便宜的 50 款）。
 * 现在直接调 Service，一次查询就能覆盖全库，那套绕行逻辑可以删掉。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RetrieveNode {

    /** 单次检索的候选上限。147 款全库都能装下；涨到 500 款也够。 */
    private static final int CANDIDATE_LIMIT = 500;

    private final ProductService productService;
    private final CandidateCache candidateCache;

    public void run(ChatState state, EventSink sink) {
        Intent intent = state.getIntent();
        String cacheKey = CacheKeys.candidates(intent.category(),
                money(intent.budgetMin()), money(intent.budgetMax()), intent.brands());

        // 先看缓存：同品类同预算同品牌的过滤结果在 10 分钟内是稳定的
        List<Map<String, Object>> candidates = candidateCache.get(cacheKey);
        boolean cached = candidates != null;

        sink.emit("status", Map.of("stage", "searching",
                "text", "在商品库中按「" + intent.categoryLabel() + " · "
                        + Intents.priceRangeText(intent) + "」做硬过滤…"
                        + (cached ? "（命中缓存）" : "")));

        if (!cached) {
            try {
                candidates = search(intent);
            } catch (Exception e) {
                String msg = "商品服务暂时不可用，稍后再试（" + e.getMessage() + "）";
                log.error("候选检索失败", e);
                sink.emit("error", Map.of("msg", msg));
                state.setError(msg);
                return;
            }
            candidateCache.put(cacheKey, candidates);
        }

        if (candidates.isEmpty()) {
            // 区分"这个品类没数据"和"这个价位没数据"，别让用户瞎猜
            String msg = explainEmpty(intent);
            sink.emit("error", Map.of("msg", msg));
            state.setError(msg);
            return;
        }

        state.setCandidates(candidates);
        log.info("检索完成：品类={} 预算={} 品牌={} 命中={} 来源={}", intent.category(),
                Intents.priceRangeText(intent), intent.brands(), candidates.size(),
                cached ? "cache" : "db");
    }

    private List<Map<String, Object>> search(Intent intent) {
        return productService.searchForAgent(intent.category(),
                money(intent.budgetMin()), money(intent.budgetMax()),
                intent.brands().isEmpty() ? null : intent.brands(), CANDIDATE_LIMIT);
    }

    private static BigDecimal money(Integer value) {
        return value == null ? null : BigDecimal.valueOf(value);
    }

    /** 库里空了的时候，先探一下这个品类到底有没有货，再决定说什么 */
    private String explainEmpty(Intent intent) {
        boolean categoryMissing = false;
        if (!"phone".equals(intent.category()) || !intent.brands().isEmpty()) {
            try {
                categoryMissing = productService
                        .searchForAgent(intent.category(), null, null, null, 1).isEmpty();
            } catch (Exception e) {
                log.warn("探空查询失败：{}", e.getMessage());
            }
        }
        if (categoryMissing) {
            return "库里目前还没有" + intent.categoryLabel() + "的数据（现在只有手机）。"
                    + "抓取脚本已经预留了入口，但我不想编一个不存在的型号给你。";
        }
        return Intents.priceRangeText(intent) + " 这个区间没有在售的" + intent.categoryLabel()
                + "，预算放宽一点再试试？";
    }

    /** 给日志/调试用的候选摘要 */
    static List<Map<String, Object>> summarize(List<Map<String, Object>> candidates) {
        List<Map<String, Object>> rows = new ArrayList<>();
        for (Map<String, Object> item : candidates) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", item.get("id"));
            row.put("brand", item.get("brand"));
            row.put("model", item.get("model"));
            row.put("priceRef", item.get("priceRef"));
            rows.add(row);
        }
        return rows;
    }
}
