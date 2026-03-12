---
description: "[3/4] 基於功能審計報告中的 Logic Gap，逐項實作或修復程式碼以達成功能對齊"
---

# 🔧 [3/4] 增量式實作修復工作流 (Incremental Alignment) v4

本工作流為遷移管線的**第三步**。以 `/02-feature-parity` 產出的審計報告為任務來源，逐項實作缺失功能或修復邏輯缺口。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 核心產物

- 修改/新增後的 Dart 原始碼
- 更新後的 `FEATURE_AUDIT_v2.md`（完成度提升、Logic Gap → Matched）

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

### Step 1：從報告提取任務
// turbo
- 開啟 `FEATURE_AUDIT_v2.md`，找到目標模組的「不足之處」清單與證據鏈明細
- 確認待修復的邏輯點與 Android 參考路徑

### Step 2：閱讀 Android 參考實作
// turbo
- 根據證據鏈中的 Android 路徑與行號，讀取原始碼
- 提取核心邏輯：輸入/輸出、演算法步驟、邊際處理、UI 行為

### Step 3：閱讀 iOS 當前程式碼
// turbo
- 根據地圖，讀取 iOS 對應檔案的當前狀態
- 確認修改插入點或新建檔案的位置

### Step 4：實作修復
- **優先使用 `replace` 工具**進行精確代碼替換
- 修改策略：
  1. **新增邏輯**：在適當位置插入 Dart 實作
  2. **補全邊際**：補充缺失的 if/else 分支
  3. **新建檔案**：使用 `write_to_file` 建立全新的 Dart 檔案
- 若逼不得已需使用 `write_file` 覆寫，**必須遵守以下鐵律**：

> [!CAUTION]
> **write_file 前後驗證鐵律**
> 1. **修改前**：必須先 `read_file` 完整讀取目標檔案，確認當前內容與結構
> 2. **執行 write_file**
> 3. **修改後**：立即再次 `read_file` 重新讀取整個檔案（特別是末尾區域），逐行比對確認：
>    - 所有閉合括號、類別定義是否完整
>    - 原有功能是否被意外截斷或遺失
>    - 新增的修復邏輯是否正確寫入
> 4. 若發現任何截斷或遺失，**立即回滾並改用 `replace` 工具**

### Step 5：驗證修復
```powershell
flutter analyze
```
- 若有相關測試：`flutter test`
- 若有錯誤，回到 Step 4 修復

### Step 6：更新報告
- 更新 `FEATURE_AUDIT_v2.md`：
  - 證據鏈明細中：`Logic Gap` → `Matched`，更新狀態描述
  - 「不足之處」移至「已完成項目」
  - 更新完成度百分比與頂部儀表板

### Step 7：段落完成後統一提交
> [!NOTE]
> 完成一個完整的 Logic Gap 修復（含驗證通過 + 報告更新）後，才執行一次 Git commit。
> 不要每改一個檔案就 commit，避免產生大量碎片化提交。

```powershell
git add -A ; git commit -m "feat: implement [邏輯點描述] for [模組名]"
```

---

## 完成判定

- 所有目標 Logic Gap 已修復
- `flutter analyze` 無新增錯誤
- `FEATURE_AUDIT_v2.md` 已同步更新
- Git 已正式提交
- 回報使用者：修復摘要（修復了 X 個缺口，完成度 Y% → Z%）

---

## 下一步

→ 若修復後有 bug，執行 **`/04-debug`** 進行除錯
