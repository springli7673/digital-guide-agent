package com.digitalguide.ai.mcp;

import com.digitalguide.DigitalGuideApplication;
import com.digitalguide.ai.tool.ProductTools;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;

import java.io.BufferedReader;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;

/**
 * 以 MCP Server（stdio）方式启动同一套工具。
 *
 * <pre>
 *   java -cp ... com.digitalguide.ai.mcp.McpServerMain
 * </pre>
 *
 * <p><b>为什么复用整个 Spring 上下文</b>：这 3 个工具背后是 {@code ProductService}
 * （MyBatis + 连接池），把它拆成独立进程反而要重新配一套数据源。
 * 用 {@link WebApplicationType#NONE} 关掉 Web 容器即可——多余的是 HTTP 端口，
 * 不是业务依赖。
 *
 * <p><b>stdout 的纪律</b>：MCP 的 stdout 只能出现 JSON-RPC 报文。
 * 所以这里先把原始 stdout 抢下来专门写协议，再让 {@code System.out} 指向 stderr，
 * 这样 Spring Boot 的 banner 和所有日志都自动改道，
 * 不需要逐条去改 logback 配置（改漏一条就是客户端解析失败）。
 */
public final class McpServerMain {

    private McpServerMain() {
    }

    public static void main(String[] args) throws Exception {
        PrintStream protocolOut = new PrintStream(
                new FileOutputStream(FileDescriptor.out), true, StandardCharsets.UTF_8);
        PrintStream logOut = new PrintStream(
                new FileOutputStream(FileDescriptor.err), true, StandardCharsets.UTF_8);
        System.setOut(logOut);

        ConfigurableApplicationContext context = new SpringApplicationBuilder(DigitalGuideApplication.class)
                .web(WebApplicationType.NONE)
                .run(args);

        McpServer server = new McpServer(context.getBean(ProductTools.class));
        BufferedReader reader = new BufferedReader(
                new InputStreamReader(System.in, StandardCharsets.UTF_8));

        try {
            String line;
            while ((line = reader.readLine()) != null) {
                String response = server.handle(line);
                if (response != null) {
                    protocolOut.println(response);
                    protocolOut.flush();
                }
            }
        } finally {
            context.close();
        }
    }
}
