---
description: "[3/4] 基於功能審計報告中的 Logic Gap，逐項實作或修復程式碼以達成功能對齊"
---

# 🔧 [3/4] 增量式實作修復工作流 (Incremental Alignment) v7

本工作流為遷移管線的**第三步**。以 `/02-feature-parity` 產出的審計報告為任務來源，逐項實作缺失功能或修復邏輯缺口。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 核心產物

- 修改/新增後的 Dart 原始碼
- 更新後的 `FEATURE_AUDIT_v2.md`（完成度提升、Logic Gap → Matched）

---

## 🏗️ 零簡化開發鐵律 (Zero Simplification Mandate)

> [!DANGER]
> **嚴禁因「程式碼過長」或「重寫麻煩」而簡化實作。**
> 1. **禁絕 Placeholder**：嚴禁寫入 `// ... rest of code` 或 `/* methods omitted */` 等占位符。
> 2. **完整性優先**：對現有大型 Provider (如 ReaderProvider) 進行修改時，必須確保**原有所有業務方法、Getter、Setter 100% 保留**。
> 3. **外科手術式修改**：除非必要，否則應優先使用 `replace` 進行局部植入，而非全量 `write_file`。

---

## 前置條件

- **必須先完成** `/02-feature-parity`，確保 `FEATURE_AUDIT_v2.md` 中有明確的「不足之處」或 `Logic Gap`

---

## 執行模式

### 模式 A：按優先級批量修復
從 `FEATURE_AUDIT_v2.md` 頂部儀表板選取 P0/P1 模組，全面修復。

### 模式 B：單點修復（預設）
使用者指定一個具體的 Logic Gap（如 `14.8 進度雲端即時同步`），僅修復該點。

---

## 執行步驟

> [!IMPORTANT]
> **逐項修復原則**：每完成「一個 Logic Gap」的 Step 1~6 後，必須**立即執行 `/04-debug`** 進行除錯驗證，確認無問題後才可進入下一個 Logic Gap。

### Step 1：從報告提取任務
- 開啟 `FEATURE_AUDIT_v2.md`，找到目標模組的「不足之處」清單與證據鏈明細。

### Step 2：閱讀 Android 參考實作
- 讀取原始碼，提取核心邏輯：演算法步驟、邊際處理、UI 行為。

### Step 3：閱讀 iOS 當前程式碼 (核心防禦)
- **必須 `read_file` 獲取目標檔案的完整內容**（若檔案過大，需分段讀取並在記憶體中拼接）。
- 標註出所有**不可遺失**的現有功能點。

### Step 4：實作修復 (結構安全模式)
- **規範工具選用**：
  - **優先級 1 (`replace`)**：針對單一邏輯點的局部替換。
  - **優先級 2 (`write_file`)**：僅限於建立全新檔案，或經過 Step 3 完整讀取後的大規模重構。
- **重構保護協議**：
  - 若執行 `write_file`，內容必須包含該檔案**原本所有的邏輯**加上新實作的邏輯。
  - **嚴禁在 `write_file` 參數中使用任何省略符號。**

### Step 5：結構校驗 (Mandatory)
- **修改後立即回讀**：必須再次 `read_file` 該檔案。
- **一致性比對**：確認檔案行數、閉合括號與 Step 3 標註的「不可遺失功能」是否依然存在。
- 若發現功能遺失，**視為重大事故**，必須立即透過 `git checkout <file>` 回滾並重新實作。

### Step 6：更新報告
- 更新 `FEATURE_AUDIT_v2.md` 的狀態描述與完成度。

### Step 7：🐛 執行 `/04-debug`
- 確認 `flutter analyze` 與 `flutter test` 無新增錯誤。

### Step 8：Git 備份
- `git add <file> ; git commit -m "feat: implement [邏輯點]"`

---

## 完成判定
- 所有 Logic Gap 已修復且**無功能退化 (No Regression)**。
