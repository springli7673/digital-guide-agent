<script setup lang="ts">
/** 登录 / 注册（同一个表单，切换模式） */
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { useShopStore } from '@/stores/shopStore'

const shop = useShopStore()
const router = useRouter()

const mode = ref<'login' | 'register'>('login')
const formRef = ref<FormInstance>()

const form = reactive({
  username: '',
  password: '',
  nickname: '',
})

const isRegister = computed(() => mode.value === 'register')
const title = computed(() => (isRegister.value ? '注册账号' : '登录'))
const submitText = computed(() => (isRegister.value ? '注册并登录' : '登录'))

const rules = computed<FormRules>(() => ({
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { pattern: /^[A-Za-z0-9_]{3,32}$/, message: '3-32 位字母、数字或下划线', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 64, message: '密码长度需在 6-64 之间', trigger: 'blur' },
  ],
}))

function toggle(): void {
  mode.value = isRegister.value ? 'login' : 'register'
  formRef.value?.clearValidate()
}

async function submit(): Promise<void> {
  if (!formRef.value) return
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  try {
    if (isRegister.value) {
      await shop.register(form.username.trim(), form.password, form.nickname.trim())
    } else {
      await shop.login(form.username.trim(), form.password)
    }
    // 登录前攒下的加购动作，登录后自动补上
    await shop.replayPendingIntent()
    ElMessage.success(isRegister.value ? '注册成功' : '登录成功')
    void router.push('/mall')
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : String(e))
  }
}
</script>

<template>
  <div class="login-wrap">
    <el-card class="login-card" shadow="never">
      <h2>{{ title }}</h2>
      <p class="login-tip">
        登录后，智能客服会记住你聊过的内容，购物车也会跟着你的账号走。
      </p>

      <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="3-32 位字母、数字或下划线" autocomplete="username" />
        </el-form-item>

        <el-form-item label="密码" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            show-password
            placeholder="至少 6 位"
            autocomplete="current-password"
          />
        </el-form-item>

        <el-form-item v-if="isRegister" label="昵称">
          <el-input v-model="form.nickname" placeholder="不填就用用户名" />
        </el-form-item>

        <el-button type="primary" class="submit" :loading="shop.busy" @click="submit">
          {{ submitText }}
        </el-button>
      </el-form>

      <el-button link type="primary" class="toggle" @click="toggle">
        {{ isRegister ? '已有账号？去登录' : '没有账号？去注册' }}
      </el-button>
    </el-card>
  </div>
</template>

<style scoped>
.login-wrap {
  display: flex;
  justify-content: center;
  padding: 56px 20px;
}

.login-card {
  width: 360px;
  border-radius: var(--dg-radius);
  border: 1px solid var(--dg-border);
  box-shadow: var(--dg-shadow);
}

.login-card h2 {
  margin: 0 0 8px;
  font-size: 20px;
}

.login-tip {
  margin: 0 0 18px;
  font-size: 12px;
  line-height: 1.7;
  color: var(--dg-text-3);
}

.submit {
  width: 100%;
  height: 40px;
  margin-top: 4px;
}

.toggle {
  margin-top: 10px;
  width: 100%;
}
</style>
