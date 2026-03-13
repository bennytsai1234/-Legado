# 🗺️ Legado Android ↔ iOS Flutter 結構映射地圖 (Comprehensive Feature Mapping)

本文件建立了 Android 原生 Legado 專案與 iOS Flutter 遷移專案之間的職責對應關係。

## 📊 總覽表格 (Mapping Overview)

| 模組 | Android 路徑 (io.legado.app) | iOS 路徑 (lib/) | 核心職責 | 狀態 |
| :--- | :--- | :--- | :--- | :--- |
| **資料實體** | `data.entities` | `core.models` | 跨平台的資料模型定義 | ✅ |
| **資料存取** | `data.dao` | `core.database.dao` | SQLite 資料庫 CRUD 操作 | ✅ |
| **解析引擎** | `model.analyzeRule` | `core.engine` | 書源規則解析 (JSONPath, Jsoup, XPath) | ✅ |
| **業務助手** | `help` | `core.services` | WebDAV, TTS, 書籍內容處理, 備份還原 | ✅ |
| **核心 UI** | `ui` | `features` | 書架、閱讀器、書源管理、RSS | ✅ |
| **外部模組** | `modules.book` | `core.local_book` | 本地文件 (EPUB, UMD) 解析 | ✅ |

---

<!-- BEGIN_MAPPING_DATA -->
### 1. 資料模型與存取 (Data & Entities)
**職責定義**：負責定義書源、書籍、章節、規則等核心資料結構，以及與資料庫的互動。

| # | Android 檔案 | 核心職責 | iOS 對應檔案 | 依賴對標 | 狀態 |
|:--|:---|:---|:---|:---|:---|
| 1 | `Book.kt` | 書籍實體模型 | `book.dart` | Room ↔ sqflite | ✅ |
| 2 | `BookSource.kt` | 書源規則定義 | `book_source.dart` | - | ✅ |
| 3 | `BookChapter.kt` | 章節資訊模型 | `chapter.dart` | - | ✅ |
| 4 | `BookDao.kt` | 書籍資料庫操作 | `book_dao.dart` | Room ↔ sqflite | ✅ |
| 5 | `BookSourceDao.kt` | 書源資料庫操作 | `book_source_dao.dart` | Room ↔ sqflite | ✅ |
| 6 | `Cookie.kt/Dao` | Cookie 持久化 | `cookie.dart/dao.dart` | - | ✅ |
<!-- END_MAPPING_DATA -->

<!-- BEGIN_MAPPING_ENGINE -->
### 2. 解析引擎 (Analyze Engine)
**職責定義**：Legado 的核心邏輯，負責解析不同格式的網絡數據，支援 JS 注入與自定義規則。

| # | Android 檔案 | 核心職責 | iOS 對應檔案 | 依賴對標 | 狀態 |
|:--|:---|:---|:---|:---|:---|
| 1 | `AnalyzeRule.kt` | 總體解析邏輯 | `analyze_rule.dart` | - | ✅ |
| 2 | `AnalyzeByJSoup.kt` | CSS/HTML 解析 | `analyze_by_css.dart` | Jsoup ↔ html | ✅ |
| 3 | `AnalyzeByJSonPath.kt` | JSON 解析 | `analyze_by_json_path.dart` | - ↔ json_path | ✅ |
| 4 | `AnalyzeByXPath.kt` | XML/HTML 解析 | `analyze_by_xpath.dart` | - ↔ xpath_selector | ✅ |
| 5 | `AnalyzeByRegex.kt` | 正則表達式解析 | `analyze_by_regex.dart` | - | ✅ |
| 6 | `RuleAnalyzer.kt` | 規則執行器 | `rule_analyzer.dart` | - | ✅ |
| 7 | `help.rhino.*` | JS 引擎封裝 | `core.engine.js.*` | Rhino ↔ flutter_js | ✅ |
<!-- END_MAPPING_ENGINE -->

<!-- BEGIN_MAPPING_HELP -->
### 3. 業務助手 (Help & Services)
**職責定義**：封裝複雜的業務邏輯，如網絡請求、內容處理、多媒體服務等。

| # | Android 檔案 | 核心職責 | iOS 對應檔案 | 依賴對標 | 狀態 |
|:--|:---|:---|:---|:---|:---|
| 1 | `AppWebDav.kt` | WebDAV 同步 | `webdav_service.dart` | - ↔ webdav_client | ✅ |
| 2 | `ContentProcessor.kt` | 正文清洗與排版 | `content_processor.dart` | - | ✅ |
| 3 | `TTS.kt` | 語音朗讀 | `tts_service.dart` | - ↔ flutter_tts | ✅ |
| 4 | `HttpHelper.kt` | 網絡請求封裝 | `http_client.dart` | OkHttp ↔ dio | ✅ |
| 5 | `Backup.kt/Restore.kt` | 配置備份與還原 | `backup_aes_service.dart/restore_service.dart` | - | ✅ |
| 6 | `CacheManager.kt` | 緩存管理 | `cache_manager.dart` | - | ✅ |
<!-- END_MAPPING_HELP -->

<!-- BEGIN_MAPPING_UI -->
### 4. UI 功能模組 (UI & Features)
**職責定義**：提供用戶操作介面。

| # | Android 檔案 | 核心職責 | iOS 對應檔案 | 狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ui.main.bookshelf.*` | 書架介面 | `features.bookshelf.*` | ✅ |
| 2 | `ui.book.read.*` | 閱讀器介面 | `features.reader.*` | ✅ |
| 3 | `ui.book.source.*` | 書源管理介面 | `features.source_manager.*` | ✅ |
| 4 | `ui.rss.*` | RSS 訂閱介面 | `features.rss.*` | ✅ |
| 5 | `ui.book.info.*` | 書籍詳情介面 | `features.book_detail.*` | ✅ |
| 6 | `ui.replace.*` | 替換規則介面 | `features.replace_rule.*` | ✅ |
<!-- END_MAPPING_UI -->

---

## ❌ 遺失清單 (Missing Inventory / Pending Port)

以下為 Android 專案中存在但 iOS 目前尚未實現或需要進一步對標的關鍵功能：

1.  **ExoPlayerHelper.kt**: 針對音頻書籍的高級控制（目前的 `just_audio` 實現可能尚未完全對標高級緩存與預加載邏輯）。
2.  **Cronet**: 高級網絡堆棧支援，iOS 暫時僅使用 Dio/Native。
3.  **CanvasRecorder**: 閱讀器翻頁動畫的錄製/緩存（iOS 使用 Flutter 渲染，翻頁動畫機制完全不同）。
4.  **Aliyun/Cloud support**: 部分雲端 SDK 整合。

---

## 🏗️ 職責映射鐵律驗證
- [x] **1-to-N 拆分**：已識別 `ReadBookConfig.kt` 在 iOS 中拆分為多個 Provider 與 Page。
- [x] **依賴校核**：已比對 `pubspec.yaml` 並確認核心依賴對標完成。
