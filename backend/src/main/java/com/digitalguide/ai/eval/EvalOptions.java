package com.digitalguide.ai.eval;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/** 评测参数。命令行只认这几个开关，够用且好记。 */
public record EvalOptions(
        String only,
        int limit,
        int repeat,
        Path casesPath,
        Path productsPath,
        Path outDir
) {

    public static EvalOptions parse(String[] args, Path projectRoot) {
        String only = "";
        int limit = 0;
        int repeat = 1;
        String cases = null;
        String products = null;
        String out = null;

        for (int i = 0; i < args.length; i++) {
            String arg = args[i];
            String value = valueOf(args, i);
            switch (arg.split("=")[0]) {
                case "--only" -> {
                    only = value == null ? "" : value;
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                case "--limit" -> {
                    limit = value == null ? 0 : Integer.parseInt(value);
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                case "--repeat" -> {
                    repeat = value == null ? 1 : Math.max(1, Integer.parseInt(value));
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                case "--cases" -> {
                    cases = value;
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                case "--products" -> {
                    products = value;
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                case "--out" -> {
                    out = value;
                    if (arg.indexOf('=') < 0) {
                        i++;
                    }
                }
                default -> {
                    // 忽略：Spring Boot 自己的参数也在同一个数组里
                }
            }
        }

        return new EvalOptions(
                only,
                Math.max(limit, 0),
                repeat,
                locate(cases, projectRoot, "eval/cases.json"),
                locate(products, projectRoot, "data/normalized/products.json"),
                out != null ? Path.of(out) : locate(null, projectRoot, "eval"));
    }

    /** 兼容 `--x value` 和 `--x=value` 两种写法 */
    private static String valueOf(String[] args, int index) {
        String arg = args[index];
        int eq = arg.indexOf('=');
        if (eq >= 0) {
            return arg.substring(eq + 1);
        }
        if (index + 1 < args.length && !args[index + 1].startsWith("--")) {
            return args[index + 1];
        }
        return null;
    }

    /**
     * 同时兼容"从 backend/ 跑"和"从项目根跑"。
     * IDEA 里直接运行 EvalMain 时工作目录是 backend/，所以要往上找两级。
     */
    private static Path locate(String explicit, Path projectRoot, String relative) {
        if (explicit != null && !explicit.isBlank()) {
            return Path.of(explicit);
        }
        List<Path> candidates = new ArrayList<>();
        if (projectRoot != null) {
            candidates.add(projectRoot.resolve(relative));
        }
        candidates.add(Path.of(relative));
        candidates.add(Path.of("..").resolve(relative));
        candidates.add(Path.of("../..").resolve(relative));
        for (Path candidate : candidates) {
            if (Files.exists(candidate)) {
                return candidate.normalize();
            }
        }
        return candidates.get(0);
    }
}
