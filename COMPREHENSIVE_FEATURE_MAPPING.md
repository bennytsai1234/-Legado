# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping) v3
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。
**本次審核為「UI 元件與程式碼驅動 (Code-Driven)」的深度優化版，精確到每一個按鈕的功能實作情況。**

---

## 📊 開發進度與狀態總覽 (Implementation Status)

| 核心模組 | 開發完成度 | 狀態評估 |
| :--- | :--- | :--- |
| **書架 (Bookshelf)** | 🟢 90% | 核心書架、分組、排序、匯入、備份功能已完成，UI 按鈕全數實作。 |
| **發現 (Explore)** | 🟢 90% | 分源瀏覽、分類篩選已實作。 |
| **閱讀器 (Reader)** | 🟡 85% | 核心渲染、翻頁、字體管理、字典查詞已實作。仿真翻頁等進階功能部分完成。 |
| **書源管理 (Source Manager)** | 🟢 90% | 增刪改查、群組過濾、二維碼/URL/本地檔案匯入均已實作。 |
| **訂閱 (RSS)** | 🟡 80% | 來源解析、文章列表、標記與閱讀已完成，部分 Web 交互需強化。 |
| **設定 (Settings)** | 🟡 75% | WebDAV 同步備份完善，字體/字典/佈景主題設定實作，但部分進階排版選單仍待細化。 |

---

## 📂 模組對位與 UI 按鈕審查清單

以下清單對照 `C:\Users\benny\Desktop\Folder\Project\reader\legado` 中的 `ui` 目錄。

### 📍 1. 書架模組 (`ui/main/bookshelf` vs `lib/features/bookshelf/bookshelf_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **搜尋按鈕** | `BookshelfFragment.kt` | ✅ Matched | `onPressed: () => Navigator.push(...)` 至 `SearchPage` |
| **匯入書架/本機書籍** | 菜單 `import` / SAF 檔案選擇 | ✅ Matched | 支援檔案選擇與 URL 匯入 (`FilePickerPage`) |
| **切換列表/網格視圖** | `BookshelfAdapter` 動態切換 | ✅ Matched | 實作於 AppBar action，變更 Provider 狀態 |
| **管理分組** | `GroupManageActivity` | ✅ Matched | `Navigator.push(...)` 至 `GroupManagePage` |
| **書籍長按選單** | Context Menu 彈窗 | ✅ Matched | `onLongPress` 觸發多選模式，支援刪除、移動分組 |
| **下拉刷新/更新** | `SwipeRefreshLayout` | ✅ Matched | `RefreshIndicator` 綁定 `refreshBookshelf()` |

### 📍 2. 閱讀器模組 (`ui/book/read` vs `lib/features/reader/reader_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **單擊中央喚出選單** | `ReadBookActivity` 觸控區域 | ✅ Matched | `GestureDetector(onTapUp: ... toggleControls())` |
| **左右點擊翻頁** | `PageView` 翻頁邏輯 | ✅ Matched | 手勢識別點擊邊緣呼叫 `nextPage()` / `prevPage()` |
| **選取文字彈窗: 查詞** | `DictDialog` 觸發 | ✅ Matched | `ContextMenuButtonItem(label: '查詞')` 呼叫 `DictDialog.show` |
| **選取文字彈窗: 筆記** | 標記 Bookmark | ✅ Matched | `_showAnnotationDialog` 與 `BookmarkDao` 整合 |
| **頂部: 自動換源** | 選單 `auto_change_source` | ✅ Matched | `PopupMenuButton` 呼叫 `provider.autoChangeSource()` |
| **底部: 上/下一章** | Chapter 切換 | ✅ Matched | `TextButton` 綁定 `prevChapter` / `nextChapter` |
| **底部: 目錄** | `TocFragment` | ✅ Matched | 抽屜式目錄 (Drawer)，使用 `ListView.builder` 渲染章節 |
| **設定: 字體大小增減** | `FontSelectDialog` | ✅ Matched | `IconButton` 綁定 `setFontSize(+/- 1)` |
| **設定: 閱讀字體** | 字體切換 | ✅ Matched | 串接 `FontManagerPage` 支援動態 TTF/OTF 載入 |
| **設定: 翻頁方式** | Simulation/Scroll/Cover | ✅ Matched | `ChoiceChip` 設定 `pageTurnMode (水平/覆蓋/垂直)` |
| **設定: 簡繁轉換** | `ChineseUtils` | ✅ Matched | `ChoiceChip` 綁定 `setChineseConvert` (0:無, 1:轉簡, 2:轉繁) |
| **設定: 佈景主題** | 顏色陣列切換 | ✅ Matched | `GestureDetector` 變更 `themeIndex` |

### 📍 3. 書源管理模組 (`ui/book/source` vs `lib/features/source_manager/source_manager_page.dart`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **新增書源 FAB** | `SourceEditActivity` 啟動 | ✅ Matched | FloatingActionButton 跳轉 `SourceEditorPage` |
| **匯入方式選單** | QR, 剪貼簿, 本地檔案, 網路 | ✅ Matched | AppBar `PopupMenuButton` 提供四種匯入管道 |
| **啟用/停用開關** | `Switch` 切換 `enabled` | ✅ Matched | `Switch` 綁定 `provider.toggleSource(source)` |
| **滑動刪除** | `ItemTouchHelper` | ✅ Matched | `Dismissible` 元件實作 |
| **書源群組篩選** | 分組 Chips 滾動列 | ✅ Matched | 橫向 ListView 渲染 group tags 進行過濾 |
| **長按進入編輯** | 列表點擊事件 | ✅ Matched | `ListTile(onLongPress)` 跳轉編輯頁面 |
| **書源登入/驗證** | Web JS Injection | ⚠️ Partial | 具備基礎 Web 登入按鈕，複雜 JS 校驗需 `ui/browser` 補強 |

### 📍 4. 設定與工具模組 (`ui/config` & `ui/dict` vs `lib/features/settings` & `lib/features/dict`)

| UI 元件 / 按鈕功能 | Android 原始邏輯 | iOS 實作狀態 | 程式碼佐證 / 備註 |
|:---|:---|:---|:---|
| **設定: 備份與還原** | `WebDav` & Local ZIP | ✅ Matched | `ListTile` 綁定 `BackupSettingsPage`，實作全量 DAO 打包 |
| **設定: 字典管理** | `ui/dict/rule` | ✅ Matched | `DictRulePage` 提供字典規則 CRUD (`dictRule.json`) |
| **設定: 語音朗讀** | `HttpTTS` & 本地 TTS | ✅ Matched | `AloudSettingsPage` 整合 `flutter_tts` 與 HTTP 引擎 |
| **設定: 替換規則** | `ui/replace` | ✅ Matched | `ReplaceRulePage` 支援正則與全域變數替換 |
| **關於頁面: 崩潰日誌** | `CrashHandler` 寫檔 | ✅ Matched | `CrashLogPage` 讀取並顯示持久化錯誤紀錄 |
| **關於頁面: 檢查更新** | GitHub Release API | ✅ Matched | `AppUpdateService().checkUpdate()` 與彈窗下載 |

---

## 🛠️ 開發缺口與待辦清單 (Remaining Gaps)

> 以下功能在 Android 版中存在，但在 iOS 端尚未實作或實作不完全，將作為下階段的優化目標。

1. **[✅ Matched] 內置網頁瀏覽器 (`ui/browser`)**
   - **描述**: 實作了 `BrowserPage` 與 `BrowserProvider`，支援書源登入、JS 注入、Cookie 同步與 Cloudflare 挑戰偵測。
   - **iOS 對策**: 已整合 `webview_flutter` 並與 `SourceVerificationService` 聯動。
2. **[⚠️ Partial] 閱讀器：文字長按的進階選單**
   - **描述**: 雖然已實作「查詞」與「筆記」，但 Android 支援更豐富的操作（如：複製、搜尋、分享）。
3. **[❌ Missing] 替換規則：調試功能**
   - **描述**: Android 的 `ReplaceRuleEditActivity` 支援針對單一文字段落即時測試正規表達式是否生效。
4. **[⚠️ Partial] 仿真翻頁引擎 (`SimulationPageAnim`)**
   - **描述**: 雖然有 `pageTurnMode == 3` (仿真翻頁) 的入口，但 Flutter 原生缺少完美的 3D 捲曲特效，目前暫以 `PageMetrics` 模擬過渡。

---
*報告產生時間: 2026-03-14 | 由 AI Agent 執行程式碼掃描生成*