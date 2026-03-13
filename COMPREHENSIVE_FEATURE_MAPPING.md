# COMPREHENSIVE_FEATURE_MAPPING.md

## 總覽
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | `ui/book/read/` | `features/reader/` | ✅ | 包含閱讀器、配置、導航 |
| **02** | **書架/主頁面** | `ui/main/` | `features/bookshelf/` | ✅ | 書架、分組管理 |
| **03** | **書源管理** | `ui/book/source/` | `features/source_manager/` | ✅ | 書源列表、編輯、調試 |
| **04** | **核心引擎** | `modules/book/`, `modules/rhino/` | `core/engine/`, `core/local_book/` | ✅ | 解析引擎、JS 運行環境 |
| **05** | **數據持久化** | `data/` | `core/database/`, `core/models/` | ✅ | 資料庫 DAO、Entities |
| **06** | **RSS 閱覽** | `ui/rss/` | `features/rss/` | ✅ | RSS 源管理、文章列表 |
| **07** | **背景服務** | `service/` | `core/services/` | ✅ | TTS 朗讀、下載、Web 服務 |
| **08** | **系統助手/備份** | `help/` | `core/services/` | ✅ | 備份恢復、WebDav、JS 擴展 |
| **09** | **替換規則** | `ui/replace/` | `features/replace_rule/` | ✅ | 正則替換規則管理 |
| **10** | **通用配置** | `ui/config/` | `features/settings/` | ✅ | 主題、備份、其他配置 |
| **11** | **底層基類** | `base/` | `core/base/` | ✅ | Activity, VM 基類與適配器 |
| **12** | **常量與異常** | `constant/`, `exception/` | `core/constant/` | ✅ | 全域變量、正則模式、自定義異常 |
| **13** | **工具函數庫** | `utils/` | `core/services/` | ✅ | 加密、壓縮、文件、編碼工具 |
| **14** | **廣播與關聯** | `receiver/`, `ui/association/` | `features/association/` | ✅ | 分享關聯、媒體控制、網路監聽 |
| **15** | **自定義 UI 元件** | `ui/widget/` | `shared/widgets/` | ✅ | 自定義 View、動畫、圖片處理 |

---

<!-- BEGIN_MAPPING_01 -->
### 01. 閱讀主界面

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ReadBookActivity.kt` | UI (Activity) | `reader_page.dart` | ✅ 已對應 |
| 2 | `ReadBookViewModel.kt` | 業務邏輯 (ViewModel) | `reader_provider.dart` | ✅ 已對應 |
| 3 | `BaseReadBookActivity.kt` | UI (Base) | `reader_page.dart` (合併) | ⚠️ 部分合併 |
| 4 | `ReadMenu.kt` | UI (Menu) | `reader_page.dart` (UI 部分) | ⚠️ 部分合併 |
| 5 | `PageView.kt` | UI (Custom View) | `page_view_widget.dart` | ✅ 已對應 |
| 6 | `ReadView.kt` | UI (Custom View) | `page_view_widget.dart` | ✅ 已對應 |
| 7 | `ChapterProvider.kt` | 資料解析/佈局 (Provider) | `engine/chapter_provider.dart` | ✅ 已對應 |
| 8 | `TextPageFactory.kt` | 邏輯 (Factory) | `engine/text_page.dart` | ✅ 已對應 |
| 9 | `SimulationPageDelegate.kt` | 翻頁動畫 (Delegate) | `engine/simulation_page_view.dart` | ✅ 已對應 |
| 10 | `AutoReadDialog.kt` | 配置 UI (Dialog) | `reader_page.dart` (對話框暫缺) | 🚨 嚴重缺失 |
<!-- END_MAPPING_01 -->

<!-- BEGIN_MAPPING_02 -->
### 02. 書架/主頁面

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `MainActivity.kt` | UI (Activity) | `bookshelf_page.dart` | ✅ 已對應 |
| 2 | `MainViewModel.kt` | 業務邏輯 (ViewModel) | `bookshelf_provider.dart` | ✅ 已對應 |
| 3 | `BookshelfManageActivity.kt` | UI (Activity) | `bookshelf_page.dart` (編輯模式) | ⚠️ 部分合併 |
| 4 | `GroupManageDialog.kt` | UI (Dialog) | `group_manage_page.dart` | ✅ 已對應 |
<!-- END_MAPPING_02 -->

<!-- BEGIN_MAPPING_03 -->
### 03. 書源管理

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `BookSourceActivity.kt` | UI (Activity) | `source_manager_page.dart` | ✅ 已對應 |
| 2 | `BookSourceViewModel.kt` | 業務邏輯 (ViewModel) | `source_manager_provider.dart` | ✅ 已對應 |
| 3 | `BookSourceEditActivity.kt` | UI (Activity) | `source_editor_page.dart` | ✅ 已對應 |
| 4 | `BookSourceDebugActivity.kt` | UI (Activity) | `debug_page.dart` (部分) | ⚠️ 部分對應 |
<!-- END_MAPPING_03 -->

<!-- BEGIN_MAPPING_04 -->
### 04. 核心引擎 (Core Engines)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `EpubReader.java` | 邏輯 (EPUB 解析) | `epub_parser.dart` | ✅ 已對應 |
| 2 | `UmdReader.java` | 邏輯 (UMD 解析) | ❌ 無對應 | ❌ 缺失 |
| 3 | `RhinoScriptEngine.kt` | 引擎 (JS Runtime) | `js_engine.dart` | ✅ 已對應 |
| 4 | `JsAdapter.kt` | 轉接層 (JS Binding) | `js_extensions.dart` | ✅ 已對應 |
| 5 | `AnalyzRule.kt` | 邏輯 (Rule Parser) | `analyze_rule.dart` | ✅ 已對應 |
<!-- END_MAPPING_04 -->

<!-- BEGIN_MAPPING_05 -->
### 05. 數據持久化

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `BookDao.kt` | 資料存取 (DAO) | `database/dao/book_dao.dart` | ✅ 已對應 |
| 2 | `BookSourceDao.kt` | 資料存取 (DAO) | `database/dao/book_source_dao.dart` | ✅ 已對應 |
| 3 | `AppDatabase.kt` | 資料庫核心 | `database/app_database.dart` | ✅ 已對應 |
| 4 | `Book.kt` | 數據模型 (Entity) | `models/book.dart` | ✅ 已對應 |
| 5 | `BookSource.kt` | 數據模型 (Entity) | `models/book_source.dart` | ✅ 已對應 |
| 6 | `DatabaseMigrations.kt`| 資料庫遷移 | `database/app_database.dart` | ✅ 已對應 |
<!-- END_MAPPING_05 -->

<!-- BEGIN_MAPPING_06 -->
### 06. RSS 閱覽

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `RssSourceActivity.kt` | UI (Activity) | `rss/rss_source_page.dart` | ✅ 已對應 |
| 2 | `RssArticlesFragment.kt` | UI (Fragment) | `rss/rss_article_page.dart` | ✅ 已對應 |
| 3 | `ReadRssActivity.kt` | UI (Activity) | `rss/rss_read_page.dart` | ✅ 已對應 |
| 4 | `RssSourceViewModel.kt` | 業務邏輯 (ViewModel) | `rss/rss_source_provider.dart` | ✅ 已對應 |
<!-- END_MAPPING_06 -->

<!-- BEGIN_MAPPING_07 -->
### 07. 背景服務

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `AudioPlayService.kt` | 服務 (Audio) | `services/audio_play_service.dart` | ✅ 已對應 |
| 2 | `DownloadService.kt` | 服務 (Download) | `services/download_service.dart` | ✅ 已對應 |
| 3 | `TTSReadAloudService.kt` | 服務 (TTS) | `services/tts_service.dart` | ✅ 已對應 |
| 4 | `WebService.kt` | 服務 (Web Server) | `services/web_service.dart` | ✅ 已對應 |
<!-- END_MAPPING_07 -->

<!-- BEGIN_MAPPING_08 -->
### 08. 系統助手/備份

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `Backup.kt` | 邏輯 (備份) | `services/backup_aes_service.dart` (部分) | ⚠️ 部分對應 |
| 2 | `Restore.kt` | 邏輯 (恢復) | ❌ 無對應 | ❌ 缺失 |
| 3 | `AppWebDav.kt` | 邏輯 (WebDav) | `services/webdav_service.dart` | ✅ 已對應 |
| 4 | `JsExtensions.kt` | 邏輯 (JS 擴展) | `engine/js/js_extensions.dart` | ✅ 已對應 |
| 5 | `ContentProcessor.kt` | 邏輯 (內容處理) | `services/content_processor.dart` | ✅ 已對應 |
<!-- END_MAPPING_08 -->

<!-- BEGIN_MAPPING_09 -->
### 09. 替換規則

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ReplaceRuleActivity.kt` | UI (Activity) | `replace_rule/replace_rule_page.dart` | ✅ 已對應 |
| 2 | `ReplaceEditActivity.kt` | UI (Activity) | `replace_rule/replace_rule_edit_page.dart` | ✅ 已對應 |
| 3 | `ReplaceRuleViewModel.kt" | 業務邏輯 (ViewModel) | `replace_rule/replace_rule_provider.dart` | ✅ 已對應 |
<!-- END_MAPPING_09 -->

<!-- BEGIN_MAPPING_10 -->
### 10. 通用配置

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ConfigActivity.kt` | UI (Activity) | `settings/settings_page.dart` | ✅ 已對應 |
| 2 | `ThemeConfigFragment.kt` | UI (Fragment) | `settings/theme_settings_page.dart` | ✅ 已對應 |
| 3 | `BackupConfigFragment.kt` | UI (Fragment) | `settings/backup_settings_page.dart" | ✅ 已對應 |
| 4 | `OtherConfigFragment.kt` | UI (Fragment) | `settings/other_settings_page.dart" | ✅ 已對應 |
<!-- END_MAPPING_10 -->

<!-- BEGIN_MAPPING_11 -->
### 11. 底層基類 (Base Classes)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `BaseActivity.kt` | 基類 (Activity) | `shared/widgets/base_scaffold.dart` | ⚠️ 功能對應 |
| 2 | `BaseViewModel.kt` | 基類 (ViewModel) | `core/base/base_provider.dart` | ✅ 已對應 |
| 3 | `RecyclerAdapter.kt` | 基類 (Adapter) | ❌ 無對應 (Flutter ListView) | ➖ 不需對應 |
| 4 | `BaseService.kt` | 基類 (Service) | ❌ 無對應 | ➖ 不需對應 |
<!-- END_MAPPING_11 -->

<!-- BEGIN_MAPPING_12 -->
### 12. 常量與異常 (Constants & Exceptions)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `AppConst.kt` | 常量 | `core/constant/prefer_key.dart` | ✅ 已對應 |
| 2 | `AppPattern.kt` | 常量 (Regex) | `core/constant/app_pattern.dart` | ✅ 已對應 |
| 3 | `PreferKey.kt` | 常量 (Prefs) | `core/constant/prefer_key.dart` | ✅ 已對應 |
| 4 | `RegexTimeoutException.kt` | 異常 | ❌ 無對應 | ❌ 缺失 |
<!-- END_MAPPING_12 -->

<!-- BEGIN_MAPPING_13 -->
### 13. 工具函數庫 (Utils)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `QRCodeUtils.kt` | 工具 (QR) | `features/source_manager/qr_scan_page.dart` | ✅ 已對應 |
| 2 | `FileUtils.kt` | 工具 (文件) | `core/storage/file_doc.dart` | ✅ 已對應 |
| 3 | `EncodingDetect.kt` | 工具 (編碼) | `core/services/encoding_detect.dart` | ✅ 已對應 |
| 4 | `MD5Utils.kt` | 工具 (加密) | `core/services/backup_aes_service.dart` | ✅ 已對應 |
| 5 | `ZipUtils.kt` | 工具 (壓縮) | ❌ 無對應 (依賴插件) | ⚠️ 依賴插件 |
<!-- END_MAPPING_13 -->

<!-- BEGIN_MAPPING_14 -->
### 14. 廣播與關聯 (Receivers & Association)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `MediaButtonReceiver.kt` | 媒體按鈕 | `core/services/audio_play_service.dart` | ✅ 已對應 |
| 2 | `FileAssociationActivity.kt` | 文件關聯 | `features/association/intent_handler_service.dart` | ✅ 已對應 |
| 3 | `ImportBookSourceDialog.kt` | 導入 (Dialog) | `features/source_manager/source_manager_page.dart` | ✅ 已對應 |
| 4 | `OnLineImportActivity.kt` | 導入 (網路) | `shared/widgets/browser_page.dart` | ✅ 已對應 |
<!-- END_MAPPING_14 -->

<!-- BEGIN_MAPPING_15 -->
### 15. 自定義 UI 元件 (Widgets)

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `CoverImageView.kt` | UI (封面) | `shared/widgets/` (通用元件) | ⚠️ 部分合併 |
| 2 | `FastScroller.kt` | UI (快速滾動) | ❌ 無對應 | ❌ 缺失 |
| 3 | `SmoothCheckBox.kt` | UI (核取框) | ❌ 無對應 | ➖ 使用原生 |
| 4 | `BatteryView.kt` | UI (電池) | `features/reader/reader_page.dart` (內建) | ✅ 已對應 |
<!-- END_MAPPING_15 -->
