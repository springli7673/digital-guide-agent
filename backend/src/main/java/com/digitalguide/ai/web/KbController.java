package com.digitalguide.ai.web;

import com.digitalguide.ai.rag.KbIngestor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 知识库入库接口。
 *
 * <p>手动触发而不是启动时自动跑：入库要调 embedding 模型，一篇指南几十个块，
 * 启动时跑会让"服务起来"变慢且依赖 Ollama 在线。改完语料点一下这个接口就行。
 */
@Slf4j
@RestController
@RequiredArgsConstructor
public class KbController {

    private final KbIngestor ingestor;

    @PostMapping("/v1/kb/ingest")
    public Map<String, Object> ingest() throws IOException {
        KbIngestor.IngestResult result = ingestor.ingest();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("ok", true);
        payload.put("docs", result.docs());
        payload.put("chunks", result.chunks());
        payload.put("titles", result.titles());
        return payload;
    }
}
