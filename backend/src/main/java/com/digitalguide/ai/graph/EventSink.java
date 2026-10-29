package com.digitalguide.ai.graph;

/**
 * 节点向外推事件的口子。
 *
 * <p>Python 版是 LangGraph 的 {@code get_stream_writer()}；Java 版没有图运行时，
 * 就把它收敛成一个函数式接口——节点只负责"说什么"，"怎么送到浏览器"交给上层。
 * 这样节点依然可以脱开 SSE 单测（传一个收集用的 sink 即可）。
 */
@FunctionalInterface
public interface EventSink {

    /**
     * @param event status / intent / candidates / clarify / token / done / error
     * @param data  会被序列化成 JSON 的事件体
     */
    void emit(String event, Object data);

    /** 吞掉事件的 sink，给单测和"不关心流"的调用方用 */
    EventSink DISCARD = (event, data) -> {
    };
}
