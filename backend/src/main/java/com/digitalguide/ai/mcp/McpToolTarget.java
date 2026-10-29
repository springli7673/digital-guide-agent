package com.digitalguide.ai.mcp;

/**
 * MCP 工具与业务代码之间的最小契约。
 *
 * <p>存在的唯一目的：让 {@link McpServer} 不依赖 Spring、不依赖数据库，
 * 从而可以在单元测试里塞一个假实现，验证协议报文对不对。
 *
 * <p>{@code com.digitalguide.ai.tool.ProductTools} 直接实现它——
 * 方法签名和参数语义完全一致，不需要任何适配代码。
 */
public interface McpToolTarget {

    String searchPhones(int minPrice, int maxPrice, String brands);

    String phoneDetail(String model);

    String comparePhones(String modelA, String modelB);
}
