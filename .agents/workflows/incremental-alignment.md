---
description: 基於功能審計報告中的 Logic Gap，逐項實作或修復程式碼以達成功能對齊
---

# 🔧 增量式實作修復工作流 (Incremental Alignment) v4

本工作流以 `/feature-parity` 產出的審計報告為任務來源，逐項實作缺失功能或修復邏輯缺口。

---

## 核心產物

- 修改/新增後的 Dart 原始碼
- 更新後的 `FEATURE_AUDIT_v2.md`（完成度提升）
- 更新後的 `FEATURE_AUDIT_LOG.md`（狀態從 Logic Gap → Matched）

---

## 前置條件

- **必須先完成** `/feature-parity`，確保 `FEATURE_AUDIT_v2.md` 中有明確的「不足之處」清單
- 確認目標模組在 `FEATURE_AUDIT_LOG.md` 中有 `Logic Gap` 記錄

---

## 執行模式

### 模式 A：按優先級批量修復
從 `FEATURE_AUDIT_v2.md` 頂部儀表板選取 P0/P1 模組，全面修復。

### 模式 B：單點修復（預設）
使用者指定一個具體的 Logic Gap（如 `14.8 進度雲端即時同步`），僅修復該點。

---

## 執行步驟

### Step 1：從報告提取任務
// turbo
- 開啟 `FEATURE_AUDIT_v2.md`，找到目標模組的「不足之處」清單
- 開啟 `FEATURE_AUDIT_LOG.md`，找到對應的 `Logic Gap` 記錄
- 確認待修復的邏輯點與 Android 參考路徑

### Step 2：閱讀 Android 參考實作
// turbo
- 根據 `FEATURE_AUDIT_LOG.md` 中的證據鏈（檔案名:行號），讀取 Android 原始碼
- 提取核心邏輯：
  - 輸入/輸出資料結構
  - 演算法步驟
  - 邊際處理與例外情況
  - UI 互動行為

### Step 3：閱讀 iOS 當前程式碼
// turbo
- 根據地圖，讀取 iOS 對應檔案的當前狀態
- 確認修改插入點或新建檔案的位置
- 確認是否有需要重構的現有程式碼

### Step 4：實作修復
- **嚴格使用 `replace` 工具**進行精確代碼替換
- 修改策略：
  1. **新增邏輯**：在適當位置插入 Dart 實作
  2. **補全邊際**：補充缺失的 if/else 分支
  3. **新建檔案**：使用 `write_to_file` 建立全新的 Dart 檔案
- **禁止 `write_file` 覆寫已有檔案**

### Step 5：立即備份
- 每完成一個檔案的修改，立即在同一輪次執行：
```powershell
git add <modified_file> ; git commit -m "backup: update <file>"
```

### Step 6：驗證修復
- 執行靜態分析：
```powershell
flutter analyze
```
- 若有相關測試，執行：
```powershell
flutter test
```
- 若分析有錯誤，回到 Step 4 修復後重新驗證

### Step 7：更新報告
- 更新 `FEATURE_AUDIT_LOG.md`：
  - 將修復的 `Logic Gap` 狀態改為 `Matched`
  - 更新狀態描述，記錄修復方式
- 更新 `FEATURE_AUDIT_v2.md`：
  - 從「不足之處」移至「已完成項目」
  - 更新完成度百分比
  - 更新頂部儀表板

### Step 8：正式提交
```powershell
git add -A ; git commit -m "feat: implement [邏輯點描述] for [模組名]"
```

---

## 完成判定

- 所有目標 Logic Gap 已修復
- `flutter analyze` 無新增錯誤
- 報告已同步更新
- Git 已正式提交
- 回報使用者：修復摘要（修復了 X 個缺口，完成度從 Y% → Z%）

---

## 與其他工作流的關係

```
/feature-parity → 本工作流 → /debug（若修復後發現 bug）
本工作流 ─→ 更新報告 ─→ /feature-parity（可重新分析驗證）
```
