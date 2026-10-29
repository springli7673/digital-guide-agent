package com.digitalguide.ai.eval;

import com.digitalguide.DigitalGuideApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;

import java.nio.file.Files;
import java.nio.file.Path;

/**
 * 评测入口（独立 main，不是 Web 请求）。
 *
 * <p>用法：
 * <pre>
 *   java -cp ... com.digitalguide.ai.eval.EvalMain --only prefer --limit 3
 *   java -cp ... com.digitalguide.ai.eval.EvalMain --repeat 3 --limit 10
 * </pre>
 * IDEA 里直接右键运行 {@code EvalMain}，Program arguments 填 {@code --only prefer}。
 *
 * <p>刻意用 {@code WebApplicationType.NONE} 启动：跑评测不该占用 8080，
 * 也不该因为端口被占而失败。数据库和模型照常装配，因为图真的要用它们。
 */
public final class EvalMain {

    private EvalMain() {
    }

    public static void main(String[] args) throws Exception {
        Path projectRoot = locateProjectRoot(args);

        // 不把 CLI 参数交给 Spring：--only / --repeat 不是 Spring 的属性
        ConfigurableApplicationContext context = new SpringApplicationBuilder(DigitalGuideApplication.class)
                .web(WebApplicationType.NONE)
                .run();

        int exitCode;
        try {
            EvalOptions options = EvalOptions.parse(args, projectRoot);
            exitCode = context.getBean(EvalRunner.class).run(options);
        } finally {
            org.springframework.boot.SpringApplication.exit(context, () -> 0);
        }
        System.exit(exitCode);
    }

    /** 从当前目录往上找"包含 eval/cases.json 的目录"当作项目根 */
    private static Path locateProjectRoot(String[] args) {
        for (int i = 0; i < args.length; i++) {
            if (args[i].startsWith("--root")) {
                String value = args[i].contains("=")
                        ? args[i].substring(args[i].indexOf('=') + 1)
                        : (i + 1 < args.length ? args[i + 1] : null);
                if (value != null) {
                    return Path.of(value).toAbsolutePath().normalize();
                }
            }
        }
        Path current = Path.of("").toAbsolutePath();
        for (Path path = current; path != null; path = path.getParent()) {
            if (Files.exists(path.resolve("eval").resolve("cases.json"))) {
                return path;
            }
        }
        return current;
    }
}
