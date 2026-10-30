import { createRouter, createWebHistory } from 'vue-router'

/**
 * 四条路由，和产品结构一一对应：
 *   /mall  手机商城（默认）
 *   /cart  购物车
 *   /chat  智能客服
 *   /login 登录 / 注册
 *
 * 刻意不加全局守卫：/cart 在未登录时由页面自己显示"去登录"，
 * 直接重定向会让用户丢掉"我刚才在看哪"的上下文。
 */
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/mall' },
    {
      path: '/mall',
      name: 'mall',
      component: () => import('@/views/MallView.vue'),
      meta: { title: '手机商城' },
    },
    {
      path: '/cart',
      name: 'cart',
      component: () => import('@/views/CartView.vue'),
      meta: { title: '购物车' },
    },
    {
      path: '/chat',
      name: 'chat',
      component: () => import('@/views/ChatView.vue'),
      meta: { title: '智能客服' },
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { title: '登录' },
    },
    { path: '/:pathMatch(.*)*', redirect: '/mall' },
  ],
})

router.afterEach((to) => {
  const title = (to.meta.title as string) || '数码导购'
  document.title = `${title} · 数码导购`
})

export default router
