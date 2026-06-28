# 智慧记账 - 测试Bug修复指南

## P0 - 立即修复

### Bug #1: 键盘事件监听拼写错误

**文件**: `preview/index.html`  
**行号**: 2016

**修复前**:
```javascript
document.addEventListener('keydown', e => {
```

**修复后**:
```javascript
document.addEventListener('keydown', e => {
```

---

### Bug #2: 添加数据持久化

**问题**: 所有数据在刷新后丢失

**解决方案**: 使用 `localStorage` 持久化 `transactions` 数据

**步骤**:

1. **保存数据**（在每次数据变更后调用）

在 `confirmAdd()` 函数末尾添加：
```javascript
function confirmAdd() {
  if (!selectedCategory) return showToast('请选择分类');
  if (addAmount <= 0) return showToast('请输入金额');

  const t = {
    id: 't' + Date.now(),
    amount: addAmount,
    type: addType,
    categoryId: selectedCategory.id,
    date: new Date(),
    note: document.getElementById('note-input').value || selectedCategory.name
  };
  transactions.unshift(t);
  
  // ✅ 新增：保存到 localStorage
  saveTransactions();
  
  closeOverlay();
  showToast('记账成功 ✓');
  setTimeout(() => { switchTab(0); }, 300);
}
```

2. **创建 save/load 函数**

在 `// ══════════════════════════════════` 数据模型部分之后添加：

```javascript
// ══════════════════════════════════
// 数据持久化
// ══════════════════════════════════

const STORAGE_KEY = 'smart-ledger-data';

function saveTransactions() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
  } catch (e) {
    console.error('保存数据失败:', e);
  }
}

function loadTransactions() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      const parsed = JSON.parse(saved);
      // 恢复 Date 对象
      return parsed.map(t => ({
        ...t,
        date: new Date(t.date)
      }));
    }
  } catch (e) {
    console.error('加载数据失败:', e);
  }
  return null;
}

// 初始化时加载数据
const savedTransactions = loadTransactions();
if (savedTransactions && savedTransactions.length > 0) {
  transactions = savedTransactions;
}
```

3. **删除记录时也要保存**

添加删除功能（见P1修复）

---

## P1 - 高优先级修复

### Bug #3: 添加记录删除功能

**设计方案**: 长按记录项弹出删除确认

**实现步骤**:

1. **在记录项添加长按事件** (在 `renderHome()` 和 `renderRecords()` 中)

修改记录项HTML，添加 `oncontextmenu` 和长按逻辑：

```javascript
function renderRecords() {
  // ... 原有代码 ...
  
  container.innerHTML = Object.entries(groups).map(([key, items]) => {
    const [y,m] = key.split('-');
    const monthNames = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
    return `<div class="group-title">${y}年 ${monthNames[parseInt(m)-1]}</div>` +
      items.map(t => {
        const cat = findCat(t.categoryId);
        return `<div class="record-item fade-in-up" 
                    oncontextmenu="deleteTransaction('${t.id}'); return false;"
                    onclick="deleteTransaction('${t.id}')">
          <div class="icon-circle">${cat ? cat.icon : '📌'}</div>
          <div class="info">
            <div class="name">${cat ? cat.name : '其他'}</div>
            <div class="meta">${t.date.getDate()}日 · ${t.note || ''}</div>
          </div>
          <div class="amount" style="color:${t.type==='income'?'var(--income)':'var(--expense)'}">${t.type==='income'?'+':'-'}¥${fmtAmount(t.amount)}</div>
        </div>`;
      }).join('');
  }).join('');
}
```

2. **添加删除函数**

```javascript
function deleteTransaction(id) {
  if (!confirm('确定要删除这条记录吗？')) return;
  
  transactions = transactions.filter(t => t.id !== id);
  saveTransactions();  // ✅ 持久化
  
  showToast('已删除');
  renderHome();
  renderStats();
  renderRecords();
}
```

**注意**: 上面的实现是单击删除，实际应该使用长按（touchstart + long press timer）。为了简化，可以先使用单击删除并添加确认弹窗。

---

### Bug #4: 限制周度统计不能查看未来

**修复位置**: `navPeriod()` 函数

```javascript
function navPeriod(dir) {
  if (statsPeriod !== 'week') return;
  
  // ✅ 新增：不能查看未来
  if (dir > 0) {
    const nextWeek = statsWeekOffset + 1;
    const testDate = new Date();
    const day = testDate.getDay();
    const monday = new Date(testDate);
    monday.setDate(testDate.getDate() - (day === 0 ? 6 : day - 1) + nextWeek * 7);
    
    if (monday > new Date()) {
      showToast('不能查看未来数据');
      return;
    }
  }
  
  statsWeekOffset += dir;
  updateDateLabel();
  renderStats();
}
```

---

### Bug #5: 金额输入校验

**修复位置**: `numpadInput()` 函数

```javascript
function numpadInput(val) {
  if (val === '.') {
    if (addAmountStr.includes('.')) return;
    addAmountStr += '.';
  } else if (val === 'del') {
    addAmountStr = addAmountStr.slice(0, -1);
    if (addAmountStr === '' || addAmountStr === '-') addAmountStr = '0';
  } else if (val === 'ok') {
    confirmAdd();
    return;
  } else {
    // ✅ 新增：限制小数位数最多2位
    if (addAmountStr.includes('.')) {
      const decimals = addAmountStr.split('.')[1];
      if (decimals && decimals.length >= 2) return;
    }
    
    // ✅ 新增：限制最大金额（可选）
    if (parseFloat(addAmountStr + val) > 9999999) {
      showToast('金额过大');
      return;
    }
    
    if (addAmountStr === '0') {
      addAmountStr = val;
    } else {
      addAmountStr += val;
    }
  }
  
  addAmount = parseFloat(addAmountStr) || 0;
  document.getElementById('amount-display').textContent = '¥' + addAmountStr;
}
```

---

### Bug #6: 统一分类管理功能

**问题**: 记账流程中可以新增分类，但分类管理页面中的"新增分类"按钮显示"开发中"

**修复方案**: 让分类管理页面的"新增分类"按钮调用相同的 `openNewCategory()` 函数

**步骤**:

1. 修改分类管理页面的HTML（约第1197行）：

```html
<button class="btn-primary" style="margin-top:16px;background:transparent;color:var(--primary);border:1.5px dashed var(--divider)" 
        onclick="closeOverlay(); setTimeout(() => openNewCategory(), 300);">
  + 新增分类
</button>
```

2. 在 `openNewCategory()` 函数中，判断当前在哪个页面：

```javascript
function openNewCategory() {
  newCatEmoji = '👤';
  updateNewCatPreview();
  document.getElementById('new-cat-name').value = '';
  
  // ✅ 新增：如果在分类管理页面，先关闭它
  document.getElementById('overlay-category-mgmt').classList.remove('show');
  
  document.getElementById('new-cat-title').textContent = addType === 'expense' ? '新增支出分类' : '新增收入分类';
  renderEmojiPicker();
  document.getElementById('overlay-new-cat').classList.add('show');
}
```

---

## P2 - 中优先级修复

### Bug #7: 使用标准Emoji

**修复位置**: `CATEGORIES` 数组和 `renderEmojiPicker()` 函数

**建议**: 使用更通用的Emoji，避免使用可能显示不一致的Emoji

```javascript
const CATEGORIES = [
  { id:'food', name:'餐饮', icon:'🍽️', type:'expense' },  // 改用 🍽️
  { id:'transport', name:'交通', icon:'🚗', type:'expense' },  // 改用 🚗
  { id:'shopping', name:'购物', icon:'🛒', type:'expense' },  // 改用 🛒
  // ... 其他分类
];
```

---

### Bug #10: 延长Toast显示时间

**修复位置**: `showToast()` 函数

```javascript
function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.style.opacity = '1';
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.style.opacity = '0'; }, 3500);  // ✅ 改为3.5秒
}
```

---

## 测试验证清单

修复完成后，请按以下清单验证：

### P0 验证
- [ ] 键盘事件（桌面端输入金额）是否正常工作
- [ ] 添加记录后刷新页面，数据是否保留
- [ ] 清除浏览器数据后，应用是否能正常初始化

### P1 验证
- [ ] 长按/单击记录项是否能删除
- [ ] 周度统计右箭头在"本周"时是否禁用或提示
- [ ] 输入金额时，是否最多只能输入2位小数
- [ ] 分类管理页面的"新增分类"是否能正常打开

### P2 验证
- [ ] Emoji在各浏览器中是否显示一致
- [ ] Toast提示是否有足够时间阅读

---

## 附加建议

### 1. 添加清除演示数据功能

在设置页面添加"清除所有数据"按钮（带确认）：

```javascript
function clearAllData() {
  if (!confirm('确定要清除所有数据吗？此操作不可恢复！')) return;
  
  transactions = [];
  saveTransactions();
  
  renderHome();
  renderStats();
  renderRecords();
  
  showToast('已清除所有数据');
}
```

### 2. 添加数据导出功能

在设置页面的"导出数据"中，实现CSV导出：

```javascript
function exportToCSV() {
  let csv = '日期,类型,分类,金额,备注\n';
  transactions.forEach(t => {
    const cat = findCat(t.categoryId);
    csv += `${t.date.toLocaleDateString()},${t.type === 'income' ? '收入' : '支出'},${cat ? cat.name : '其他'},${t.amount},${t.note || ''}\n`;
  });
  
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `smart-ledger-${new Date().toISOString().slice(0,10)}.csv`;
  a.click();
}
```

---

## 总结

| 优先级 | Bug数量 | 修复工作量估计 |
|-------|---------|--------------|
| P0 | 2 | 0.5天 |
| P1 | 4 | 1-2天 |
| P2 | 4 | 0.5-1天 |

**建议**: 优先修复P0和P1问题，确保核心功能的完整性和数据安全性。
