# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | 85% | ✅ | 基本翻頁、UI 切換一致；搜尋與自動閱讀彈窗有細微缺失 |
| **02** | **書架/主頁面** | 90% | ✅ | 佈局切換、分組與批量管理一致；自動備份同步邏輯有細微缺口 |
| **03** | **書源管理** | 92% | ✅ | 書源列表、編輯、匯入匯出一致；偵錯控制台與進階分組邏輯（如按域名分組）有細微缺失 |
| **04** | **核心引擎** | 0% | ⏳ | 待分析 |
<!-- END_DASHBOARD -->

---

<!-- BEGIN_AUDIT_01 -->
## 01. 閱讀主界面

**模組職責**：提供書籍內容展示、翻頁互動、選單導航及閱讀偏好設定。
**Legado 檔案**：`ReadBookActivity.kt`, `ReadBookViewModel.kt`, `ChapterProvider.kt`, `ReadMenu.kt`
**Flutter (iOS) 對應檔案**：`reader_page.dart`, `reader_provider.dart`, `chapter_provider.dart`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **點擊區域自定義**：iOS 已實現九宮格點擊映射 (`_executeAction`)，對標 Android `onTouch`。
- ✅ **翻頁模式**：支持仿真 (`SimulationPageView`)、覆蓋、水平與垂直滑動。
- ✅ **沉浸式 UI**：實現了自動隱藏系統狀態欄與導航欄的功能。
- ✅ **章節導航**：透過側邊欄（Drawer）實現了章節跳轉與搜尋功能。

**不足之處**：
- [ ] **全局搜尋缺失**：iOS 端的搜尋目前僅限於已下載/快取的章節，而 Android 支援對全書源內容進行搜尋。
- [ ] **自動閱讀細節**：iOS 雖然有自動翻頁開關，但缺乏 Android 的 `AutoReadDialog`（調節速度、模式等細節）。
- [ ] **亮度/字體微調**：iOS 的調整範圍較 Android 簡化（例如 Android 支持字體權重轉換器）。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **01.1 點擊互動** | `ReadBookActivity.kt`: 220 (`onTouch`) | `reader_page.dart`: 104 (`GestureDetector`) | **Equivalent** | 實作方式不同但語義對等 |
| **01.2 章節切換** | `ReadBookActivity.kt`: 137 (`openChapter`) | `reader_page.dart`: 85 (`_executeAction`) | **Matched** | 呼叫 Provider/VM 跳轉邏輯一致 |
| **01.3 仿真翻頁** | `ReadBookActivity.kt`: 196 (`SimulationPageDelegate`) | `reader_page.dart`: 145 (`SimulationPageView`) | **Matched** | 仿真效果對等實現 |
| **01.4 內容搜尋** | `ReadBookActivity.kt`: 164 (`searchContentActivity`) | `reader_page.dart`: 237 (`_doSearch`) | **Logic Gap** | iOS 搜尋範圍受限於快取 |
| **01.5 系統 UI** | `ReadBookActivity.kt`: 250 (`upSystemUiVisibility`) | `reader_page.dart`: 50 (`_updateSystemUI`) | **Matched** | 隱藏/顯示邏輯一致 |
<!-- END_AUDIT_01 -->

<!-- BEGIN_AUDIT_02 -->
## 02. 書架/主頁面

**模組職責**：展示已加入的書籍列表，支持分組、排序、搜尋及批量管理。
**Legado 檔案**：`MainActivity.kt`, `MainViewModel.kt`, `BookshelfManageActivity.kt`, `BaseBookshelfFragment.kt`
**Flutter (iOS) 對應檔案**：`bookshelf_page.dart`, `bookshelf_provider.dart`, `group_manage_page.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **分組導航**：實現了基於 TabBar 的書籍分組切換。
- ✅ **佈局切換**：完美對標 Android 的網格 (Grid) 與列表 (List) 雙佈局切換。
- ✅ **批量管理**：實現了比 Android 更高效的拖拽多選與批量刪除/移動功能。
- ✅ **未讀標記**：支持顯示書籍更新章節數量的徽章提示。

**不足之處**：
- [ ] **自動 WebDav 同步**：Android 在 `MainActivity` 啟動時會自動比對 WebDav 備份日期並提示恢復，iOS 目前僅能手動導出/匯入。
- [ ] **多樣化書架樣式**：Android 提供多種書架樣式（Style1/Style2），iOS 目前固定為單一風格。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **02.1 書籍分組** | `MainActivity.kt`: 102 (`menu_bookshelf`) | `bookshelf_page.dart`: 80 (`TabBar`) | **Equivalent** | 導航層級不同但功能對等 |
| **02.2 佈局切換** | `AppConfig.bookshelfLayout` | `bookshelf_page.dart`: 160 (`toggleLayout`) | **Matched** | 網格/列表切換邏輯一致 |
| **02.3 批量選擇** | `BookshelfManageActivity.kt` | `bookshelf_page.dart`: 30 (`_handleDragUpdate`) | **Matched** | 批量操作邏輯一致 |
| **02.4 自動刷新** | `MainActivity.kt`: 138 (`upAllBookToc`) | `bookshelf_provider.dart`: 110 (`refreshBookshelf`) | **Matched** | 啟動更新邏輯一致 |
| **02.5 數據同步** | `MainActivity.kt`: 220 (`backupSync`) | ❌ 暫無自動觸發邏輯 | **Logic Gap** | 缺少自動 WebDav 恢復提示 |
<!-- END_AUDIT_02 -->

<!-- BEGIN_AUDIT_03 -->
## 03. 書源管理

**模組職責**：維護書籍來源的獲取規則，支持書源的匯入、編輯、分組與校驗。
**Legado 檔案**：`BookSourceActivity.kt`, `BookSourceViewModel.kt`, `BookSourceEditActivity.kt`, `BookSourceDebugActivity.kt`
**Flutter (iOS) 對應檔案**：`source_manager_page.dart`, `source_manager_provider.dart`, `source_editor_page.dart`, `debug_page.dart`
**完成度：92%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **多維度匯入**：支持網路連結、剪貼簿、QR Code 及本地 JSON 匯入，對標 Android `ImportBookSourceDialog`。
- ✅ **規則編輯器**：提供了表單化與純 JSON 雙模式編輯，覆蓋了搜尋、發現、詳情、目錄、正文五大規則塊。
- ✅ **批量管理**：實現了批量選取後的刪除、啟用、禁用及批量校驗功能。
- ✅ **分組過濾**：支持按分組標籤快速篩選書源。

**不足之處**：
- [ ] **域名分組缺失**：Android 支持 `groupSourcesByDomain`（按域名自動歸類），iOS 目前僅支持手動定義的分組。
- [ ] **偵錯細節**：Android 的 `BookSourceDebugActivity` 支持直接輸入特定書籍 URL 進行深度調試，iOS 目前僅支持基礎的日誌流展示。
- [ ] **間隔校驗**：iOS 缺乏 Android 的 `checkSelectedInterval`（按間隔時間校驗）功能，僅支持全量並發校驗。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **03.1 匯入邏輯** | `BookSourceActivity.kt`: 475 (`showImportDialog`) | `source_manager_page.dart`: 355 (`_showImportDialog`) | **Matched** | 多源匯入邏輯完整對齊 |
| **03.2 批量操作** | `BookSourceActivity.kt`: 360 (`onMenuItemClick`) | `source_manager_provider.dart`: 115 (`deleteSelected`) | **Matched** | 批量選取與刪除語義一致 |
| **03.3 規則編輯** | `BookSourceEditActivity.kt`: 220 (`upSourceView`) | `source_editor_page.dart`: 120 (`_buildFormTab`) | **Matched** | 規則字段定義完全一致 |
| **03.4 偵錯日誌** | `BookSourceDebugActivity.kt`: 44 (`viewModel.observe`) | `debug_page.dart`: 28 (`_initLogs`) | **Equivalent** | 實現方式不同但日誌展示語義一致 |
| **03.5 書源校驗** | `BookSourceActivity.kt`: 390 (`checkSource`) | `source_manager_provider.dart`: 150 (`checkSelectedSources`) | **Matched** | 校驗觸發流程一致 |
<!-- END_AUDIT_03 -->

<!-- BEGIN_AUDIT_04 -->
## 04. 核心引擎

**模組職責**：處理各類書籍格式解析（EPUB/UMD/TXT）及基於規則與 JS 的內容提取。
**Legado 檔案**：`EpubReader.java`, `RhinoScriptEngine.kt`, `AnalyzeRule.kt`, `JsExtensions.kt`
**Flutter (iOS) 對應檔案**：`epub_parser.dart`, `js_engine.dart`, `analyze_rule.dart`, `js_extensions.dart`
**完成度：88%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **規則解析體系**：iOS 完美對標了 Android 的多模式解析（XPath, CSS, JsonPath, Regex），且支持同樣的 `##` 正則替換語法。
- ✅ **動態參數處理**：實現了與 Android 一致的 `@get`, `@put`, `{{js}}` 宏替換邏輯。
- ✅ **JS 運行環境**：通過 `flutter_js` 提供了獨立的 JS 執行上下文，並注入了 `java` (this), `source`, `book` 等關鍵對象。
- ✅ **EPUB 解析**：支持目錄提取、元數據讀取及 HTML 內容流加載。

**不足之處**：
- [ ] **UMD 格式缺失**：Android 擁有獨立的 `UmdReader` 模組，iOS 端目前尚未實現對 UMD 格式的支持。
- [ ] **JS 引擎差異**：Android 使用 Mozilla Rhino，支持一些特定的 Java 互操作特性；iOS 基於系統原生 JS 引擎，部分極端複雜的 Legacy JS 書源可能存在兼容性微差。
- [ ] **預加載策略**：Android 的 `EpubReader` 支持更細粒度的 Lazy Loading 配置，iOS 的 `epubx` 封裝相對較厚。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **04.1 規則分發** | `AnalyzeRule.kt`: 152 (`getString`) | `analyze_rule.dart`: 137 (`getString`) | **Matched** | 多模式切換邏輯完全一致 |
| **04.2 宏替換** | `AnalyzeRule.kt`: 574 (`SourceRule` init) | `analyze_rule.dart`: 333 (`SourceRule` init) | **Matched** | `@get/@put/{{}}` 語法解析對齊 |
| **04.3 正則替換** | `AnalyzeRule.kt`: 374 (`replaceRegex`) | `analyze_rule.dart`: 283 (`_replaceRegex`) | **Matched** | `##` 分隔符與分組捕獲邏輯一致 |
| **04.4 JS 上下文** | `RhinoScriptEngine.kt`: 183 (`getRuntimeScope`) | `js_engine.dart`: 35 (`evaluate`) | **Equivalent** | 對象注入與執行流程語義一致 |
| **04.5 EPUB 加載** | `EpubReader.java`: 60 (`readEpub`) | `epub_parser.dart`: 14 (`load`) | **Equivalent** | 核心解析功能對等 |
<!-- END_AUDIT_04 -->
