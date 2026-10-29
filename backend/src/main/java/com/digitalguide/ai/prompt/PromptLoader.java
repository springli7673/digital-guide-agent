package com.digitalguide.ai.prompt;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 提示词读取：classpath:prompts/*.txt，读一次缓存住。
 *
 * <p>放资源文件而不是 Java 字符串常量，是为了让 prompt 能独立迭代——
 * 调 prompt 不该触发重新编译，也不该在 diff 里跟代码混在一起。
 */
@Slf4j
@Component
public class PromptLoader {

    private final Map<String, String> cache = new ConcurrentHashMap<>();

    public String load(String name) {
        return cache.computeIfAbsent(name, key -> {
            ClassPathResource resource = new ClassPathResource("prompts/" + key + ".txt");
            try (InputStream in = resource.getInputStream()) {
                return new String(in.readAllBytes(), StandardCharsets.UTF_8);
            } catch (IOException e) {
                log.error("提示词加载失败：prompts/{}.txt", key, e);
                return "";
            }
        });
    }
}
