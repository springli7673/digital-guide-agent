package com.digitalguide.ai.mcp;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * MCP 协议层的回归测试。
 *
 * <p>这一层最容易"看起来能用、实际不合规"：客户端只按 JSON-RPC 解析，
 * 少一个 {@code jsonrpc} 字段、通知回了包、错误码用错，表现都是"连上但工具用不了"。
 * 所以这里逐条钉报文本身，不去跑真实进程。
 */
class McpServerTest {

    private final ObjectMapper mapper = new ObjectMapper();

    /** 记录最后一次调用参数的假工具 */
    private static final class FakeTools implements McpToolTarget {
        String lastSearch;
        boolean explode;

        @Override
        public String searchPhones(int minPrice, int maxPrice, String brands) {
            if (explode) {
                throw new IllegalStateException("数据库挂了");
            }
            lastSearch = minPrice + "-" + maxPrice + ":" + brands;
            return "1. 小米 Redmi K80，参考价 ¥2,199";
        }

        @Override
        public String phoneDetail(String model) {
            return "详情：" + model;
        }

        @Override
        public String comparePhones(String modelA, String modelB) {
            return "对比：" + modelA + " vs " + modelB;
        }
    }

    private JsonNode call(McpServer server, String request) throws Exception {
        String response = server.handle(request);
        assertThat(response).as("应当有回包").isNotNull();
        JsonNode node = mapper.readTree(response);
        assertThat(node.path("jsonrpc").asText()).isEqualTo("2.0");
        return node;
    }

    @Test
    @DisplayName("initialize 回协议版本与 serverInfo")
    void initialize() throws Exception {
        JsonNode node = call(new McpServer(new FakeTools()),
                "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}");

        assertThat(node.path("id").asInt()).isEqualTo(1);
        assertThat(node.path("result").path("protocolVersion").asText())
                .isEqualTo(McpServer.PROTOCOL_VERSION);
        assertThat(node.path("result").path("serverInfo").path("name").asText())
                .isEqualTo(McpServer.SERVER_NAME);
        assertThat(node.path("result").path("capabilities").has("tools")).isTrue();
    }

    @Test
    @DisplayName("tools/list 暴露 3 个工具，且每个都带 inputSchema")
    void toolsList() throws Exception {
        McpServer server = new McpServer(new FakeTools());
        JsonNode tools = call(server, "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}")
                .path("result").path("tools");

        assertThat(tools.isArray()).isTrue();
        assertThat(tools).hasSize(3);
        assertThat(server.toolNames()).containsExactly("searchPhones", "phoneDetail", "comparePhones");
        for (JsonNode tool : tools) {
            assertThat(tool.hasNonNull("description")).isTrue();
            assertThat(tool.path("inputSchema").path("required").isArray()).isTrue();
        }
    }

    @Test
    @DisplayName("tools/call 把 arguments 透传给工具，结果包成 content 数组")
    void toolsCall() throws Exception {
        FakeTools fake = new FakeTools();
        JsonNode node = call(new McpServer(fake), """
                {"jsonrpc":"2.0","id":3,"method":"tools/call","params":
                  {"name":"searchPhones","arguments":{"minPrice":2000,"maxPrice":3000,"brands":"小米"}}}
                """);

        assertThat(fake.lastSearch).isEqualTo("2000-3000:小米");
        JsonNode result = node.path("result");
        assertThat(result.path("isError").asBoolean()).isFalse();
        assertThat(result.path("content").get(0).path("type").asText()).isEqualTo("text");
        assertThat(result.path("content").get(0).path("text").asText()).contains("Redmi K80");
    }

    @Test
    @DisplayName("工具内部异常包成 isError=true，而不是 JSON-RPC 错误")
    void toolFailureIsResultNotError() throws Exception {
        FakeTools fake = new FakeTools();
        fake.explode = true;
        JsonNode node = call(new McpServer(fake), """
                {"jsonrpc":"2.0","id":4,"method":"tools/call","params":
                  {"name":"searchPhones","arguments":{"minPrice":0,"maxPrice":0,"brands":""}}}
                """);

        assertThat(node.has("error")).isFalse();
        assertThat(node.path("result").path("isError").asBoolean()).isTrue();
        assertThat(node.path("result").path("content").get(0).path("text").asText())
                .contains("数据库挂了");
    }

    @Test
    @DisplayName("未知方法回 -32601")
    void unknownMethod() throws Exception {
        JsonNode node = call(new McpServer(new FakeTools()),
                "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"resources/list\"}");

        assertThat(node.path("error").path("code").asInt()).isEqualTo(-32601);
    }

    @Test
    @DisplayName("非法 JSON 回 -32700")
    void badJson() throws Exception {
        JsonNode node = call(new McpServer(new FakeTools()), "{not json");
        assertThat(node.path("error").path("code").asInt()).isEqualTo(-32700);
    }

    @Test
    @DisplayName("通知（没有 id）不回包")
    void notificationGetsNoResponse() {
        McpServer server = new McpServer(new FakeTools());
        assertThat(server.handle("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"))
                .isNull();
        assertThat(server.handle("   ")).isNull();
    }
}
