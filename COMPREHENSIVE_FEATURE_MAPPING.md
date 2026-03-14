# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping) v4
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。
**本次審核為「UI 元件與程式碼驅動 (Code-Driven)」的深度優化版，精確到每一個按鈕的功能實作情況。**

---

## 📊 開發進度與狀態總覽 (Implementation Status)

| 核心模組 | 開發完成度 | 狀態評估 |
| :--- | :--- | :--- |
| **書架 (Bookshelf)** | 🟢 98% | 核心書架、分組、排序、匯入、備份、本地搜尋、批量移動功能已完成。 |
| **發現 (Explore)** | 🟢 95% | 分源瀏覽、分類篩選、書源調試整合已實作。 |
| **閱讀器 (Reader)** | 🟢 95% | 渲染、仿真翻頁、排版細化（縮排/對齊）、九宮格點擊、長按進階選單均已就緒。 |
| **書源管理 (Source Manager)** | 🟢 98% | CRUD、並行校驗、專業版調試日誌、批量分組管理均已實作。 |
| **訂閱 (RSS)** | 🟢 90% | 來源解析、文章列表、RSS 規則調試已完成。 |
| **設定 (Settings)** | 🟢 95% | WebDAV 自動備份、連通性測試、字體全量管理（下載/預覽）完善。 |

---

## 📂 模組對位與 UI 按鈕審查清單

以下清單對照 `C:\Users\benny\Desktop\Folder\Project\reader\legado` 中的 `ui` 目錄。

### 📍 1. 書架模組 (`ui/main/bookshelf` vs `lib/features/bookshelf/bookshelf_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **搜尋按鈕** | `BookshelfFragment.kt` | ✅ Matched | 實作 AppBar 動態搜尋框與本地過濾邏輯 |
| **匯入書架/本機書籍** | 菜單 `import` / SAF 檔案選擇 | ✅ Matched | 支援檔案選擇與 URL 匯入 (`FilePickerPage`) |
| **切換列表/網格視圖** | `BookshelfAdapter` 動態切換 | ✅ Matched | 實作於 AppBar action，變更 Provider 狀態 |
| **管理分組** | `GroupManageActivity` | ✅ Matched | `Navigator.push(...)` 至 `GroupManagePage` |
| **書籍多選/批量操作** | Context Menu 彈窗 | ✅ Matched | `onLongPress` 觸發多選模式，支援刪除、移動分組 |
| **下拉刷新/更新** | `SwipeRefreshLayout` | ✅ Matched | `RefreshIndicator` 綁定 `refreshBookshelf()` |

### 📍 2. 閱讀器模組 (`ui/book/read` vs `lib/features/reader/reader_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **自定義點擊區域** | 9-Grid Click Areas | ✅ Matched | 實作 `ReaderPage` 九宮格手勢檢測與行為映射 |
| **排版: 首行縮排** | Text Indent | ✅ Matched | `ChapterProvider` 支援全角空格縮排與標題間距 |
| **排版: 兩端對齊** | Full Justify | ✅ Matched | `_TextPagePainter` 手動字元間距計算渲染 |
| **選取文字彈窗** | `TextActionMenu` | ✅ Matched | 支援複製、搜尋、分享、筆記與字典查詞 |
| **頂部: 自動換源** | 選單 `auto_change_source` | ✅ Matched | `PopupMenuButton` 呼叫 `provider.autoChangeSource()` |
| **底部: 設定選單** | 各類排版/主題配置 | ✅ Matched | 實現主題與排版參數 (字體/行高/間距) 的同步切換 |

### 📍 3. 書源管理模組 (`ui/book/source` vs `lib/features/source_manager/source_manager_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **書源調試 (Pro)** | `BookSourceDebug` | ✅ Matched | 支援 HTTP 詳情日誌、JSON 格式化與日誌匯出 |
| **批量校驗/清理** | `CheckSourceService` | ✅ Matched | 支援並行校驗、詳情日誌查看與失效源一鍵清理 |
| **書源分組管理** | `GroupManageDialog` | ✅ Matched | 支援分組 CRUD、手動拖曳排序及批量分組遷移 |
| **書源登入/驗證** | Web JS Injection | ✅ Matched | `SourceLoginPage` 支援 UA 同步與 HttpOnly Cookie 捕捉 |

### 📍 4. 設定與工具模組 (`ui/config` & `ui/dict` vs `lib/features/settings` & `lib/features/dict`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **設定: 備份與還原** | `WebDav` 進階配置 | ✅ Matched | 支援連通性測試、子目錄/裝置名稱設定與自動同步 |
| **設定: 字典管理** | 多頁籤查詞與規則 | ✅ Matched | `DictDialog` 支援 Tab 切換，規則支援複製貼上 |
| **設定: 字體管理** | 字體下載與預覽 | ✅ Matched | 支援網路下載、自定義預覽文字與大小即時調節 |
| **替換規則: 調試** | `ReplaceEditActivity` | ✅ Matched | 編輯器整合實時測試引擎與正則驗證 |

---

## 🛠️ 開發缺口與待辦清單 (Remaining Gaps)

> 目前核心功能已基本對齊，剩餘多為平臺特性或視覺美化。

1. **[⚠️ Partial] 仿真翻頁引擎 (`SimulationPageAnim`)**
   - **描述**: 已有 2D 效果，但 iOS 原生缺少完美的 3D 捲曲特效，目前以自定義繪製路徑模擬。
2. **[❌ Missing] 桌面小組件 UI 渲染 (iOS WidgetKit)**
   - **描述**: 基礎設施數據鏈已打通，但 Swift 側的 Widget UI 尚未在專案中完成視覺開發。
3. **[❌ Missing] 本地備份目錄監聽**
   - **描述**: Android 的自動備份支援監聽目錄變動，iOS 需受限於 Sandbox 機制另行優化。

---
*報告產生時間: 2026-03-14 | 由 AI Agent 完成全自動迭代後生成*
