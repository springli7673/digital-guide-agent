<script setup lang="ts">
/** 流式阶段的进度提示：理解需求 → 检索候选 → 参数打分 → 组织话术 */
import { computed } from 'vue'
import type { StatusPayload } from '@/types'

const props = defineProps<{ status: StatusPayload }>()

const STEPS: Array<{ key: string; label: string }> = [
  { key: 'parsing', label: '理解需求' },
  { key: 'searching', label: '检索候选' },
  { key: 'scoring', label: '参数打分' },
  { key: 'answering', label: '组织话术' },
]

const current = computed(() => STEPS.findIndex((s) => s.key === props.status.stage))
</script>

<template>
  <div class="status">
    <span class="spinner" />
    <span class="status-text">{{ status.text }}</span>
    <span class="steps">
      <i
        v-for="(s, i) in STEPS"
        :key="s.key"
        :class="{ done: i < current, active: i === current }"
      >{{ s.label }}</i>
    </span>
  </div>
</template>

<style scoped>
.status {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 4px;
  font-size: 12px;
  color: var(--dg-text-3);
}

.spinner {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  border: 2px solid var(--el-color-primary-light-7);
  border-top-color: var(--dg-primary);
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.status-text {
  color: var(--dg-text-2);
}

.steps {
  display: flex;
  gap: 8px;
  margin-left: auto;
}

.steps i {
  font-style: normal;
  opacity: 0.45;
  transition: opacity var(--dg-transition), color var(--dg-transition);
}

.steps i.done {
  opacity: 1;
  color: var(--dg-text-2);
}

.steps i.active {
  opacity: 1;
  color: var(--dg-primary);
  font-weight: 600;
}
</style>
