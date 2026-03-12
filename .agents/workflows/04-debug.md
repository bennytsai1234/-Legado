---
description: "[4/4] 針對已實作但有 bug 的功能，系統性地排查、定位根因並修復"
---

# 🐛 [4/4] 除錯工作流 (Debug) v1

本工作流為遷移管線的**第四步**，用於系統性排查並修復 runtime bug。修復過程中應**主動參考地圖與審計報告**以理解檔案關聯與預期行為。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 核心產物

- 修復後的 Dart 原始碼
- 更新後的 `FEATURE_AUDIT_v2.md`（若涉及已記錄模組）

---

## 前置條件與預設行為

> [!IMPORTANT]
> **當使用者未提供任何錯誤資訊時**，預設執行 `flutter analyze` 作為起點，自動收集所有靜態分析警告與錯誤，並逐一修復。

- 若使用者提供了錯誤訊息 / 堆疊追蹤 → 直接進入 Step 2
- 若使用者未提供任何資訊 → 執行 Step 1 自動掃描

---

## 錯誤分類

| 類型 | 特徵 | 排查策略 |
|:---|:---|:---|
| **編譯錯誤** | `flutter analyze` 報錯 | 直接定位檔案行號修復 |
| **型別錯誤** | `type 'X' is not a subtype of type 'Y'` | 追蹤資料流，找型別不匹配源頭 |
| **空值錯誤** | `Null check operator used on a null value` | 追蹤可空鏈路，補空值防護 |
| **邏輯錯誤** | 功能運作但結果不正確 | 對照 Android 原始碼比對差異 |
| **UI 錯誤** | 畫面渲染異常或互動失效 | 檢查 Widget 樹與 State 管理 |
| **併發錯誤** | 競態條件或死鎖 | 檢查 async/await 鏈與 Completer |
| **效能問題** | 卡頓或記憶體洩漏 | Profile 分析熱點函式 |

---

## 執行步驟

### Step 1：自動掃描（無錯誤資訊時的預設行為）
// turbo
```powershell
flutter analyze
```
- 收集所有 warning / error
- 按嚴重度排序（error → warning → info）
- 產生待修復清單

### Step 2：堆疊追蹤定位
// turbo
- 從錯誤訊息或分析結果中提取：
  - 出錯的檔案路徑與行號
  - 呼叫鏈中的關鍵節點
  - 觸發條件

### Step 3：參考地圖 + 原始碼閱讀
// turbo
- **先讀地圖**：開啟 `COMPREHENSIVE_FEATURE_MAPPING.md`，找到出錯檔案所屬的模組，了解 Android 端對應的檔案與責任區
- **再讀報告**：開啟 `FEATURE_AUDIT_v2.md`，查看該模組的已知狀態、已完成項目與不足之處，判斷 bug 是否與已知 Logic Gap 相關
- **讀取出錯檔案**：讀取錯誤發生位置的完整原始碼
- **追蹤依賴鏈**：根據地圖中的對應關係，讀取相關依賴檔案（Provider、Service、DAO 等）
- **對照 Android**：若為邏輯錯誤，讀取 Android 端對應檔案確認正確行為
- 理解資料流：輸入 → 處理邏輯 → 輸出

### Step 4：根因分析 (Root Cause Analysis)
- 建立假設 → 驗證假設：
  - 邏輯錯誤 → 對照 Android 原始碼
  - 型別錯誤 → 追蹤資料轉換鏈
  - 空值錯誤 → 確認資料來源
- 確認根因後記錄

### Step 5：修復實作
- **優先使用 `replace` 工具**進行精確代碼替換
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

### Step 6：驗證修復
```powershell
flutter analyze
```
- 確認問題已消除且無新增錯誤
- 若有相關測試：`flutter test test/<related_test>.dart`

### Step 7：更新報告（若涉及已記錄模組）
- 更新 `FEATURE_AUDIT_v2.md` 中的對應模組狀態

### Step 8：段落完成後統一提交
> [!NOTE]
> 完成一個完整的 bug 修復（含驗證通過 + 報告更新）後，才執行一次 Git commit。
> 不要每改一個檔案就 commit，避免產生大量碎片化提交。

```powershell
git add -A ; git commit -m "fix: [bug 描述簡述]"
```

---

## 完成判定

- `flutter analyze` 無新增警告/錯誤
- Git 已正式提交
- 回報使用者：根因分析與修復方式摘要
