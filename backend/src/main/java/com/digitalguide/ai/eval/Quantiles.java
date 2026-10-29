package com.digitalguide.ai.eval;

import java.util.List;

/**
 * 分位数，口径对齐 Python 的 {@code statistics.quantiles(sorted, n=4)}（exclusive 法）：
 * 第 p 分位的 1-based 下标是 {@code (N+1) * p}，落在两个样本之间就线性插值，越界则夹到端点。
 *
 * <p>为什么不用"取第 N*0.75 个"这种近似：评测的判定线差一点点就会让结论翻转，
 * 而 P75 又是 prefer 类唯一的判定依据，口径必须和旧版一致，否则迁移前后的数字不可比。
 */
public final class Quantiles {

    private Quantiles() {
    }

    public static double at(List<Double> sortedAsc, double p) {
        int n = sortedAsc.size();
        if (n == 0) {
            throw new IllegalArgumentException("空样本没有分位数");
        }
        if (n == 1) {
            return sortedAsc.get(0);
        }
        double index = (n + 1) * p;
        if (index <= 1) {
            return sortedAsc.get(0);
        }
        if (index >= n) {
            return sortedAsc.get(n - 1);
        }
        int lower = (int) Math.floor(index);
        double fraction = index - lower;
        double a = sortedAsc.get(lower - 1);
        double b = sortedAsc.get(lower);
        return a + fraction * (b - a);
    }
}
