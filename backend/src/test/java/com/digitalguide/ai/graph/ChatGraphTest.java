package com.digitalguide.ai.graph;

import com.digitalguide.ai.llm.LlmClient;
import com.digitalguide.ai.llm.LlmException;
import com.digitalguide.ai.llm.LlmProperties;
import com.digitalguide.ai.llm.LlmRequest;
import com.digitalguide.ai.prompt.PromptLoader;
import com.digitalguide.ai.scoring.ScoringService;
import com.digitalguide.ai.scoring.SpecSchemaProvider;
import com.digitalguide.domain.Category;
import com.digitalguide.service.CategoryService;
import com.digitalguide.service.ProductService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 整条链路（parse → retrieve → score → answer）的集成测试。
 *
 * <p>模型和商品服务都用手写的假实现，不用 Mockito：
 * 一来不依赖 java agent（离线环境里 MockMaker 初始化会失败），
 * 二来假的 ProductService 一眼就能看出"给这条链路喂了什么数据"。
 */
class ChatGraphTest {

    private static final String INTENT_WITH_BUDGET = """
            {"category":"phone","budget_min":1800,"budget_max":3450,"budget_known":true,
             "must_have":["battery_mah"],"nice_to_have":[],"brands":[],
             "usage":"学生日常","need_clarify":false,"clarify_question":""}
            """;

    private static final String INTENT_NEED_CLARIFY = """
            {"category":"phone","budget_known":false,"must_have":[],
             "need_clarify":true,"clarify_question":"预算大概多少？"}
            """;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final LlmProperties llmProperties = new LlmProperties();
    private final PromptLoader prompts = new PromptLoader();

    @Test
    @DisplayName("正常链路：事件顺序固定，候选 3 款，回答逐字流出")
    void happyPath() {
        FakeProductService productService = new FakeProductService(List.of(
                product("小米", "Redmi K80", 2199, Map.of("battery_mah", 6550, "cpu_score", 300)),
                product("vivo", "iQOO Neo10", 2399, Map.of("battery_mah", 6100, "cpu_score", 320)),
                product("荣耀", "GT Pro", 2999, Map.of("battery_mah", 7200, "cpu_score", 280))));

        RecordingSink sink = new RecordingSink();
        ChatState state = graph(new FakeLlm(INTENT_WITH_BUDGET), productService)
                .run(new ChatState("预算3000，续航好点", "s1", List.of(), 0), sink);

        assertThat(sink.events())
                .containsSubsequence("status", "intent", "candidates", "token", "done");
        assertThat(state.getIntent()).isNotNull();
        assertThat(state.getIntent().mustHave()).containsExactly("battery_mah");
        assertThat(state.getRanked()).hasSize(3);
        // 续航是唯一偏好 → 电池容量最大的排第一，且展示分是候选集内相对分 100
        assertThat(state.getRanked().get(0).get("model")).isEqualTo("GT Pro");
        assertThat(state.getRanked().get(0).get("score")).isEqualTo(100);
        assertThat(state.getAnswer()).contains("推荐");
        assertThat(state.getClarify()).isNull();
        assertThat(state.getError()).isNull();
    }

    @Test
    @DisplayName("缺信息时只推 clarify，不检索也不调回答模型")
    void clarifyPathStopsBeforeRetrieve() {
        FakeProductService productService = new FakeProductService(List.of());

        RecordingSink sink = new RecordingSink();
        ChatState state = graph(new FakeLlm(INTENT_NEED_CLARIFY), productService)
                .run(new ChatState("推荐个手机", "s2", List.of(), 0), sink);

        assertThat(sink.events()).contains("intent", "clarify").doesNotContain("candidates");
        assertThat(state.getClarify()).isNotNull();
        assertThat(state.getClarify().get("options")).isNotNull();
        assertThat(state.getRanked()).isEmpty();
        // 追问分支不应该去查库
        assertThat(productService.callCount).isZero();
    }

    @Test
    @DisplayName("检索为空时报错并停下，不能凭空编型号")
    void emptyCandidatesEmitError() {
        RecordingSink sink = new RecordingSink();
        ChatState state = graph(new FakeLlm(INTENT_WITH_BUDGET), new FakeProductService(List.of()))
                .run(new ChatState("预算3000，续航好点", "s3", List.of(), 0), sink);

        assertThat(sink.events()).contains("error").doesNotContain("candidates");
        assertThat(state.getError()).isNotBlank();
        assertThat(state.getRanked()).isEmpty();
    }

    @Test
    @DisplayName("模型流式失败时退化成模板话术，用户不会看到空白")
    void answerFallsBackWhenModelFails() {
        FakeLlm llm = new FakeLlm(INTENT_WITH_BUDGET);
        llm.failStream = true;

        RecordingSink sink = new RecordingSink();
        ChatState state = graph(llm, new FakeProductService(List.of(
                product("小米", "Redmi K80", 2199, Map.of("battery_mah", 6550)))))
                .run(new ChatState("预算3000，续航好点", "s4", List.of(), 0), sink);

        assertThat(state.getAnswer()).contains("Redmi K80");
        assertThat(sink.events()).contains("token");
    }

    @Test
    @DisplayName("预算被钉死时，检索参数要带上区间")
    void retrievePassesBudget() {
        FakeProductService productService = new FakeProductService(List.of(
                product("小米", "Redmi K80", 2199, Map.of("battery_mah", 6550))));

        graph(new FakeLlm(INTENT_WITH_BUDGET), productService)
                .run(new ChatState("预算3000", "s5", List.of(), 0), new RecordingSink());

        assertThat(productService.lastMin).isEqualByComparingTo("1800");
        assertThat(productService.lastMax).isEqualByComparingTo("3450");
    }

    // ------------------------------------------------------------------ 装配

    private ChatGraph graph(LlmClient llm, ProductService productService) {
        return new ChatGraph(
                new ParseNode(llm, llmProperties, prompts, objectMapper),
                new RetrieveNode(productService),
                new ScoreNode(new ScoringService(), new SpecSchemaProvider(new FailingCategoryService(), objectMapper)),
                // 知识 / 工具路径在这几条用例里不会被走到（category 都是 phone），传 null 即可
                new KnowledgeNode(null, null, new com.digitalguide.ai.rag.RagProperties()),
                null,
                new AnswerNode(llm, llmProperties, prompts));
    }

    private static Map<String, Object> product(String brand, String model, int price, Map<String, Object> metrics) {
        Map<String, Object> specs = new LinkedHashMap<>();
        specs.put("metrics", metrics);
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", (long) model.hashCode());
        item.put("brand", brand);
        item.put("model", model);
        item.put("priceRef", BigDecimal.valueOf(price));
        item.put("imageUrl", "https://example.com/x.jpg");
        item.put("specs", specs);
        item.put("highlights", List.of("大电池"));
        return item;
    }

    private static LlmProperties newProperties() {
        return new LlmProperties();
    }

    // ------------------------------------------------------------------ 假实现

    /** 假装是模型：解析返回固定 JSON，回答吐三个分片 */
    private static final class FakeLlm implements LlmClient {

        private final String intentJson;
        private boolean failStream;

        private FakeLlm(String intentJson) {
            this.intentJson = intentJson;
        }

        @Override
        public String complete(LlmRequest request) {
            return intentJson;
        }

        @Override
        public void stream(LlmRequest request, Consumer<String> onToken) {
            if (failStream) {
                throw new LlmException("模拟模型宕机");
            }
            onToken.accept("推荐");
            onToken.accept("如下：");
            onToken.accept("综合参数最优的那款。");
        }

        @Override
        public String modelName() {
            return "fake";
        }

        @Override
        public boolean healthy() {
            return true;
        }
    }

    /** 假的商品服务：直接返回给定候选，并记录最后一次查询条件 */
    private static final class FakeProductService extends ProductService {

        private final List<Map<String, Object>> rows;
        private int callCount;
        private BigDecimal lastMin;
        private BigDecimal lastMax;

        private FakeProductService(List<Map<String, Object>> rows) {
            super(null, null, null, null, null, null, null);
            this.rows = rows;
        }

        @Override
        public List<Map<String, Object>> searchForAgent(String categoryCode, BigDecimal minPrice,
                                                        BigDecimal maxPrice, List<String> brands, int limit) {
            callCount++;
            lastMin = minPrice;
            lastMax = maxPrice;
            return rows;
        }
    }

    /** 类目服务故意抛异常，验证"类目配置坏了也要能退回兜底权重" */
    private static final class FailingCategoryService extends CategoryService {

        private FailingCategoryService() {
            super(null, null);
        }

        @Override
        public Category getByCode(String code) {
            throw new IllegalStateException("类目未配置");
        }
    }

    private static final class RecordingSink implements EventSink {

        private final List<String> events = new ArrayList<>();

        @Override
        public void emit(String event, Object data) {
            events.add(event);
        }

        private List<String> events() {
            return events;
        }
    }
}
