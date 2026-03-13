# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | 95% | ✅ | 基本翻頁、UI 切換一致；全局內容搜尋與自動閱讀彈窗已實現 |
| **02** | **書架/主頁面** | 95% | ✅ | 佈局切換、分組與批量管理一致；WebDav 自動同步已完整對齊 |
| **03** | **書源管理** | 100% | ✅ | 書源列表、編輯、匯入匯出一致；域名分組、偵錯細節、間隔校驗已完全對齊 |
| **04** | **核心引擎** | 95% | ✅ | 多模式規則解析、JS 引擎對齊；已實現 UMD 格式解析 |
| **05** | **數據持久化** | 95% | ✅ | 數據模型、響應式監聽、位運算分組對齊；事務控制微小差異 |
| **06** | **RSS 閱覽** | 90% | ✅ | 規則解析、文章列表、收藏夾邏輯一致 |
| **07** | **背景服務** | 95% | ✅ | TTS 朗讀、HTTP TTS、本地 Web 服務對齊 |
| **08** | **系統助手/備份** | 95% | ✅ | WebDav 同步、JS 工具類對齊；統一恢復機制已完善 |
| **09** | **替換規則** | 95% | ✅ | 正則替換、範圍控制與分組管理完全對齊 |
| **10** | **通用配置** | 92% | ✅ | 主題、備份、朗讀設定一致；字體權重微調功能缺失 |
| **11** | **底層基類** | 95% | ✅ | ViewModel/Provider 基類對齊；已實現統一 UI 狀態 BaseScaffold |
| **12** | **常量與異常** | 95% | ✅ | 全局鍵值、正則模式對齊；特定 Java 異常類型簡化 |
| **13** | **工具函數庫** | 90% | ✅ | 編碼檢測、加密、文件工具一致；依賴部分原生插件 |
| **14** | **廣播與關聯** | 95% | ✅ | 媒體控制、分享接收、網路監聽邏輯高度對齊 |
| **15** | **自定義 UI 元件** | 90% | ✅ | 核心組件（電池、封面）對齊；已實現基礎字母快速滾動條 |
<!-- END_DASHBOARD -->

---

<!-- BEGIN_AUDIT_01 -->
## 01. 閱讀主界面

**模組職責**：提供核心閱讀體驗，包括文字渲染、翻頁動畫、菜單交互及內容搜尋。
**Legado 檔案**：`ReadBookActivity.kt`, `ReadBookViewModel.kt`, `SimulationPageDelegate.kt`, `SearchMenu.kt`, `PageView.kt`, `AutoReadDialog.kt`
**Flutter (iOS) 對應檔案**：`reader_page.dart`, `reader_provider.dart`, `simulation_page_view.dart`, `search_page.dart`, `page_view_widget.dart`, `auto_read_dialog.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **核心渲染**：實現了基於 Flutter Canvas 的高性能文本分頁與渲染。
- ✅ **仿真翻頁**：完美對標 Android 的 `SimulationPageDelegate` 動畫效果。
- ✅ **全局內容搜尋**：實現了跨章節的關鍵字搜尋、跳轉定位與規則處理（對標 Android `searchChapter`）。
- ✅ **章節導航**：支持目錄跳轉、進度條拖拽與前後章切換。
- ✅ **自動閱讀**：實現了與 Android 一致的 `AutoReadDialog`，支持精細化速度調節與快捷操作。

**不足之處**：
- [ ] **亮度/字體微調**：iOS 的調整範圍較 Android 簡化（例如 Android 支持字體權重轉換器）。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **01.1 UI 進入點** | `ReadBookActivity.kt`: 150 (`onCreate`) | `reader_page.dart`: 45 (`build`) | **Matched** | 生命週期與 UI 初始化一致 |
| **01.2 業務邏輯** | `ReadBookViewModel.kt`: 80 (`loadContent`) | `reader_provider.dart`: 120 (`loadChapter`) | **Matched** | 內容加載與分頁邏輯一致 |
| **01.3 翻頁動畫** | `SimulationPageDelegate.kt` | `simulation_page_view.dart` | **Matched** | 貝塞爾曲線翻頁算法完全對齊 |
| **01.4 內容搜尋** | `SearchContentViewModel.kt` | `reader_provider.dart`: 430 (`searchContent`) | **Matched** | 已支持在線搜尋、多匹配項與規則處理 |
| **01.5 頁面管理** | `PageView.kt` | `page_view_widget.dart` | **Matched** | 多手勢交互與層級管理一致 |
| **01.6 自動閱讀** | `AutoReadDialog.kt` | `auto_read_dialog.dart` | **Matched** | 速度控制與選單導航邏輯一致 |
<!-- END_AUDIT_01 -->

<!-- BEGIN_AUDIT_02 -->
## 02. 書架/主頁面

**模組職責**：管理書籍列表、分組導航及書籍元數據同步。
**Legado 檔案**：`MainActivity.kt`, `MainViewModel.kt`, `GroupManageDialog.kt`, `BookshelfManageActivity.kt`
**Flutter (iOS) 對應檔案**：`bookshelf_page.dart`, `bookshelf_provider.dart`, `group_manage_page.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **分組管理**：實現了與 Android 一致的位運算書籍分組邏輯。
- ✅ **批量操作**：支持書籍的批量移動、刪除及緩存下載管理。
- ✅ **佈局切換**：完美對標列表、網格等多種書架展示模式。
- ✅ **自動 WebDav 同步**：實現了與 Android 一致的背景自動備份與同步機制。

**不足之處**：
- [ ] **性能微調**：超大規模書架（1000+ 本書）下的滾動流暢度仍有優化空間。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **02.1 書籍加載** | `MainViewModel.kt`: 40 (`refreshBookshelf`) | `bookshelf_provider.dart`: 35 (`loadBooks`) | **Matched** | 資料庫讀取與狀態管理一致 |
| **02.2 分組過濾** | `GroupManageDialog.kt` | `group_manage_page.dart` | **Matched** | 分組選擇與過濾邏輯一致 |
| **02.3 批量編輯** | `BookshelfManageActivity.kt` | `bookshelf_page.dart` (編輯模式) | **Equivalent** | 功能完全對等 |
| **02.4 排序邏輯** | `BookDao.kt`: 15 (`ORDER_BY_LAST_READ`) | `book_dao.dart`: 22 (`sortByLastRead`) | **Matched** | 排序字段與語義一致 |
| **02.5 數據同步** | `MainActivity.kt` | `main.dart:321 (_checkBackupSync)` | **Matched** | 自動 WebDav 同步邏輯已對齊 |
<!-- END_AUDIT_02 -->

<!-- BEGIN_AUDIT_03 -->
## 03. 書源管理

**模組職責**：負責書源的 CRUD、導入、導出、分組及調試控制台。
**Legado 檔案**：`BookSourceActivity.kt`, `BookSourceViewModel.kt`, `BookSourceEditActivity.kt`, `BookSourceDebugActivity.kt`
**Flutter (iOS) 對應檔案**：`source_manager_page.dart`, `source_manager_provider.dart`, `source_editor_page.dart`, `debug_page.dart`
**完成度：100%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **多維匯入**：支持 URL、本地文件、剪貼簿及 QR 碼匯入書源。
- ✅ **視覺編輯器**：實現了帶語法提示的書源規則編輯界面。
- ✅ **書源調試**：對標了 Android 的調試控制台，可實時查看解析過程。
- ✅ **域名分組**：支持按域名自動歸類書源，對標 Android 的高級分組邏輯。
- ✅ **偵錯細節**：完整實現了規則解析的每一步日誌輸出，支持交互式偵錯。
- ✅ **間隔校驗**：實現了自動校驗的區間選擇與頻率控制。

**不足之處**：
- 無（已完全對標核心功能）

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **03.1 書源匯入** | `BookSourceViewModel.kt`: 200 (`importSource`) | `source_manager_provider.dart`: 150 (`import`) | **Matched** | JSON 解析與重複項處理一致 |
| **03.2 規則編輯** | `BookSourceEditActivity.kt` | `source_editor_page.dart` | **Matched** | 字段映射與預覽功能一致 |
| **03.3 調試日誌** | `BookSourceDebugActivity.kt` | `debug_page.dart` | **Equivalent** | 實時日誌流輸出邏輯一致 |
| **03.4 源校驗** | `BookSourceViewModel.kt`: 310 (`checkSource`) | `check_source_service.dart` | **Matched** | 網絡連通性與響應校驗一致 |
| **03.5 排序權重** | `BookSource.kt`: 45 (`customOrder`) | `book_source.dart`: 30 (`customOrder`) | **Matched** | 排序字段定義一致 |
| **03.6 域名分組** | `BookSourceActivity.kt` | `SourceManagerProvider.toggleGroupByDomain` | **Matched** | 域名聚合邏輯與 Android 一致 |
| **03.7 互動偵錯** | `BookSourceDebugActivity.kt` | `DebugPage` & `SourceEditorPage._showDebugConsole` | **Matched** | 偵錯控制台交互與日誌層級一致 |
| **03.8 區間選擇** | `BookSourceViewModel.kt` | `SourceManagerProvider.selectInterval` | **Matched** | 校驗頻率與區間選擇邏輯一致 |
<!-- END_AUDIT_03 -->

<!-- BEGIN_AUDIT_04 -->
## 04. 核心引擎

**模組職責**：執行書源規則，包括網路請求、CSS/JSONPath 提取及 JS 沙盒環境。
**Legado 檔案**：`AnalyzRule.kt`, `RhinoScriptEngine.kt`, `JsAdapter.kt`, `EpubReader.java`
**Flutter (iOS) 對應檔案**：`analyze_rule.dart`, `js_engine.dart`, `js_extensions.dart`, `epub_parser.dart`, `umd_parser.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **混合解析**：支持 CSS、JSONPath、XPath 及 Regex 的鏈式調用。
- ✅ **JS 運行環境**：通過 `flutter_js` 實現了與 Rhino 語義對等的沙盒。
- ✅ **EPUB 支持**：實現了流式 EPUB 解析與資源提取。
- ✅ **UMD 格式解析**：實現了對 UMD 格式電子書的解析與支持。

**不足之處**：
- [ ] **性能優化**：複雜書源規則下的解析效率仍有提升空間。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **04.1 規則引擎** | `AnalyzRule.kt`: 55 (`eval`) | `analyze_rule.dart`: 40 (`evaluate`) | **Matched** | 遞迴解析邏輯一致 |
| **04.2 JS 橋接** | `JsAdapter.kt` | `js_extensions.dart` | **Equivalent** | 注入對象與 API 對標一致 |
| **04.3 網路請求** | `OkHttpUtils.kt` | `http_client.dart` | **Matched** | Cookie 與 User-Agent 處理一致 |
| **04.4 內容清洗** | `ContentProcessor.kt` | `content_processor.dart` | **Matched** | 正則清洗與特殊字符處理一致 |
| **04.5 解碼算法** | `EncodingDetect.kt` | `encoding_detect.dart` | **Matched** | 字節流編碼自動識別一致 |
| **04.6 UMD 解析** | `UmdParser.java` | `UmdParser.parse` | **Matched** | UMD 格式解析支持已實現 |
<!-- END_AUDIT_04 -->

<!-- BEGIN_AUDIT_05 -->
## 05. 數據持久化

**模組職責**：提供書籍、章節、書源及配置的本地存儲與事務管理。
**Legado 檔案**：`AppDatabase.kt`, `BookDao.kt`, `BookSourceDao.kt`, `Book.kt`
**Flutter (iOS) 對應檔案**：`app_database.dart`, `book_dao.dart`, `book_source_dao.dart`, `book.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **響應式監聽**：實現了基於 Stream 的資料庫變更實時推送。
- ✅ **數據遷移**：實現了與 Android 結構完全一致的資料庫遷移方案。
- ✅ **位運算分組**：完美繼承了 Android 的位元組過濾與權重邏輯。

**不足之處**：
- [ ] **多表聯查**：部分複雜的 SQL 關聯查詢在 iOS 端目前採用了分次查詢後內存合併的簡化方案。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **05.1 模型定義** | `Book.kt` | `book.dart` | **Matched** | 字段名稱與類型完全對應 |
| **05.2 資料庫遷移** | `DatabaseMigrations.kt` | `app_database.dart` | **Matched** | 版本升級路徑與 SQL 語句一致 |
| **05.3 數據流更新** | `BookDao.kt`: 22 (`flowByGroup`) | `book_dao.dart`: 18 (`watchBookshelf`) | **Matched** | 響應式更新機制對等 |
| **05.4 進度保存** | `BookDao.kt`: 173 (`upProgress`) | `book_dao.dart`: 137 (`updateProgress`) | **Matched** | 進度與時間戳邏輯一致 |
| **05.5 批處理** | `BookSourceDao.kt`: 228 (`delete`) | `book_source_dao.dart`: 88 (`deleteSources`) | **Matched** | 批量操作語義一致 |
<!-- END_AUDIT_05 -->

<!-- BEGIN_AUDIT_06 -->
## 06. RSS 閱覽

**模組職責**：支持基於規則的 RSS 源獲取、文章解析呈現與收藏管理。
**Legado 檔案**：`RssSourceActivity.kt`, `RssArticlesFragment.kt`, `ReadRssActivity.kt`, `RssParserByRule.kt`
**Flutter (iOS) 對應檔案**：`rss_source_page.dart`, `rss_article_page.dart`, `rss_parser.dart`, `rss_star_provider.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **規則解析**：實現了對 Android RSS 規則的完全相容解析（XPath/CSS/Regex）。
- ✅ **列表分頁**：支持加載更多文章與下拉刷新。
- ✅ **文章收藏**：實現了與數據庫關聯的 RSS 收藏夾。

**不足之處**：
- [ ] **RSS 偵測**：Android 支持對 RSS 源進行即時偵錯輸出， iOS 尚未實現此開發者介面。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **06.1 規則解析** | `RssParserByRule.kt`: 45 (`parse`) | `rss_parser.dart`: 28 (`parseRss`) | **Matched** | 規則字段與解析邏輯一致 |
| **06.2 文章收藏** | `RssStarDao.kt` | `rss_star_provider.dart`: 15 (`toggleStar`) | **Matched** | 數據存儲與交互流程一致 |
| **06.3 文章閱讀** | `ReadRssActivity.kt` | `rss_read_page.dart` | **Matched** | 內置 WebView 渲染與規則提取內容一致 |
| **06.4 來源管理** | `RssSourceActivity.kt` | `rss_source_page.dart` | **Matched** | 來源啟用/禁用邏輯一致 |
| **06.5 分組過濾** | `GroupManageDialog.kt` | `rss_source_provider.dart`: 60 (`filterByGroup`) | **Matched** | 分組管理語義一致 |
<!-- END_AUDIT_06 -->

<!-- BEGIN_AUDIT_07 -->
## 07. 背景服務

**模組職責**：提供朗讀 (TTS)、書籍下載及本地 Web 控制台等後台常駐功能。
**Legado 檔案**：`TTSReadAloudService.kt`, `DownloadService.kt`, `WebService.kt`, `AudioPlayService.kt`
**Flutter (iOS) 對應檔案**：`tts_service.dart`, `download_service.dart`, `web_service.dart`, `audio_play_service.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **朗讀引擎**：支持系統原生 TTS 與第三方 HTTP TTS 接口（如 Edge-TTS）。
- ✅ **異步下載**：實現了基於線程池的多章節並發下載與錯誤重試邏輯。
- ✅ **Web 交互**：對標 Android 實現了本地 HTTP Server，支持 Web 端管理書源。

**不足之處**：
- [ ] **下載通知細節**：Android 支持更細緻的系統通知欄進度展示與控制，iOS 受系統限制較為簡化。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **07.1 系統 TTS** | `TTSReadAloudService.kt`: 120 (`speak`) | `tts_service.dart`: 45 (`speak`) | **Matched** | 核心朗讀 API 對齊 |
| **07.2 下下載並發** | `DownloadService.kt`: 80 (`startDownload`) | `download_service.dart`: 65 (`_worker`) | **Matched** | 並發控制與任務隊列一致 |
| **07.3 Web 端口** | `WebService.kt`: 35 (`startServer`) | `web_service.dart`: 22 (`start`) | **Matched** | 內置 Server 端口與靜態路由一致 |
| **07.4 音頻焦點** | `AudioPlayService.kt`: 155 (`onFocusChange`) | `audio_play_service.dart`: 110 (`_handleFocus`) | **Equivalent** | 系統音頻策略語義對等 |
| **07.5 朗讀定時** | `BaseReadAloudService.kt`: 210 (`stopTimer`) | `tts_service.dart`: 130 (`stopAfter`) | **Matched** | 定時關閉功能一致 |
<!-- END_AUDIT_07 -->

<!-- BEGIN_AUDIT_08 -->
## 08. 系統助手/備份

**模組職責**：管理全局數據備份恢復、WebDav 同步、加密工具及內容處理插件。
**Legado 檔案**：`Backup.kt`, `Restore.kt`, `AppWebDav.kt`, `JsExtensions.kt`, `ContentProcessor.kt`
**Flutter (iOS) 對應檔案**：`webdav_service.dart`, `backup_aes_service.dart`, `js_extensions.dart`, `content_processor.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **WebDav 同步**：完整對標了 Android 的自動備份與遠端文件列表管理。
- ✅ **內容預處理**：實現了與 Android 一致的內容去廣告、正則清洗與排版優化。
- ✅ **JS 擴展工具**：提供了與 Android 完全相容的加密 (`md5`, `aes`, `base64`) 工具類。
- ✅ **統一恢復機制**：實現了基於 `RestoreService` 的統一恢復調度，支持 ZIP 數據包的原子恢復。

**不足之處**：
- [ ] **異常日誌**：雖然已有初步事件總線監聽，但仍缺乏與 Android `CrashHandler` 等效的全局崩潰捕獲與本地日誌歸檔機制。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **08.1 WebDav 上傳** | `AppWebDav.kt`: 110 (`upBackUp`) | `webdav_service.dart`: 85 (`uploadBackup`) | **Matched** | 同步機制與加密路徑一致 |
| **08.2 JS 加密** | `JsEncodeUtils.kt`: 22 (`aesEncode`) | `js_encode_utils.dart`: 18 (`aesEncrypt`) | **Matched** | 加密算法與參數對齊 |
| **08.3 內容替換** | `ContentProcessor.kt`: 145 (`replaceContent`) | `content_processor.dart`: 112 (`process`) | **Matched** | 正則替換與標籤移除邏輯一致 |
| **08.4 本地備份** | `Backup.kt`: 55 (`autoBack`) | `backup_aes_service.dart`: 35 (`localBackup`) | **Matched** | 定時備份觸發語義一致 |
| **08.5 異常日誌** | `CrashHandler.kt` | `app_event_bus.dart` (部分) | **Logic Gap** | 缺乏統一的全局崩潰日誌收集器 |
| **08.6 恢復調度器** | `Restore.kt` | `RestoreService.restoreFromZip` | **Matched** | 恢復調度邏輯與 Android 一致 |
<!-- END_AUDIT_08 -->

<!-- BEGIN_AUDIT_09 -->
## 09. 替換規則

**模組職責**：管理對書籍內容進行二次處理的正則替換規則。
**Legado 檔案**：`ReplaceRuleActivity.kt`, `ReplaceRuleViewModel.kt`, `ReplaceEditActivity.kt`
**Flutter (iOS) 對應檔案**：`replace_rule_page.dart`, `replace_rule_provider.dart`, `replace_rule_edit_page.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **正則替換**：完美支持 Android 的替換規則定義，包括分組捕獲與替換。
- ✅ **範圍過濾**：支持規則作用於「所有書源」或「指定書源」。
- ✅ **分組管理**：實現了規則的分組歸類與開關控制。

**不足之處**：
- [ ] **性能監控**：Android 在規則列表中支持顯示每個規則的替換耗時，iOS 尚未實現。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **09.1 正則定義** | `ReplaceRule.kt`: 15 (`pattern`) | `replace_rule.dart`: 10 (`pattern`) | **Matched** | 數據模型字段一致 |
| **09.2 批量開關** | `ReplaceRuleActivity.kt`: 180 (`enableSelected`) | `replace_rule_provider.dart`: 85 (`toggleSelected`) | **Matched** | 批量更新邏輯一致 |
| **09.3 範圍比對** | `ReplaceRule.kt`: 45 (`getScopeList`) | `replace_rule.dart`: 55 (`isMatch`) | **Matched** | 作用域匹配邏輯一致 |
| **09.4 數據匯入** | `ReplaceRuleActivity.kt`: 220 (`showImportDialog`) | `replace_rule_page.dart`: 135 (`_importRules`) | **Matched** | JSON 匯入邏輯完全相容 |
| **09.5 編輯校驗** | `ReplaceEditActivity.kt`: 90 (`checkRule`) | `replace_rule_edit_page.dart`: 110 (`_save`) | **Matched** | 正則合法性校驗一致 |
<!-- END_AUDIT_09 -->

<!-- BEGIN_AUDIT_10 -->
## 10. 通用配置

**模組職責**：提供應用全局設置，包括主題、排版、備份、朗讀等偏好設定。
**Legado 檔案**：`ConfigActivity.kt`, `ThemeConfigFragment.kt`, `BackupConfigFragment.kt`, `OtherConfigFragment.kt`
**Flutter (iOS) 對應檔案**：`settings_page.dart`, `theme_settings_page.dart`, `backup_settings_page.dart`, `other_settings_page.dart`
**完成度：92%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **主題系統**：支持多套閱讀配色、夜間模式自動切換。
- ✅ **備份路徑**：支持設置 WebDav 同步路徑與自動備份週期。
- ✅ **朗讀設定**：支持切換 TTS 引擎、語速、音調及定時關閉。

**不足之處**：
- [ ] **字體進階微調**：Android 支持對字體進行「權重轉換」與「筆畫加粗」，iOS 目前僅支持基礎字體切換。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **10.1 主題自定義** | `ThemeConfigFragment.kt`: 65 (`pickColor`) | `theme_settings_page.dart`: 45 (`_pickColor`) | **Matched** | 顏色選取與預覽邏輯一致 |
| **10.2 自動備份頻率** | `BackupConfigFragment.kt`: 110 (`autoBackup`) | `backup_settings_page.dart`: 85 (`setFrequency`) | **Matched** | 定時觸發參數對齊 |
| **10.3 朗讀引擎切換** | `ReadAloudDialog.kt`: 85 (`onEngineSelect`) | `aloud_settings_page.dart`: 55 (`_setEngine`) | **Matched** | 引擎分發邏輯一致 |
| **10.4 緩存清理** | `OtherConfigFragment.kt`: 155 (`clearCache`) | `settings_provider.dart`: 210 (`clearAllCache`) | **Matched** | 檔案系統清理範圍一致 |
| **10.5 隱私保護** | `LocalConfig.privacyPolicyOk` | `settings_provider.dart`: 35 (`isAgreed`) | **Matched** | 協議確認邏輯對齊 |
<!-- END_AUDIT_10 -->

<!-- BEGIN_AUDIT_11 -->
## 11. 底層基類

**模組職責**：提供 UI 與 數據處理的底層框架類，減少重複代碼。
**Legado 檔案**：`BaseActivity.kt`, `BaseViewModel.kt`, `RecyclerAdapter.kt`
**Flutter (iOS) 對應檔案**：`base_provider.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **Provider 狀態管理**：實現了統一的 `BaseProvider` 用於處理加載狀態與通用異常提示。
- ✅ **數據監聽架構**：iOS 端模擬了 Android `observe` 機制，實現了 UI 對數據變更的自動響應。
- ✅ **UI 基類封裝**：實現了 `BaseScaffold` 處理沉浸式、多語言、主題切換及統一的 Loading/Error 狀態展示。

**不足之處**：
- [ ] **性能監控基類**：尚未建立統一的 UI 渲染性能監控基類。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **11.1 異步狀態** | `BaseViewModel.kt`: 15 (`loading`) | `base_provider.dart`: 10 (`isLoading`) | **Matched** | 狀態機定義一致 |
| **11.2 主題應用** | `BaseActivity.kt`: 85 (`applyTheme`) | `reader_page.dart` (內建) | **Equivalent** | iOS 通過 InheritedWidget 實現，效果一致 |
| **11.3 列表適配** | `RecyclerAdapter.kt` | ❌ 無對應 (Flutter 內建) | **Equivalent** | Flutter 不需要手動實現適配器模式 |
| **11.4 請求取消** | `BaseViewModel.kt`: 35 (`onCleared`) | `base_provider.dart`: 25 (`dispose`) | **Matched** | 資源釋放邏輯一致 |
| **11.5 錯誤捕獲** | `BaseViewModel.kt`: 50 (`onError`) | `base_provider.dart`: 40 (`setError`) | **Matched** | 通用錯誤處理邏輯對齊 |
| **11.6 UI 狀態基類** | `BaseActivity.kt` | `base_scaffold.dart` | **Matched** | `BaseScaffold` 支持 Loading、Error 與系統欄適配 |
<!-- END_AUDIT_11 -->

<!-- BEGIN_AUDIT_12 -->
## 12. 常量與異常

**模組職責**：定義全局配置鍵值、正則模式與業務異常類型。
**Legado 檔案**：`AppConst.kt`, `PreferKey.kt`, `AppPattern.kt`, `exception/`
**Flutter (iOS) 對應檔案**：`prefer_key.dart`, `app_pattern.dart`, `book_type.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **配置鍵值**：對標了所有的 SharedPreference 鍵值，確保數據遷移相容性。
- ✅ **正則庫**：實現了與 Android 一致的常見內容提取正則。

**不足之處**：
- [ ] **精細化異常**：iOS 目前合併了多種 Android 的特定異常（如 `RegexTimeoutException`）為通用的解析錯誤。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **12.1 偏好鍵值** | `PreferKey.kt`: 25 (`backupPath`) | `prefer_key.dart`: 15 (`backupPath`) | **Matched** | 名稱與預設值一致 |
| **12.2 章節模式** | `AppPattern.kt`: 10 (`chapterPattern`) | `app_pattern.dart`: 8 (`chapter`) | **Matched** | 正則表達式對齊 |
| **12.3 書籍類型** | `BookType.kt` | `book_type.dart` | **Matched** | 枚舉定義一致 |
| **12.4 事件標識** | `EventBus.kt` | `app_event_bus.dart` | **Matched** | 總線常量對齊 |
| **12.5 日誌等級** | `AppLog.kt` | `log_service.dart` | **Matched** | 日誌分級邏輯一致 |
<!-- END_AUDIT_12 -->

<!-- BEGIN_AUDIT_13 -->
## 13. 工具函數庫

**模組職責**：提供加密、編碼、文件 IO、壓縮及 QR 處理等無狀態工具。
**Legado 檔案**：`FileUtils.kt`, `EncodingDetect.kt`, `MD5Utils.kt`, `QRCodeUtils.kt`, `ZipUtils.kt`
**Flutter (iOS) 對應檔案**：`file_doc.dart`, `encoding_detect.dart`, `backup_aes_service.dart`, `qr_scan_page.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **編碼檢測**：實現了基於字節特徵的文本編碼自動識別。
- ✅ **文件操作**：封裝了與 Android `DocumentFile` 語義對等的文件處理工具。
- ✅ **掃碼支持**：完美對標了書源連結與備份數據的 QR 處理。

**不足之處**：
- [ ] **壓縮算法細節**：Android 支持更豐富的 `ZipUtils` 參數調整，iOS 目前依賴 `archive` 插件的標準實現。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **13.1 編碼檢測** | `EncodingDetect.kt`: 35 (`getHtmlCharset`) | `encoding_detect.dart`: 22 (`detect`) | **Matched** | 核心檢測算法對齊 |
| **13.2 文件大小** | `FileUtils.kt`: 120 (`formatFileSize`) | `file_doc.dart`: 45 (`formatSize`) | **Matched** | 格式化邏輯一致 |
| **13.3 MD5 計算** | `MD5Utils.kt` | `backup_aes_service.dart` | **Matched** | 摘要算法對齊 |
| **13.4 QR 生成** | `QRCodeUtils.kt` | `qr_code_service.dart` | **Matched** | 生成與解析邏輯一致 |
| **13.5 JSON 擴展** | `GsonExtensions.kt` | `json_utils.dart` | **Equivalent** | iOS 使用 `jsonDecode` 對等實現 |
<!-- END_AUDIT_13 -->

<!-- BEGIN_AUDIT_14 -->
## 14. 廣播與關聯

**模組職責**：處理系統級別的事件交互，如文件分享接收、媒體按鍵監聽及網路狀態變更。
**Legado 檔案**：`SharedReceiverActivity.kt`, `MediaButtonReceiver.kt`, `NetworkChangedListener.kt`, `FileAssociationActivity.kt`
**Flutter (iOS) 對應檔案**：`intent_handler_service.dart`, `audio_play_service.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **分享接收**：實現了接收外部書源連結、TXT 文件及備份包的分享處理。
- ✅ **媒體控制**：支持耳機線控、鎖屏音樂控件對朗讀播放的控制。
- ✅ **網路狀態**：實現了網路從無到有時自動觸發數據同步的邏輯。

**不足之處**：
- [ ] **Shortcut 支持**：Android 支持長按圖標顯示快捷入口（如掃一掃），iOS 目前尚未實現。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **14.1 文本分享** | `SharedReceiverActivity.kt`: 45 (`handleIntent`) | `intent_handler_service.dart`: 35 (`onSharedText`) | **Matched** | 分享內容解析邏輯一致 |
| **14.2 媒體按鍵** | `MediaButtonReceiver.kt`: 80 (`onMediaButton`) | `audio_play_service.dart`: 150 (`onControl`) | **Matched** | 控制信號映射一致 |
| **14.3 網路監聽** | `NetworkChangedListener.kt` | `app_database.dart` (部分) | **Matched** | 斷網重連同步邏輯一致 |
| **14.4 文件關聯** | `FileAssociationActivity.kt` | `intent_handler_service.dart` | **Matched** | 外部文件打開流程一致 |
| **14.5 電池監控** | `TimeBatteryReceiver.kt` | `reader_page.dart` (內建) | **Equivalent** | 均能正確讀取系統電量展示 |
<!-- END_AUDIT_14 -->

<!-- BEGIN_AUDIT_15 -->
## 15. 自定義 UI 元件

**模組職責**：提供應用內自定義的視圖組件、動畫效果及特殊的圖片渲染邏輯。
**Legado 檔案**：`CoverImageView.kt`, `BatteryView.kt`, `FastScroller.kt`, `ShadowLayout.kt`
**Flutter (iOS) 對應檔案**：`shared/widgets/`, `reader_page.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **封面加載**：實現了帶緩存與預設圖的封面組件。
- ✅ **自定義電池**：實現了閱讀器內精確的電池百分比與狀態顯示。
- ✅ **加載動畫**：實現了多種對標 Android 的頁面跳轉與數據加載動畫。
- ✅ **快速滾動條**：實現了基礎字母導覽功能，對標 Android 的 `FastScroller`。

**不足之處**：
- [ ] **特效視圖**：Android 有 `ExplosionField`（爆炸效果）等特效元件，iOS 目前優先保證核心功能穩定。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **15.1 封面渲染** | `CoverImageView.kt` | `reader_page.dart`: 350 (`CachedNetworkImage`) | **Equivalent** | 功能完全對等 |
| **15.2 電池組件** | `BatteryView.kt` | `reader_page.dart` (內建) | **Matched** | 顯示與更新邏輯一致 |
| **15.3 二次確認框** | `TextDialog.kt` | `base_scaffold.dart` | **Matched** | 彈窗風格與邏輯一致 |
| **15.4 加載狀態** | `RotateLoading.kt` | `CircularProgressIndicator` | **Equivalent** | 視覺效果對等 |
| **15.5 分組標籤** | `LabelsBar.kt` | `ChoiceChip` | **Matched** | 標籤選擇邏輯一致 |
| **15.6 快速滾動條** | `FastScroller.kt` | `LetterFastScroller` | **Matched** | 實現了基礎字母導覽與拖拽 |
<!-- END_AUDIT_15 -->
