---
description: "[6] 基於 IOS_LEGADO_PARITY_REPORT.md 中的 Parity Gap 清單，按優先級逐項實作缺失功能"
---

# 🛠️ [6] 功能對齊修復工作流 (Parity Fix) v1

本工作流以 `IOS_LEGADO_PARITY_REPORT.md`（位於 `reader/` 根目錄）中的 **Parity Gap 清單** 為唯一任務來源，按 P0 → P1 → P2 → P3 優先級逐項實作或補全 iOS Flutter 專案中對 Legado Android 的缺失功能。

> **定位**：本工作流是專門針對功能差異報告的修復器。與 `/03-incremental-alignment` 不同，它以 `IOS_LEGADO_PARITY_REPORT.md` 的 Gap ID（`GAP-XX`）為索引，而非 `FEATURE_AUDIT_v2.md` 的 Logic Gap。

> **執行順序建議**：每修一個 Gap → 執行 `/04-debug` 驗證 → 更新報告 → Git commit → 下一個 Gap

---

## 核心產物

- 修改/新增後的 Dart 原始碼
- 更新後的 `IOS_LEGADO_PARITY_REPORT.md`（Gap 狀態由 ❌ → ✅ or ⚠️ → ✅）
- 同步更新 `ios/COMPREHENSIVE_FEATURE_MAPPING.md`（若新增對應關係）

---

## 前置條件

- `IOS_LEGADO_PARITY_REPORT.md` 存在於 `reader/` 根目錄
- iOS Flutter 專案位於 `reader/ios/`，Android 參照在 `reader/legado/`

---

## 執行模式

### 模式 A：按優先級自動批量修復（預設）
從報告中的 Gap 清單依序選取 **P0 → P1 → P2 → P3**，逐一完成。

### 模式 B：指定 Gap ID 單點修復
使用者提供一個 Gap ID（如 `GAP-01`），僅修復該項。

範例：
```
/06-parity-fix GAP-01
→ 僅修復 GAP-01（目錄/TOC 獨立頁面）
```

---

## 執行步驟

> [!IMPORTANT]
> **逐項修復原則**：每完成一個 Gap 的 Step 1~7 後，必須**立即執行 `/04-debug`** 驗證無新增錯誤，才能進入下一個 Gap。禁止累積多個 Gap 後才一起驗證。

### Step 0：確認任務來源

// turbo
- 開啟 `reader/IOS_LEGADO_PARITY_REPORT.md`
- 讀取 `<!-- BEGIN_PARITY_DASHBOARD -->` 儀表板，確認整體完成度
- 讀取 `<!-- BEGIN_GAP_LIST -->` 中的 Parity Gap 清單
- 根據執行模式決定本次要修復的 Gap 範圍
- 回報使用者：「本輪將修復以下 Gap：[GAP-XX, ...]」

---

### Step 1：提取 Gap 任務

// turbo
- 從報告的 Gap 清單中選取目標 Gap（按優先級或使用者指定）
- 記錄該 Gap 的：
  - **Gap ID**：如 `GAP-01`
  - **功能描述**：如「目錄/TOC 獨立頁面」
  - **Android 參照路徑**：如 `ui/book/toc/TocActivity.kt`
  - **iOS 當前狀態**：如「❌ 無對應頁面」
  - **所屬模組**：如「01-閱讀器」

---

### Step 2：閱讀 Android 參考實作

// turbo
- 根據 Gap 的 Android 參照路徑，讀取 `reader/legado/app/src/main/java/io/legado/app/` 下的源碼
- 需理解與提取：
  1. **UI 結構**：Activity/Fragment/Dialog 的佈局與主要 Widget
  2. **業務邏輯**：ViewModel 的核心方法、輸入/輸出、資料流
  3. **API 呼叫**：依賴的 DAO / Service / Repository
  4. **邊際處理**：空值防護、錯誤處理、Loading 狀態
  5. **Android 特有機制**（若有），評估 Flutter 等價替代方案

---

### Step 3：閱讀 iOS 當前狀態

// turbo
- 開啟 `reader/ios/COMPREHENSIVE_FEATURE_MAPPING.md`，定位該模組的對應關係
- 讀取 iOS 專案中最接近的現有檔案，確認：
  - 已有哪些邏輯可複用
  - 需要新建哪些檔案
  - 需要在現有檔案中插入哪些方法

---

### Step 4：設計 Flutter 等價實作

- 確認 Dart 實作方案：
  - **新建 Page**：`features/<module>/<gap>_page.dart` + `<gap>_provider.dart`
  - **新建 Service**：`core/services/<gap>_service.dart`
  - **補全現有檔案**：在對應 provider/page 中插入缺失方法
  - **新建 Widget**：抽取可復用的 Dialog/BottomSheet/Panel
- 確認依賴關係：需要引入哪些 DAO / Service

---

### Step 5：實作修復

- **新增檔案**：使用 `write_to_file` 建立全新的 Dart 檔案
- **修改現有檔案**：**優先使用 `replace` 工具**進行精確代碼替換

> [!CAUTION]
> **write_file 前後驗證鐵律**
> 1. **修改前**：必須先 `read_file` 完整讀取目標檔案，確認當前內容與結構
> 2. **執行 write_file**
> 3. **修改後**：立即再次 `read_file` 重新讀取整個檔案（特別是末尾區域），逐行比對確認：
>    - 所有閉合括號、類別定義是否完整
>    - 原有功能是否被意外截斷或遺失
>    - 新增的修復邏輯是否正確寫入
> 4. 若發現任何截斷或遺失，**立即回滾並改用 `replace` 工具**

- 在 `main.dart` 中確認路由/導航已正確串接

---

### Step 6：🐛 立即執行 `/04-debug`

> [!IMPORTANT]
> **此步驟不可跳過。** 每完成一個 Gap 的實作後，必須立即切換至 `/04-debug`。

```powershell
& 'C:\Program Files\Flutter\bin\flutter.bat' analyze
```

- 確認 `flutter analyze` 無新增 error/warning
- 若有錯誤：在當前 Gap 的修復範圍內完成修復後再繼續
- 確認後回到本工作流 Step 7

---

### Step 7：更新報告（使用區段錨點）

> [!IMPORTANT]
> 更新 `IOS_LEGADO_PARITY_REPORT.md` 時**必須遵循區段錨點規範**。

- 使用 `<!-- BEGIN_GAP_LIST -->` / `<!-- END_GAP_LIST -->` 或
  `<!-- BEGIN_MODULE_XX -->` / `<!-- END_MODULE_XX -->` 精確定位
- **一次 replace 只觸及一個 Gap 的狀態行**，禁止跨模組替換
- 更新內容：
  - Gap 表格中：`❌ 缺失` → `✅ 已實作` 或 `⚠️ 部分實作`
  - 更新 `<!-- BEGIN_PARITY_DASHBOARD -->` 中對應模組的完成度百分比
- 同步更新 `ios/COMPREHENSIVE_FEATURE_MAPPING.md` 的對應條目
- 驗證：`read_file` 確認相鄰模組錨點未被破壞

---

### Step 8：統一提交

> [!NOTE]
> 完成一個完整的 Gap 修復（含實作 + 除錯驗證 + 報告更新）後，才執行一次 Git commit。

```powershell
git add -A ; git commit -m "feat: implement [Gap 功能描述] (GAP-XX)"
```

---

### 🔁 Step 9：回到 Step 1，處理下一個 Gap

---

## Gap 修復進度追蹤

> 此節供執行時追蹤進度，每完成一個 Gap 後更新。

| Gap ID | 功能 | 優先級 | 狀態 |
|:---|:---|:---|:---|
| GAP-01 | 目錄 / TOC 獨立頁面 | 🔴 P0 | ⬜ 待修復 |
| GAP-02 | 朗讀控制 Dialog | 🔴 P0 | ⬜ 待修復 |
| GAP-03 | 完整 Restore 資料還原邏輯 | 🔴 P0 | ⬜ 待修復 |
| GAP-04 | 語音引擎選擇 Dialog | 🔴 P0 | ⬜ 待修復 |
| GAP-05 | 文字長按選單 | 🟠 P1 | ⬜ 待修復 |
| GAP-06 | 自動閱讀 / AutoPager | 🟠 P1 | ⬜ 待修復 |
| GAP-07 | Association 匯入框架 | 🟠 P1 | ⬜ 待修復 |
| GAP-08 | 字典查詢 UI + 規則管理 | 🟠 P1 | ⬜ 待修復 |
| GAP-09 | 頁眉 / 頁碼設定 Dialog | 🟠 P1 | ⬜ 待修復 |
| GAP-10 | 更多閱讀設定 Dialog | 🟠 P1 | ⬜ 待修復 |
| GAP-11 | 書內容全文搜尋 | 🟡 P2 | ⬜ 待修復 |
| GAP-12 | SlidePageDelegate 翻頁 | 🟡 P2 | ⬜ 待修復 |
| GAP-13 | 邊距設定 Dialog | 🟡 P2 | ⬜ 待修復 |
| GAP-14 | BgText 背景文字設定完整化 | 🟡 P2 | ⬜ 待修復 |
| GAP-15 | UMD 格式解析 | 🟡 P2 | ⬜ 待修復 |
| GAP-16 | TXT TOC 規則 | 🟡 P2 | ⬜ 待修復 |
| GAP-17 | 漫畫閱讀器完整化 | 🟡 P2 | ⬜ 待修復 |
| GAP-18 | WebView 書源登入完整流程 | 🟡 P2 | ⬜ 待修復 |
| GAP-19 | 封面來源設定 | 🟢 P3 | ⬜ 待修復 |
| GAP-20 | 歡迎頁設定 | 🟢 P3 | ⬜ 待修復 |
| GAP-21 | 主題列表 Dialog | 🟢 P3 | ⬜ 待修復 |
| GAP-22 | 崩潰捕獲 CrashHandler | 🟢 P3 | ⬜ 待修復 |
| GAP-23 | 書源內容編輯對話框 | 🟢 P3 | ⬜ 待修復 |

---

## 完成判定

- 所有目標 Gap 狀態變更為 ✅
- 每個 Gap 修復後都已通過 `/04-debug` 驗證（`flutter analyze` 無新增錯誤）
- `IOS_LEGADO_PARITY_REPORT.md` 儀表板完成度已更新
- `ios/COMPREHENSIVE_FEATURE_MAPPING.md` 已同步
- Git 已正式提交
- 回報使用者：修復摘要（修復了 X 個 Gap，整體完成度 65% → Y%）

---

## 與其他工作流的關係

| 工作流 | 關係 |
|:---|:---|
| `/03-incremental-alignment` | 本工作流的深度依賴，Step 5 的實作策略完全參照 03 的規範 |
| `/04-debug` | Step 6 強制呼叫，每個 Gap 完成後必須執行 |
| `/05-loop-runner` | 可呼叫本工作流作為迴圈目標：`/05-loop-runner 06 N` |

> [!TIP]
> **批量修復建議**：可使用 `/05-loop-runner 06 5` 自動重複執行本工作流 5 輪，每輪修復 1 個 P0/P1 Gap。
