package com.digitalguide.ai.eval;

/**
 * 一条评测 case。不同类别用的字段不同：
 *
 * <ul>
 *   <li>budget：low / high —— 候选价格必须全部落在这个区间</li>
 *   <li>prefer：dim + direction + (low/high) —— 点名维度上 top3 至少 2 个达到分位线</li>
 *   <li>refuse：无额外字段 —— 必须报错或追问，且不能给候选</li>
 *   <li>fabricate：无额外字段 —— 回答里的型号与价格必须来自候选</li>
 * </ul>
 */
public record EvalCase(
        String id,
        String cat,
        String query,
        Integer low,
        Integer high,
        String dim,
        String direction,
        /** 知识型 case 期望命中的文档标题（子串匹配），其他类型为 null */
        String expect
) {
}
