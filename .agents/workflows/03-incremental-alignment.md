---
description: "[3/4] 根據審計報告的缺口進行代碼實作與功能對齊"
---

# 🔧 [3/4] 功能對齊實作工作流 (Parity Alignment) v1

本工作流專注於將 `FEATURE_AUDIT_v2.md` 中記錄的 **Logic Gap** 或 **Placeholder** 轉化為 100% 對齊的實作。

---

## 🏗️ 實作鐵律 (Implementation Mandate)

> [!DANGER]
> **1. 外科手術式修改**：優先使用 `replace` 植入邏輯，禁止無意義的 `write_file` 全量覆寫，保持檔案結構穩定。
> **2. 零占位符協定**：嚴禁寫入 `// 同 Android` 或 `/* 此處省略 */`。所有產出的程式碼必須是完整、可編譯且邏輯閉環的。
> **3. 嚴謹同步**：核心演算法（如：解密、緩存校驗、規則解析）必須與 Legado Android 原始碼邏輯 100% 平移。

---

## 執行步驟

### Step 1：任務提取
- 開啟 `FEATURE_AUDIT_v2.md`，定位到最新的「比對報告」區塊。
- 挑選一個標註為 `❌ Logic Gap` 或 `🚨 Placeholder` 的功能點作為本次實作目標。

### Step 2：參考實作研究
- **讀取 Android 原始碼**：理解目標功能的資料流、邊際條件（Edge Cases）與異常處理。
- **讀取 iOS 現狀**：確認目前的類別結構、Provider 狀態與可用的 Utility 函式。

### Step 3：外科手術式實作
- **邏輯植入**：
  - 若為現有檔案補全：使用 `replace` 在正確的 Method 位置插入邏輯。
  - 若為新功能：建立對應的新檔案。
- **依賴檢查**：確保所需之 Service (如 `BookDao`, `WebDavService`) 已正確注入。

### Step 4：品質校核
- **無退化驗證**：確保原子修改未影響該檔案原有的其他功能。
- **語法自查**：檢查是否有漏掉的 `import` 或括號未閉合。

### Step 5：更新審計報告
- 在 `FEATURE_AUDIT_v2.md` 對應位置將 `[ ]` 標註為 `[x]` 或變更狀態為 `✅ Matched`。

### Step 6：Git 備份
- `git add <file> ; git commit -m "feat: align logic for [功能] (from audit)"`

---

## 下一步
→ 執行 **`/04-debug-loop`** 驗證實作後的程式碼正確性。
