package com.digitalguide.ai.rag;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * 向量化：bge-m3（1024 维）走 Ollama 的 OpenAI 兼容端点。
 *
 * <p>pgvector 的参数接受 {@code '[0.1,0.2,...]'} 这种字面量，所以这里顺手负责
 * 把 float[] 转成字面量——用 JDBC 拼字符串而不是引入额外的向量库客户端，
 * 少一个依赖，SQL 也看得见。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KbEmbeddingService {

    private final EmbeddingModel embeddingModel;

    public float[] embed(String text) {
        return embeddingModel.embed(text);
    }

    public List<float[]> embedAll(List<String> texts) {
        List<float[]> vectors = new ArrayList<>(texts.size());
        for (String text : texts) {
            vectors.add(embed(text));
        }
        return vectors;
    }

    /** pgvector 的文本表示：'[0.1,0.2,0.3]' */
    public static String toVectorLiteral(float[] vector) {
        StringBuilder builder = new StringBuilder(vector.length * 8).append('[');
        for (int i = 0; i < vector.length; i++) {
            if (i > 0) {
                builder.append(',');
            }
            builder.append(vector[i]);
        }
        return builder.append(']').toString();
    }
}
