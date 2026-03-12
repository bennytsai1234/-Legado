---
description: 基於結構地圖，對每個模組進行邏輯級別的語義比對分析，生成功能審計報告
---

# 🔍 功能對齊分析工作流 (Feature Parity Audit) v4

本工作流基於 `/structure-mapping` 產出的地圖，深入每個模組做**原始碼級別的語義比對**，生成可執行的審計報告。

---

## 核心產物

- **`FEATURE_AUDIT_v2.md`**（模組級報告，追加更新對應章節）
- **`FEATURE_AUDIT_LOG.md`**（原子級證據鏈日誌，追加更新）

---

## 前置條件

- **必須先完成** `/structure-mapping`，確保 `COMPREHENSIVE_FEATURE_MAPPING.md` 中有目標模組的檔案對應關係

---

## 執行模式

### 模式 A：全量審計
按地圖中的 ID 順序，逐一審計所有模組。

### 模式 B：增量審計（預設）
使用者指定模組 ID 或名稱（如 `14. 核心閱讀器`），僅審計該模組。

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

### Step 5：追加至 FEATURE_AUDIT_LOG.md（原子級）
- 將每條邏輯點的比對結果追加到 `FEATURE_AUDIT_LOG.md`
- **嚴格格式**（與現有格式一致）：

```markdown
| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **X.Y 邏輯點名稱** | `檔案名.kt`: L行號 (關鍵函式名) | `檔案名.dart`: L行號 (關鍵函式名) | **Matched/Equivalent/Logic Gap** | 具體描述 |
```

- 編號規則：`模組ID.序號`（如 `14.1`、`14.2`）
- **證據鏈必須包含**：檔案名、行號、函式名或關鍵標識

### Step 6：更新 FEATURE_AUDIT_v2.md（模組級）
- 更新目標模組在 `FEATURE_AUDIT_v2.md` 中的章節：
  - 更新完成度百分比
  - 更新狀態標籤
  - 更新「不足之處」清單（從 `Logic Gap` 項目提取）
  - 更新「B 工作流任務」建議
- 同步更新頂部「總覽儀表板」中的對應行

### Step 7：同步更新 FEATURE_AUDIT_LOG.md 導航總表
- 更新 `FEATURE_AUDIT_LOG.md` 頂部的導航總表：
  - 更新該模組的邏輯達成率
  - 更新關鍵邏輯缺口摘要

### Step 8：Git 備份
- 每完成一個模組的審計：
```powershell
git add FEATURE_AUDIT_v2.md FEATURE_AUDIT_LOG.md ; git commit -m "audit: complete module [模組名] parity analysis"
```

---

## 完成判定

- 所有目標模組的邏輯點已逐條比對
- `FEATURE_AUDIT_LOG.md` 有完整的證據鏈記錄
- `FEATURE_AUDIT_v2.md` 對應章節已更新
- 導航總表已同步
- Git 已備份
- 回報使用者：審計摘要（X 個 Matched / Y 個 Logic Gap）

---

## 與其他工作流的關係

```
/structure-mapping → 本工作流 → /incremental-alignment
                                （以 Logic Gap 清單為任務輸入）
```
