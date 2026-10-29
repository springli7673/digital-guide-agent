package com.digitalguide.ai.mcp;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.NullNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 一个最小的 MCP Server：JSON-RPC 2.0 over stdio。
 *
 * <p><b>为什么手写而不是引 spring-ai-mcp</b>：
 * <ul>
 *   <li>协议本身只用到 5 个方法（initialize / initialized / ping / tools-list / tools-call），
 *       引一个 starter 换来的自动装配，在这里不如 200 行代码直白；</li>
 *   <li>工具的实现已经在进程内（{@link McpToolTarget}），MCP 只是<b>另一个入口</b>，
 *       不需要再引入一套服务端框架、也不需要把业务搬出去；</li>
 *   <li>手写之后，协议行为是可以用单测固定住的——引框架反而只能端到端试。</li>
 * </ul>
 *
 * <p>传输层约定（MCP 的 stdio 模式）：stdin/stdout 每行一条 JSON-RPC 报文，
 * <b>stdout 里绝对不允许出现其它内容</b>，日志一律走 stderr。
 */
public class McpServer {

    /** MCP 的协议版本；客户端会拿它跟自己的版本比对 */
    public static final String PROTOCOL_VERSION = "2024-11-05";
    public static final String SERVER_NAME = "digital-guide-agent";
    public static final String SERVER_VERSION = "1.0.0";

    private final McpToolTarget tools;
    private final ObjectMapper mapper = new ObjectMapper();

    public McpServer(McpToolTarget tools) {
        this.tools = tools;
    }

    /**
     * 处理一条报文。
     *
     * @return 要写回 stdout 的一行 JSON；对通知（没有 id）返回 {@code null}，表示不回包。
     */
    public String handle(String line) {
        if (line == null || line.isBlank()) {
            return null;
        }
        JsonNode root;
        try {
            root = mapper.readTree(line);
        } catch (Exception e) {
            return errorResponse(null, -32700, "Parse error");
        }
        if (root == null || !root.isObject()) {
            return errorResponse(null, -32700, "Parse error");
        }

        JsonNode id = root.get("id");
        String method = root.path("method").asText("");
        if (method.isEmpty()) {
            return id == null ? null : errorResponse(id, -32600, "Invalid Request: missing method");
        }
        // 通知（如 notifications/initialized）没有 id，协议要求不回包
        if (id == null) {
            return null;
        }

        return switch (method) {
            case "initialize" -> resultResponse(id, initializeResult());
            case "ping" -> resultResponse(id, Map.of());
            case "tools/list" -> resultResponse(id, obj("tools", toolDefinitions()));
            case "tools/call" -> resultResponse(id, callTool(root.path("params")));
            default -> errorResponse(id, -32601, "Method not found: " + method);
        };
    }

    /** 给测试与自检用：当前暴露的工具名 */
    public List<String> toolNames() {
        return toolDefinitions().stream().map(definition -> String.valueOf(definition.get("name"))).toList();
    }

    // ------------------------------------------------------------------ 方法实现

    private Map<String, Object> initializeResult() {
        return obj(
                "protocolVersion", PROTOCOL_VERSION,
                "capabilities", obj("tools", obj("listChanged", false)),
                "serverInfo", obj("name", SERVER_NAME, "version", SERVER_VERSION));
    }

    private Map<String, Object> callTool(JsonNode params) {
        String name = params.path("name").asText("");
        JsonNode arguments = params.path("arguments");
        try {
            String text = switch (name) {
                case "searchPhones" -> tools.searchPhones(
                        arguments.path("minPrice").asInt(0),
                        arguments.path("maxPrice").asInt(0),
                        arguments.path("brands").asText(""));
                case "phoneDetail" -> tools.phoneDetail(arguments.path("model").asText(""));
                case "comparePhones" -> tools.comparePhones(
                        arguments.path("modelA").asText(""),
                        arguments.path("modelB").asText(""));
                default -> throw new IllegalArgumentException("未知工具：" + name);
            };
            return obj("content", List.of(obj("type", "text", "text", text)), "isError", false);
        } catch (RuntimeException e) {
            /*
             * 工具内部异常不能抛给调用方——JSON-RPC 层要回一个"结果"，
             * 把错误包在 isError 里，让模型自己决定下一步（重试/换工具/告知用户）。
             */
            String message = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
            return obj("content", List.of(obj("type", "text", "text", "工具执行失败：" + message)),
                    "isError", true);
        }
    }

    /**
     * 工具清单。inputSchema 手写而不是从注解反射：
     * 只有 3 个工具、字段也少，手写能把 required 和描述控制得更准，
     * 而反射生成的 schema 经常把 Optional 和包装类型处理错。
     */
    private List<Map<String, Object>> toolDefinitions() {
        return List.of(
                obj("name", "searchPhones",
                        "description", "按预算和品牌检索在售手机，返回机型、参考价和关键参数。",
                        "inputSchema", obj(
                                "type", "object",
                                "properties", obj(
                                        "minPrice", obj("type", "integer", "description", "最低价（元），不限传 0"),
                                        "maxPrice", obj("type", "integer", "description", "最高价（元），不限传 0"),
                                        "brands", obj("type", "string", "description", "品牌，逗号分隔；不限传空串")),
                                "required", List.of("minPrice", "maxPrice", "brands"))),
                obj("name", "phoneDetail",
                        "description", "查询某个具体机型的完整参数。型号要来自检索结果，不要自己编。",
                        "inputSchema", obj(
                                "type", "object",
                                "properties", obj(
                                        "model", obj("type", "string", "description", "机型名，如「Redmi K80」")),
                                "required", List.of("model"))),
                obj("name", "comparePhones",
                        "description", "对比两款机型的参数差异。两个型号都要来自检索结果。",
                        "inputSchema", obj(
                                "type", "object",
                                "properties", obj(
                                        "modelA", obj("type", "string", "description", "第一款机型名"),
                                        "modelB", obj("type", "string", "description", "第二款机型名")),
                                "required", List.of("modelA", "modelB"))));
    }

    // ------------------------------------------------------------------ 报文拼装

    private String resultResponse(JsonNode id, Object payload) {
        ObjectNode node = mapper.createObjectNode();
        node.put("jsonrpc", "2.0");
        node.set("id", id);
        node.set("result", mapper.valueToTree(payload));
        return write(node);
    }

    private String errorResponse(JsonNode id, int code, String message) {
        ObjectNode node = mapper.createObjectNode();
        node.put("jsonrpc", "2.0");
        node.set("id", id == null ? NullNode.getInstance() : id);
        ObjectNode error = node.putObject("error");
        error.put("code", code);
        error.put("message", message);
        return write(node);
    }

    private String write(JsonNode node) {
        try {
            return mapper.writeValueAsString(node);
        } catch (Exception e) {
            // 理论不可达：node 是我们自己拼的。真到了这里也要给调用方一个合法报文
            return "{\"jsonrpc\":\"2.0\",\"id\":null,\"error\":{\"code\":-32603,\"message\":\"Internal error\"}}";
        }
    }

    /** 变长键值对构造 Map，省掉 Map.of 最多 10 对的限制和类型推断噪音 */
    private static Map<String, Object> obj(Object... pairs) {
        Map<String, Object> map = new LinkedHashMap<>();
        for (int i = 0; i + 1 < pairs.length; i += 2) {
            map.put(String.valueOf(pairs[i]), pairs[i + 1]);
        }
        return map;
    }
}
