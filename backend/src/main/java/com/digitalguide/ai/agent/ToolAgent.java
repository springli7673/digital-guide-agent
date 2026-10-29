package com.digitalguide.ai.agent;

import com.digitalguide.ai.graph.ChatState;
import com.digitalguide.ai.graph.EventSink;
import com.digitalguide.ai.prompt.PromptLoader;
import com.digitalguide.ai.tool.ProductTools;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * 工具模式：把 {@link ProductTools} 交给模型，由它决定调哪个、传什么参数。
 *
 * <p><b>为什么不把所有请求都做成 ReAct</b>：推荐主链路是确定的流水线
 * （parse → 硬过滤 → 打分 → 话术），每一步都可预测、可单测、可回归。
 * 换成"让模型自己决定怎么查"，同样的输入会得到不同路径，评测就失去了意义。
 * 所以这里的分工是：
 *
 * <pre>
 *   买什么        → 确定流水线（快、稳、可评测）
 *   对比/查详情   → 工具模式（多步、需要模型自己组合）
 * </pre>
 *
 * <p>这正是"workflow 还是 agent"那个经典取舍：<b>能用流程解决的别交给模型决策</b>，
 * 只有步骤数不确定的任务才值得上 ReAct。
 *
 * <p>模型侧的调用循环由 Spring AI 的 {@code ToolCallingManager} 负责——
 * 它会自动把工具结果回填给模型并继续，直到模型不再请求工具或达到上限，
 * 所以这里看到的仍然是一条连续的 token 流。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ToolAgent {

    private final ChatClient chatClient;
    private final ProductTools productTools;
    private final PromptLoader prompts;

    public void run(ChatState state, EventSink sink) {
        sink.emit("status", Map.of("stage", "tooling", "text", "正在查库、对比参数…"));

        StringBuilder answer = new StringBuilder();
        try {
            chatClient.prompt()
                    .system(prompts.load("answer_tools"))
                    .user(state.getMessage())
                    .tools(productTools)
                    .stream()
                    .content()
                    .toIterable()
                    .forEach(chunk -> {
                        if (chunk != null && !chunk.isEmpty()) {
                            answer.append(chunk);
                            sink.emit("token", Map.of("text", chunk));
                        }
                    });
        } catch (RuntimeException e) {
            log.warn("工具模式失败，退化为直接检索：{}", e.getMessage());
            String fallback = degrade(state);
            if (answer.length() == 0) {
                answer.append(fallback);
                sink.emit("token", Map.of("text", fallback));
            }
            sink.emit("status", Map.of("stage", "tooling",
                    "text", "工具调用不可用，已改为直接检索"));
        }
        state.setAnswer(answer.toString());
    }

    /**
     * 兜底：工具链挂了也要给用户一点有用的东西。
     * 直接调一次检索，把结果原样列出来——数据本身是可靠的，只是没有话术。
     */
    private String degrade(ChatState state) {
        try {
            String rows = productTools.searchPhones(0, 0, "");
            return "工具调用这会儿不太顺，先把库里的候选直接列给你：\n" + rows;
        } catch (RuntimeException e) {
            log.error("兜底检索也失败", e);
            return "这条问题需要查库，但检索服务暂时不可用，稍后再试一次。";
        }
    }
}
