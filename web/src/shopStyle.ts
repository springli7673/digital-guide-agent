/**
 * 新增界面的样式。
 *
 * 为什么不改 style.css：那份 19KB 是原始设计，一次只动一个可感知的东西——
 * 新增的样式集中注入在这里，出问题可以整块删掉，不牵连原有布局。
 */
const CSS = `
.tile-actions{display:flex;gap:8px;margin-top:10px;padding-top:10px;border-top:1px solid #f0f2f5}
.tile-actions button{flex:1;height:32px;border-radius:6px;font-size:13px;cursor:pointer;transition:.15s}
.btn-cart{background:#fff;border:1px solid #d4d7de;color:#4a4f5c}
.btn-cart:hover{border-color:#3b7cff;color:#3b7cff}
.btn-buy{background:#3b7cff;border:1px solid #3b7cff;color:#fff}
.btn-buy:hover{background:#2f6ae0}
.btn-primary{height:38px;padding:0 20px;border:none;border-radius:6px;background:#3b7cff;color:#fff;font-size:14px;cursor:pointer}
.btn-primary:disabled{opacity:.6;cursor:not-allowed}
.btn-link{background:none;border:none;color:#3b7cff;font-size:13px;cursor:pointer;margin-top:10px}

.login-wrap{display:flex;justify-content:center;padding:60px 20px}
.login-card{width:340px;background:#fff;border:1px solid #eef0f4;border-radius:12px;padding:28px 24px;box-shadow:0 4px 20px rgba(20,30,60,.06)}
.login-card h2{margin:0 0 8px;font-size:20px;color:#1f2430}
.login-tip{font-size:12px;color:#8a90a0;line-height:1.6;margin:0 0 18px}
.login-field{display:block;margin-bottom:14px}
.login-field span{display:block;font-size:12px;color:#6b7280;margin-bottom:6px}
.login-field input{width:100%;height:38px;padding:0 10px;border:1px solid #dfe3ea;border-radius:6px;font-size:14px;box-sizing:border-box}
.login-field input:focus{outline:none;border-color:#3b7cff}
.login-error{color:#e5484d;font-size:12px;margin:0 0 10px}

.cart-page{padding:24px 28px}
.cart-head{display:flex;align-items:baseline;gap:10px;margin-bottom:18px}
.cart-head h2{margin:0;font-size:20px;color:#1f2430}
.cart-count{font-size:13px;color:#8a90a0}
.cart-empty{background:#fff;border:1px solid #eef0f4;border-radius:12px;padding:40px;text-align:center;color:#6b7280}
.cart-list{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:10px}
.cart-row{display:flex;align-items:center;gap:14px;background:#fff;border:1px solid #eef0f4;border-radius:10px;padding:12px 16px}
.cart-thumb{width:56px;height:56px;border-radius:8px;background:#f6f7f9;display:flex;align-items:center;justify-content:center;overflow:hidden;font-size:12px;color:#9aa0ad}
.cart-thumb img{width:100%;height:100%;object-fit:contain}
.cart-info{flex:1;min-width:0}
.cart-model{margin:0 0 4px;font-size:14px;color:#1f2430}
.cart-price{margin:0;font-size:13px;color:#e5484d}
.cart-price em{font-style:normal;color:#f0a020;font-size:12px;margin-left:6px}
.cart-qty{display:flex;align-items:center;gap:6px}
.cart-qty button{width:26px;height:26px;border:1px solid #dfe3ea;background:#fff;border-radius:5px;cursor:pointer}
.cart-qty button:disabled{opacity:.4;cursor:not-allowed}
.cart-subtotal{width:100px;text-align:right;font-size:14px;font-weight:600;color:#1f2430}
.cart-del{background:none;border:none;color:#9aa0ad;font-size:12px;cursor:pointer}
.cart-del:hover{color:#e5484d}
.cart-foot{display:flex;justify-content:flex-end;align-items:center;gap:16px;margin-top:16px}
.cart-total{font-size:16px;font-weight:600;color:#e5484d}
.cart-ok{margin-top:14px;padding:10px 14px;background:#eefaf1;border:1px solid #cbeed6;border-radius:8px;color:#1a7f3c;font-size:13px}
.cart-error{margin-top:14px;color:#e5484d;font-size:13px}

.pending-bar{display:flex;align-items:center;gap:14px;margin:0 0 12px;padding:12px 16px;background:#fff8e6;border:1px solid #ffe1a3;border-radius:10px;font-size:13px;color:#8a5b00}
.pending-bar .pending-text{flex:1}
.pending-bar button{border:none;border-radius:6px;height:32px;padding:0 14px;cursor:pointer;font-size:13px}
.pending-bar .ok{background:#1a7f3c;color:#fff}
.pending-bar .no{background:#fff;color:#8a5b00;border:1px solid #ffe1a3}

.side-user{padding:10px 16px 14px;font-size:12px;color:#8a90a0;display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.side-user b{color:#1f2430;font-weight:600}
.side-user button{background:none;border:none;color:#3b7cff;cursor:pointer;font-size:12px;padding:0}
`

let injected = false

export function installShopStyles(): void {
  if (injected || typeof document === 'undefined') return
  injected = true
  const style = document.createElement('style')
  style.setAttribute('data-shop', '1')
  style.textContent = CSS
  document.head.appendChild(style)
}
