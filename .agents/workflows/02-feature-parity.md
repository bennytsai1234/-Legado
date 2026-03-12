---
description: "[2/4] 基於結構地圖，對每個模組進行邏輯級別的語義比對分析，生成功能審計報告"
---

# 🔍 [2/4] 功能對齊分析工作流 (Feature Parity Audit) v4

本工作流為遷移管線的**第二步**。基於 `/01-structure-mapping` 產出的地圖，深入每個模組做**原始碼級別的語義比對**，生成審計報告。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 核心產物

- **`FEATURE_AUDIT_v2.md`**（單一報告，同時包含模組級總覽 + 原子級證據鏈）

> [!NOTE]
> 報告採雙層結構：頂部為模組級儀表板與完成度追蹤，每個模組章節內包含證據鏈明細表格。
> 新的審計結果直接追加至對應模組章節內，不再維護獨立的 LOG 檔案。

---

## 前置條件

- **必須先完成** `/01-structure-mapping`，確保 `COMPREHENSIVE_FEATURE_MAPPING.md` 存在

---

## 執行模式判定

> [!IMPORTANT]
> **自動判定邏輯**：檢查 `FEATURE_AUDIT_v2.md` 是否存在。
> - **不存在** → 預設為 **全量審計**（按地圖順序逐一審計所有模組）
> - **已存在** → 預設為 **增量審計**（等待使用者指定目標模組）

### 模式 A：全量審計（預設：報告不存在時）
按地圖中的 ID 順序，從零建立完整的審計報告。

### 模式 B：增量審計（預設：報告已存在時）
使用者指定模組 ID 或名稱（如 `14. 核心閱讀器`），僅審計該模組並更新對應章節。

---

## 執行步驟

### Step 1：讀取地圖定位
// turbo
- 開啟 `COMPREHENSIVE_FEATURE_MAPPING.md`
- 定位目標模組，取得 Android / iOS 的檔案路徑清單

### Step 2：Android 端深度提取
// turbo
- 逐一讀取 Android 端所有相關檔案（Kotlin + XML 佈局）
- **提取重點**（建立特徵清單）：
  1. **UI 進入點**：所有 Activity/Fragment 的 UI 初始化與互動回調
  2. **判定分支**：所有影響顯示與資料的 `if/else`、`when`、`switch`
  3. **核心演算**：正則表達式、排序比較器、加密解密、分頁公式
  4. **邊際處理**：空值防護、異常捕獲、預設值回退
  5. **資料流**：ViewModel → UI 的 LiveData/StateFlow 綁定

### Step 3：iOS 端精確閱讀
// turbo
- 根據地圖，直接開啟 iOS 對應檔案（Dart）
- 對照 Step 2 的特徵清單，逐條檢核：
  - 這段邏輯在 iOS 是否存在？
  - 處理流程是否一致？（忽略變數命名差異）
  - 是否有語義等效但寫法不同的實作？

### Step 4：標註與分類
- 對每個邏輯點標註狀態：
  - **`Matched`**：邏輯完全一致
  - **`Equivalent`**：語義對等但實作方式不同（需說明差異）
  - **`Logic Gap`**：iOS 完全缺失此邏輯（需說明缺失影響）

### Step 5：寫入 FEATURE_AUDIT_v2.md
- **模組章節結構**：

```markdown
## XX. 模組名稱

**模組職責**：...
**Legado 檔案**：...
**Flutter (iOS) 對應檔案**：...
**完成度：XX%**
**狀態：✅/⚠️/🚨**

**已完成項目 ✅**：
- ✅ ...

**不足之處**：
- [ ] ...

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **X.Y 名稱** | `檔案.kt`: L行號 (函式名) | `檔案.dart`: L行號 (函式名) | **Matched** | 描述 |
```

- 編號規則：`模組ID.序號`（如 `14.1`、`14.2`）
- **證據鏈必須包含**：檔案名、行號、函式名或關鍵標識

### Step 6：更新頂部儀表板
- 同步更新報告頂部的「總覽儀表板」表格中的對應模組行

### Step 7：Git 備份
```powershell
git add FEATURE_AUDIT_v2.md ; git commit -m "audit: complete module [模組名] parity analysis"
```

---

## 完成判定

- 所有目標模組的邏輯點已逐條比對
- `FEATURE_AUDIT_v2.md` 對應章節已更新（含證據鏈明細）
- 儀表板已同步
- Git 已備份
- 回報使用者：審計摘要（X 個 Matched / Y 個 Logic Gap）

---

## 下一步

→ 執行 **`/03-incremental-alignment`** 修復 Logic Gap
