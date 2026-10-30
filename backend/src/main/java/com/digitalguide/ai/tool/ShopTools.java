package com.digitalguide.ai.tool;

import com.digitalguide.ai.scoring.ScoringService;
import com.digitalguide.ai.scoring.SpecSchema;
import com.digitalguide.ai.scoring.SpecSchemaProvider;
import com.digitalguide.common.BizException;
import com.digitalguide.dto.CartView;
import com.digitalguide.dto.PendingActionView;
import com.digitalguide.service.CartService;
import com.digitalguide.service.PendingActionService;
import com.digitalguide.service.ProductService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 购物车相关工具。
 *
 * <p>和 {@link ProductTools} 的分工：那边只读（查商品），这里涉及用户数据和写操作。
 *
 * <p><b>一条铁律：这个类里没有一行代码会真的下单。</b>
 * {@code prepareOrder} 只生成一个待确认凭证，真正的执行要用户在前端点确认。
 * 模型可以"提议"，但不能"执行"——这是整套写路径的安全边界。
 *
 * <p><b>为什么不是单例 Bean</b>：工具执行发生在 Spring AI 的流式链路里，
 * 可能跑在 Reactor 的线程上，{@code UserContext}（ThreadLocal）在那里是空的——
 * 实测现象就是"购物车查不了，请先登录"。
 * 所以这里改成<b>每轮对话 new 一个</b>，userId 作为构造参数固定下来：
 * 身份是数据，不是线程状态。
 */
@Slf4j
public class ShopTools {

    private final Long userId;
    private final CartService cartService;
    private final ProductService productService;
    private final PendingActionService pendingActions;
    private final ScoringService scoringService;
    private final SpecSchemaProvider schemaProvider;

    public ShopTools(Long userId,
                     CartService cartService,
                     ProductService productService,
                     PendingActionService pendingActions,
                     ScoringService scoringService,
                     SpecSchemaProvider schemaProvider) {
        this.userId = userId;
        this.cartService = cartService;
        this.productService = productService;
        this.pendingActions = pendingActions;
        this.scoringService = scoringService;
        this.schemaProvider = schemaProvider;
    }

    @Tool(description = """
            把某款手机加入当前用户的购物车。型号必须来自检索结果，不要自己编。
            用户说"加入购物车""我要买这个""先放购物车"时用这个工具。""")
    public String addToCart(
            @ToolParam(description = "机型名，如「Redmi K80」") String model,
            @ToolParam(description = "数量，不传就传 1") int qty) {
        if (userId == null) {
            return "加购物车需要先登录，请让用户登录后再试。";
        }
        Map<String, Object> product = findOne(model);
        if (product == null) {
            return "库里没有找到「" + model + "」，先用 searchPhones 查一下有哪些型号。";
        }
        try {
            cartService.add(userId, asLong(product.get("id")), Math.max(qty, 1));
        } catch (BizException e) {
            return "加入购物车失败：" + e.getMessage();
        }
        CartView cart = cartService.view(userId);
        return "已加入购物车：" + product.get("brand") + " " + product.get("model")
                + "。购物车现在 " + cart.totalQty() + " 件，合计 ¥" + cart.total() + "。";
    }

    @Tool(description = "查看当前用户购物车里的商品、数量和合计金额。")
    public String viewCart() {
        if (userId == null) {
            return "查看购物车需要先登录。";
        }
        CartView cart = cartService.view(userId);
        if (cart.items().isEmpty()) {
            return "购物车是空的。";
        }
        StringBuilder sb = new StringBuilder();
        sb.append("购物车共 ").append(cart.totalQty()).append(" 件，合计 ¥").append(cart.total()).append("：\n");
        int index = 1;
        for (CartView.Line line : cart.items()) {
            sb.append(index++).append(". ").append(line.brand()).append(' ').append(line.model())
                    .append(" ×").append(line.qty())
                    .append("，¥").append(line.price()).append("，小计 ¥").append(line.subtotal());
            if (line.priceChanged()) {
                sb.append("（价格有变动）");
            }
            sb.append('\n');
        }
        return sb.toString().trim();
    }

    /**
     * 在购物车这个"子集"里重新打分。
     *
     * <p>复用 {@link ScoringService}——它本来就是"给定候选集算归一化加权分"的纯函数，
     * 这里只是把候选集从"SQL 全库过滤结果"换成"购物车里的几件"。
     * 一行排序代码都没新增，却多了一个能力。
     */
    @Tool(description = """
            对购物车里的商品做横向比较，给出最推荐的一款并说明理由。
            用户问"购物车里哪个最值""这几款里推荐哪个"时用这个工具。""")
    public String recommendFromCart() {
        if (userId == null) {
            return "查看购物车需要先登录。";
        }
        List<CartView.Line> lines = cartService.lines(userId);
        if (lines.isEmpty()) {
            return "购物车是空的，没有可以比较的商品。";
        }
        if (lines.size() == 1) {
            return "购物车里只有一款：" + lines.get(0).brand() + " " + lines.get(0).model()
                    + "，¥" + lines.get(0).price() + "。加到 2 款以上我才能帮你比较。";
        }

        Set<Long> ids = lines.stream().map(CartView.Line::productId).collect(Collectors.toSet());
        List<Map<String, Object>> rows = productService.searchForAgent("phone", null, null, null, 500)
                .stream()
                .filter(row -> ids.contains(asLong(row.get("id"))))
                .toList();
        if (rows.size() < 2) {
            return "购物车里的商品缺少足够的参数数据，暂时没法比较。";
        }

        Map<String, SpecSchema.Dim> schema = schemaProvider.schemaFor("phone");
        List<Map<String, Object>> ranked = scoringService.score(rows, schema, Map.of(), null);
        if (ranked.isEmpty()) {
            return "参数数据不足，算不出可靠排序。";
        }

        Map<String, Object> top = ranked.get(0);
        StringBuilder sb = new StringBuilder();
        sb.append("购物车里按综合参数最推荐：").append(top.get("brand")).append(' ')
                .append(top.get("model")).append("（¥").append(top.get("priceRef")).append("）。\n");
        Object reasons = top.get("reasons");
        if (reasons instanceof List<?> list && !list.isEmpty()) {
            sb.append("理由：").append(String.join("；", list.stream().map(String::valueOf).toList()));
        }
        if (ranked.size() > 1) {
            Map<String, Object> second = ranked.get(1);
            sb.append("\n次选：").append(second.get("brand")).append(' ').append(second.get("model"));
        }
        sb.append("\n（分数是这几款内部的相对排序，不是绝对评分。）");
        return sb.toString();
    }

    /**
     * 生成"待确认下单"。
     *
     * <p><b>不做任何写操作</b>：只把购物车快照成一个待确认动作，
     * 返回给模型一句提示。真正的订单由用户点确认后走 REST 接口执行。
     */
    @Tool(description = """
            准备下单：把购物车结算成一个待确认订单，但不会真的下单。
            用户说"帮我下单""结算""买单"时用这个工具；用户必须在前端点击确认才算完成。""")
    public String prepareOrder() {
        if (userId == null) {
            return "下单需要先登录。";
        }
        CartView cart = cartService.view(userId);
        if (cart.items().isEmpty()) {
            return "购物车是空的，没法下单。";
        }
        String summary = cart.items().stream()
                .map(line -> line.brand() + " " + line.model() + " ×" + line.qty())
                .collect(Collectors.joining("；"));
        PendingActionView action;
        try {
            String confirmId = pendingActions.create(userId, "CHECKOUT", summary, cart.total(), cart.totalQty());
            action = new PendingActionView(confirmId, "CHECKOUT", summary, cart.total(), cart.totalQty());
        } catch (RuntimeException e) {
            log.warn("生成待确认动作失败：{}", e.getMessage());
            return "生成确认凭证失败，请稍后重试。";
        }
        return "已准备好订单：" + summary + "，合计 ¥" + action.total()
                + "。请让用户在前端点「确认下单」完成支付，未确认前不会扣款也不会扣库存。";
    }

    // ------------------------------------------------------------------ 内部

    /** 按型号模糊匹配一款；匹配到多个时取最短的（K80 不该命中 K80 Pro Max） */
    private Map<String, Object> findOne(String modelName) {
        if (modelName == null || modelName.isBlank()) {
            return null;
        }
        String needle = modelName.trim().toLowerCase().replace(" ", "");
        Map<String, Object> best = null;
        int bestLen = Integer.MAX_VALUE;
        for (Map<String, Object> row : productService.searchForAgent("phone", null, null, null, 500)) {
            String combined = (row.get("brand") + String.valueOf(row.get("model")))
                    .toLowerCase().replace(" ", "");
            if (combined.contains(needle) && combined.length() < bestLen) {
                best = row;
                bestLen = combined.length();
            }
        }
        return best;
    }

    private static long asLong(Object value) {
        return value instanceof Number number ? number.longValue() : Long.parseLong(String.valueOf(value));
    }
}
