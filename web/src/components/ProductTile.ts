/** 商城里的一张商品卡片：主图、品牌型号、存储、关键参数、参考价（淘宝式：图在上） */
import { computed, ref } from '../vue.js'

const ProductTile = {
  name: 'ProductTile',
  props: {
    item: { type: Object, required: true },
  },
  setup(props) {
    const broken = ref(false)

    const thumb = computed(() => props.item.imageThumb || props.item.imageUrl || '')
    const showImage = computed(() => Boolean(thumb.value) && !broken.value)

    const priceText = computed(() => {
      const p = props.item.priceRef
      if (p === null || p === undefined) return '暂无报价'
      return '¥' + Number(p).toLocaleString('zh-CN')
    })

    /** title 形如「荣耀WIN Turbo2（16GB/512GB）」，把括号里的存储单独拿出来 */
    const storage = computed(() => {
      const match = /[（(]([^）)]+)[）)]/.exec(props.item.title || '')
      return match ? match[1] : ''
    })

    const chips = computed(() => {
      const m = props.item.metrics || {}
      const out = []
      if (m.battery_mah) out.push(m.battery_mah + 'mAh')
      if (m.charge_w) out.push(m.charge_w + 'W')
      if (m.rear_mp) out.push(m.rear_mp + '万像素')
      if (m.weight_g) out.push(m.weight_g + 'g')
      return out
    })

    return { broken, thumb, showImage, priceText, storage, chips }
  },
  template: `
    <article class="tile">
      <div class="tile-img">
        <img v-if="showImage" :src="thumb" :alt="item.brand + item.model"
             loading="lazy" @error="broken = true" />
        <span v-else class="tile-img-fallback">{{ item.brand }}</span>
      </div>

      <div class="tile-top">
        <span class="tile-brand">{{ item.brand }}</span>
        <span class="tile-date" v-if="item.launchDate">{{ item.launchDate }}</span>
      </div>
      <h3 class="tile-title">{{ item.brand }} {{ item.model }}</h3>
      <p class="tile-sub" v-if="storage">{{ storage }}</p>
      <div class="tile-chips">
        <span v-for="c in chips" :key="c">{{ c }}</span>
      </div>
      <div class="tile-foot">
        <span class="tile-price">{{ priceText }}</span>
        <small>参考价</small>
      </div>
    </article>
  `,
}

export default ProductTile
