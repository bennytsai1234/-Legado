---
description: "[2/4] 基於結構地圖，對每個模組進行邏輯級別的語義比對分析，生成功能審計報告"
---

# 🔍 [2/4] 功能對齊分析工作流 (Feature Parity Audit) v6

本工作流為遷移管線的**第二步**。深入每個模組進行原始碼級別的語義比對，識別「偽對齊」並產出審計報告。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 🏗️ 嚴謹稽核規範 (Rigorous Audit Mandate)

> [!DANGER]
> **拒絕空殼對齊**：禁止因 iOS 存在同名檔案而直接標註為 `Matched`。
> 1. **占位符搜查**：必須檢索 `_showComingSoon`, `unimplemented`, `TODO` 等關鍵字。凡有此類標識，該功能點一律視為 `Logic Gap`。
> 2. **API 完整性矩陣 (Completeness Matrix)**：必須列出 Android 類別的所有 **Public Methods**，並在 iOS 對應檔案中逐一對照。
> 3. **平台敏感性分析**：涉及系統權限（背景任務、儲存權限、原生 UI）的邏輯，必須單獨標註其 iOS 實作方案。

---

## 執行步驟

### Step 1：讀取地圖與盤點
- 開啟 `COMPREHENSIVE_FEATURE_MAPPING.md`。
- 準備目標模組的 Android 原始碼與 iOS 原始碼。

### Step 2：建立 API 完整性矩陣
- **分析 Android 端**：列出所有業務關鍵函式。
- **對照 iOS 端**：
  - 存在且邏輯一致 → `Matched`
  - 存在但功能缺失/空殼 → `🚨 Placeholder`
  - 完全不存在 → `Logic Gap`

### Step 3：深度邏輯比對
- 比較關鍵演算法（如：分頁、正則處理、JS 變數傳遞）的具體步驟。
- 檢查異常處理 (Exception Handling) 是否對齊。

### Step 4：寫入 FEATURE_AUDIT_v2.md
- **證據鏈明細升級**：

| 邏輯點 / Method | Android 證據 | iOS 證據 | 狀態 | 診斷描述 |
| :--- | :--- | :--- | :--- | :--- |
| `loadChapters` | `BookDao.kt`: L40 | `book_dao.dart`: L50 | ✅ Matched | 邏輯一致 |
| `changeIcon` | `Helper.kt`: L10 | `ui.dart`: `_showSoon` | 🚨 Placeholder | UI 存在但無實作內容 |

### Step 5：計算真實完成度
- **計算公式**：`Matched / (Matched + Equivalent + Logic Gap + Placeholder)`
- **注意**：`Placeholder` 絕對不計入分子。

### Step 6：Git 備份
- `git add FEATURE_AUDIT_v2.md ; git commit -m "audit: update parity report"`

---

## 下一步
→ 執行 **`/03-incremental-alignment`** 修復 Logic Gap 與 Placeholder
