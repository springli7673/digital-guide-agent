<script setup lang="ts">
/**
 * 外壳：左侧目录 + 右侧内容。
 *
 * 「待确认下单」横幅放在这里而不是聊天页：agent 提议后用户可能已经切到别的路由，
 * 放在外壳上才不会丢。
 */
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ChatDotRound, Iphone, ShoppingCart } from '@element-plus/icons-vue'
import { useChatStore } from '@/stores/chatStore'
import { useShopStore } from '@/stores/shopStore'

const route = useRoute()
const shop = useShopStore()
const chat = useChatStore()

/**
 * 左上角 Logo（阿里云 OSS）。
 *
 * 放在外部存储上意味着：网络不通 / 对象被删 / 桶权限改成私有，图就没了。
 * 所以下面加了 fallback —— 加载失败时退回原来的「DG」色块，
 * 界面不会出现一个破图标。
 *
 * OSS 地址里没有扩展名是正常的（object key 就叫「数码导购logo」）；
 * 如果哪天上传时带了后缀，把这里改成 .../数码导购logo.png 即可。记得 URL 编码。
 */
const LOGO_URL =
  'https://digital-guide-20261030.oss-cn-beijing.aliyuncs.com/%E6%95%B0%E7%A0%81%E5%AF%BC%E8%B4%ADlogo'
const logoBroken = ref(false)

const menus = [
  { path: '/mall', label: '手机商城', icon: Iphone },
  { path: '/cart', label: '购物车', icon: ShoppingCart },
  { path: '/chat', label: '智能客服', icon: ChatDotRound },
]

onMounted(async () => {
  await shop.restoreSession()
  await shop.loadPending()
  chat.init()
})

async function onConfirm(): Promise<void> {
  const order = await shop.confirmPending()
  if (order) ElMessage.success(`下单成功：${order.orderNo}`)
  else if (shop.error) ElMessage.error(shop.error)
}
</script>

<template>
  <el-container class="app-shell">
    <el-aside width="220px" class="side">
      <div class="brand">
        <img
          v-if="!logoBroken"
          class="brand-logo brand-logo-img"
          :src="LOGO_URL"
          alt="数码导购"
          referrerpolicy="no-referrer"
          @error="logoBroken = true"
        />
        <div v-else class="brand-logo">DG</div>
        <div class="brand-text">
          <b>数码导购</b>
          <span>digital guide</span>
        </div>
      </div>

      <el-menu :default-active="route.path" router class="side-menu">
        <el-menu-item v-for="m in menus" :key="m.path" :index="m.path">
          <el-icon><component :is="m.icon" /></el-icon>
          <span>{{ m.label }}</span>
          <el-badge
            v-if="m.path === '/cart' && shop.cartCount > 0"
            :value="shop.cartCount"
            class="menu-badge"
          />
        </el-menu-item>
      </el-menu>

      <div class="side-user">
        <template v-if="shop.loggedIn">
          <span class="side-user-name">{{ shop.user?.nickname || shop.user?.username }}</span>
          <el-button link type="primary" size="small" @click="shop.logout()">退出</el-button>
        </template>
        <el-button v-else link type="primary" size="small" @click="$router.push('/login')">
          登录 / 注册
        </el-button>
      </div>
    </el-aside>

    <el-main class="main">
      <!-- agent 只能"提议"，真正下单要用户点这里 -->
      <el-alert
        v-if="shop.pending"
        class="pending"
        type="warning"
        :closable="false"
        show-icon
      >
        <div class="pending-body">
          <span>
            智能客服准备好了订单：{{ shop.pending.summary }}，合计 ¥{{ shop.pending.total }}。
            确认后才会扣库存。
          </span>
          <div class="pending-actions">
            <el-button type="primary" size="small" :loading="shop.busy" @click="onConfirm">
              确认下单
            </el-button>
            <el-button size="small" @click="shop.dismissPending()">先不买</el-button>
          </div>
        </div>
      </el-alert>

      <router-view />
    </el-main>
  </el-container>
</template>
