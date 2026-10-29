package com.digitalguide.ai.intent;

import java.util.List;

/**
 * parse 节点的产物。字段名刻意保持 snake_case 的语义（category_label / must_have…），
 * 因为它就是 Python 版 {@code AgentState["intent"]} 的等价物，两边对得上才好对照。
 */
public record Intent(
        String category,
        String categoryLabel,
        boolean budgetKnown,
        Integer budgetMin,
        Integer budgetMax,
        List<String> mustHave,
        List<String> niceToHave,
        List<String> brands,
        String usage,
        boolean needClarify,
        String clarifyQuestion
) {

    public Intent {
        mustHave = mustHave == null ? List.of() : List.copyOf(mustHave);
        niceToHave = niceToHave == null ? List.of() : List.copyOf(niceToHave);
        brands = brands == null ? List.of() : List.copyOf(brands);
        usage = usage == null ? "" : usage;
        clarifyQuestion = clarifyQuestion == null ? "" : clarifyQuestion;
    }

    /** 有预算上下界之一时才算"有区间" */
    public boolean hasBudget() {
        return budgetMin != null || budgetMax != null;
    }
}
