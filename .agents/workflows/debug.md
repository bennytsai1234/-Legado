---
description: 針對已實作但有 bug 的功能，系統性地排查、定位根因並修復
---

# 🐛 除錯工作流 (Debug) v1

本工作流獨立於地圖與報告管線，用於系統性排查並修復 runtime bug。

---

## 核心產物

- 修復後的 Dart 原始碼
- 除錯日誌（記錄排查過程與根因分析）
- 更新後的報告（若涉及已記錄的模組）

---

## 前置條件

- 使用者提供以下至少一項：
  - 錯誤訊息 / 堆疊追蹤 (Stack Trace)
  - Bug 復現步驟
  - 預期行為 vs 實際行為描述
  - 相關的 flutter analyze 警告

---

## 錯誤分類

在開始排查前，先分類 bug 類型以決定策略：

| 類型 | 特徵 | 排查策略 |
|:---|:---|:---|
| **編譯錯誤** | `flutter analyze` 報錯 | 直接定位檔案行號修復 |
| **型別錯誤** | `type 'X' is not a subtype of type 'Y'` | 追蹤資料流，找到型別不匹配的源頭 |
| **空值錯誤** | `Null check operator used on a null value` | 追蹤可空鏈路，補充空值防護 |
| **邏輯錯誤** | 功能運作但結果不正確 | 對照 Android 原始碼比對邏輯差異 |
| **UI 錯誤** | 畫面渲染異常或互動失效 | 檢查 Widget 樹與 State 管理 |
| **併發錯誤** | 競態條件或死鎖 | 檢查 async/await 鏈與 Completer 使用 |
| **效能問題** | 卡頓或記憶體洩漏 | Profile 分析熱點函式 |

---

## 執行步驟

### Step 1：資訊收集與分類
- 記錄使用者提供的錯誤資訊
- 分類 bug 類型（參考上表）
- 若資訊不足，向使用者詢問補充

### Step 2：堆疊追蹤定位
// turbo
- 從錯誤訊息或堆疊追蹤中提取：
  - 出錯的檔案路徑與行號
  - 呼叫鏈（Call Stack）中的關鍵節點
  - 觸發條件（哪個操作導致錯誤）

### Step 3：原始碼閱讀與上下文理解
// turbo
- 讀取錯誤發生位置的完整檔案
- 追蹤相關的依賴檔案（Provider、Service、DAO 等）
- 理解資料流：輸入從哪來 → 處理邏輯 → 輸出到哪

### Step 4：根因分析 (Root Cause Analysis)
- 建立假設：基於程式碼閱讀提出可能的根因
- 驗證假設：
  - 若為邏輯錯誤 → 對照 Android 原始碼確認正確行為
  - 若為型別錯誤 → 追蹤完整的資料轉換鏈
  - 若為空值錯誤 → 確認資料來源是否有保證非空
- 確認根因後記錄

### Step 5：修復實作
- **嚴格使用 `replace` 工具**進行精確代碼替換
- 修復策略按 bug 類型：
  - **型別錯誤**：修正資料模型的型別宣告或增加安全轉換
  - **空值錯誤**：增加空值檢查或設定預設值
  - **邏輯錯誤**：對照 Android 重寫邏輯分支
  - **UI 錯誤**：修正 Widget 結構或 State 更新時機
- **禁止 `write_file` 覆寫已有檔案**

### Step 6：立即備份
```powershell
git add <modified_file> ; git commit -m "backup: update <file>"
```

### Step 7：驗證修復
- 執行靜態分析：
```powershell
flutter analyze
```
- 若使用者提供了復現步驟，請使用者確認是否修復
- 若有相關單元測試：
```powershell
flutter test test/<related_test>.dart
```

### Step 8：更新報告（可選）
- 若修復的 bug 涉及 `FEATURE_AUDIT_LOG.md` 或 `FEATURE_AUDIT_v2.md` 中已記錄的模組：
  - 更新對應狀態
  - 記錄修復方式

### Step 9：正式提交
```powershell
git add -A ; git commit -m "fix: [bug 描述簡述]"
```

---

## 完成判定

- `flutter analyze` 無新增警告/錯誤
- 使用者確認 bug 已修復（或提供驗證步驟的通過截圖）
- Git 已正式提交
- 回報使用者：根因分析摘要與修復方式

---

## 與其他工作流的關係

```
/incremental-alignment → 本工作流（修復實作過程中發現的 bug）
本工作流 ─→ 更新報告 ─→ /feature-parity（重新分析確認修復）
```
