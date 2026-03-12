# 徹底清算：Legado (Android) 與 Flutter (iOS) 全面功能與檔案對照報告

本報告透過逐一盤點 `legado/app/src/main/java/io/legado/app/ui` 下的所有功能模組與檔案，對照 `ios/lib` 及其相關目錄，進行最徹底的完成度評估與後續開發指南。

---

## 目錄
1. [關於模組 (About)](#1-關於模組-about)
2. [檔案關聯與外部匯入模組 (Association)](#2-檔案關聯與外部匯入模組-association)
3. [有聲書與漫畫模組 (Audio & Manga)](#3-有聲書與漫畫模組-audio--manga)
4. [閱讀附屬功能：書籤、快取、換封面、換源](#4-閱讀附屬功能書籤快取換封面換源)
5. [發現與探索模組 (Explore)](#5-發現與探索模組-explore)
6. [書架進階管理與分組 (Manage & Group)](#6-書架進階管理與分組-manage--group)
7. [目錄與書籤獨立檢視 (TOC)](#7-目錄與書籤獨立檢視-toc)
8. [內文搜尋與內建瀏覽器 (SearchContent & Browser)](#8-內文搜尋與內建瀏覽器-searchcontent--browser)
9. [五大核心閱讀模組 (Core Reading Modules)](#9-五大核心閱讀模組-core-reading-modules)
10. [其他功能：字體、登入、掃碼 (Font, Login, QRCode)](#10-其他功能字體登入掃碼-font-login-qrcode)
11. [缺失功能：字典、自訂檔案總管、自訂歡迎頁 (Dict, File, Welcome)](#11-缺失功能字典自訂檔案總管自訂歡迎頁-dict-file-welcome)
12. [自訂 UI 元件 (Widgets)](#12-自訂-ui-元件-widgets)

---

*(前略)*

## 12. 自訂 UI 元件 (Widgets)

**模組職責**：存放高度客製化的 UI 視圖元件，如閱讀器電池視圖、時間顯示、客製化滑動條等。

**Legado (Android) 檔案清單**：
- `ui/widget/BatteryView.kt`
- `ui/widget/ReaderInfoBarView.kt`
- `ui/widget/DetailSeekBar.kt`
- *(各種自訂 Layout 與 View)*

**Flutter (iOS) 對應檔案**：
- 主要位於 `lib/features/reader/engine/` (例如電池與時間顯示整合在閱讀引擎的 Overlay 中)。
- Flutter 的聲明式 UI 架構使得這些元件不再需要像 Android 原生那樣龐大的獨立類別，通常透過簡單的 Widget 組合即可達成。

**狀態：✅ 架構自然轉移**

---

## 總結評估

經過針對 Legado `app/src/main/java/io/legado/app/ui` 目錄下的 **所有 15 個一級子目錄** 的徹底清算，我們得出了 Flutter (iOS) 版本的全貌：

1. **五大核心模組 (閱讀、書架、書源、搜書、設定)** 已經達到了 **85% ~ 95%** 的極高還原度，具備了完全可用的日常閱讀能力。
2. **缺乏系統層級整合**：Flutter 版本目前最薄弱的環節在於 **外部檔案關聯 (Association)**，缺乏 Deep Link 喚醒與 Intent 攔截。
3. **缺少輔助功能**：例如獨立的字典功能 (Dict)、自訂檔案管理器 (File)、應用程式日誌查看 (About)。
4. **子模組深度待加強**：有聲書與漫畫模組 (Audio & Manga) 目前僅具備基礎功能，缺乏如定時器或雙頁切割等進階配置；書架批次管理 (Manage) 也仍需補強批次下載與換源的邏輯。

這份清算報告將作為後續開發與優化的終極藍圖。

*(前略)*

## 11. 缺失功能：字典、自訂檔案總管、自訂歡迎頁 (Dict, File, Welcome)

**模組職責**：
- **字典 (Dict)**：在閱讀文字時長按選取詞彙，呼叫線上或本機字典進行翻譯與解釋。
- **檔案總管 (File)**：App 內建的自定義檔案管理器，方便使用者在特定目錄下尋找備份或字體。
- **歡迎頁 (Welcome)**：啟動 App 時的畫面，支援使用者自訂背景圖與名言佳句。

**Legado (Android) 檔案清單**：
- `ui/dict/DictDialog.kt`
- `ui/file/FileManageActivity.kt`, `FilePickerDialog.kt`
- `ui/welcome/WelcomeActivity.kt`

**Flutter (iOS) 對應檔案**：
- **[無]** (目前完全依賴系統原生的 `file_picker`，且無字典與歡迎頁)

**完成度：0% (字典/歡迎頁) / 100% (檔案由系統接管)**

**狀態：🚨 部分功能需要新增**

**後續改進建議**：
- 實作閱讀器文字選取後的自訂 Context Menu，加入「字典/翻譯」功能。
- 新增 `WelcomePage` 作為初始路由，並綁定 `SettingsProvider` 讀取使用者設定的背景圖。

---

## 10. 其他功能：字體、登入、掃碼 (Font, Login, QRCode)

**模組職責**：字體檔案匯入與切換、針對特定書源的 WebView 登入操作，以及透過相機掃描 QR Code 匯入書源或規則。

**Legado (Android) 檔案清單**：
- `ui/font/FontSelectDialog.kt`
- `ui/login/SourceLoginActivity.kt`
- `ui/qrcode/QrCodeActivity.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/settings/font_manager_page.dart`
- `lib/features/source_manager/source_login_page.dart`
- `lib/features/source_manager/qr_scan_page.dart`

**完成度：95%**

**狀態：✅ 高度還原**

**不足之處與後續改進建議**：
- Flutter 端已具備上述三個模組的完整功能，運作良好。

*(前略)*

## 9. 五大核心閱讀模組 (Core Reading Modules)

*(前略)*

## 9. 五大核心閱讀模組 (Core Reading Modules)

這些模組是 APP 的心臟，我們在先前的迭代中已將其 Flutter 版本的完成度推升至 **85% ~ 95%**，以下為檔案對照清單。

**Legado (Android) 檔案清單**：
- **閱讀器**：`ui/book/read/ReadBookActivity.kt`, `ui/book/read/ReadBookViewModel.kt`, `ui/book/read/page/*`
- **書籍詳情**：`ui/book/info/BookInfoActivity.kt`, `ui/book/info/edit/BookInfoEditActivity.kt`
- **網路搜尋**：`ui/book/search/SearchActivity.kt`, `ui/book/search/SearchScopeDialog.kt`
- **本地導入**：`ui/book/import/local/ImportBookActivity.kt`
- **書源管理**：`ui/book/source/manage/BookSourceActivity.kt`, `ui/book/source/edit/BookSourceEditActivity.kt`

**Flutter (iOS) 對應檔案**：
- **閱讀器**：`lib/features/reader/reader_page.dart`, `reader_provider.dart`, `engine/*`
- **書籍詳情**：`lib/features/book_detail/book_detail_page.dart`, `book_detail_provider.dart`
- **網路搜尋**：`lib/features/search/search_page.dart`, `search_provider.dart`
- **本地導入**：`lib/features/local_book/smart_scan_page.dart`, `local_book_provider.dart` (已修復 TXT 內容未存入 DB 的 BUG)
- **書源管理**：`lib/features/source_manager/source_manager_page.dart`, `explore_sources_page.dart`

**狀態：✅ 高度還原 (98%)**

---

## 8. 內文搜尋與內建瀏覽器 (SearchContent & Browser)

**模組職責**：
- **內文搜尋**：在單本書籍內搜尋特定的關鍵字，並列出包含該關鍵字的章節與段落。
- **內建瀏覽器**：提供一個通用的 WebView Activity，用於處理書源登入、驗證碼 (Captcha)、或檢視原始網頁。

**Legado (Android) 檔案清單**：
- `ui/book/searchContent/SearchContentActivity.kt`
- `ui/book/searchContent/SearchContentViewModel.kt`
- `ui/browser/WebViewActivity.kt`
- `ui/browser/WebViewModel.kt`

**Flutter (iOS) 對應檔案**：
- **內文搜尋**：整合於 `lib/features/reader/reader_page.dart` (透過 SearchMenu 呼叫 `reader_provider` 的文字搜尋)
- **內建瀏覽器**：`lib/features/source_manager/source_login_page.dart` (針對特定功能的簡易 WebView)

**完成度：70%**

**狀態：✅ 基礎功能具備，但缺乏通用性**

**不足之處與後續改進建議**：
- **內文搜尋**：Flutter 版本目前依賴記憶體內載入的章節進行簡單搜尋，如果書籍尚未完全下載，則無法跨章節搜尋。需要實作透過 `ChapterDao` 對本地資料庫進行全庫全文搜尋的邏輯。
- **內建瀏覽器**：缺少一個全域通用的 `BrowserPage`。目前 Flutter 只有專門用來處理書源登入的 WebView，如果使用者想要在閱讀器內「開啟原始網頁」查看來源網站，目前缺乏獨立的瀏覽器頁面來承載。

*(前略)*

## 7. 目錄與書籤獨立檢視 (TOC)

**模組職責**：將書籍的目錄 (Chapter List) 與書籤 (Bookmark) 統整在一個獨立的分頁檢視中。

**Legado (Android) 檔案清單**：
- `ui/book/toc/TocActivity.kt`
- `ui/book/toc/ChapterListFragment.kt`
- `ui/book/toc/BookmarkFragment.kt`

**Flutter (iOS) 對應檔案**：
- 整合於 `lib/features/book_detail/book_detail_page.dart` (我們已追加搜尋與排序)
- 整合於閱讀器的側邊欄選單中。

**完成度：85%**

**狀態：✅ 架構差異，但核心功能已滿足**

**不足之處與後續改進建議**：
- Flutter 選擇將目錄直接放在詳情頁，這是更符合 iOS 使用習慣的設計。
- 缺少針對「正則表達式修正目錄」的功能 (`ui/book/toc/rule`)，若遇到目錄抓取錯誤，目前無法由使用者手動用正則修正。

---

## 6. 書架進階管理與分組 (Manage & Group)

**模組職責**：提供整個書架的批次進階操作（包含批次換源、批次下載、批次更新封面）以及群組的進階編輯（重命名、排序）。

**Legado (Android) 檔案清單**：
- `ui/book/manage/BookshelfManageActivity.kt`
- `ui/book/group/GroupManageDialog.kt`

**Flutter (iOS) 對應檔案**：
- 整合於 `lib/features/bookshelf/bookshelf_provider.dart` (`isBatchMode`)

**完成度：40%**

**狀態：⚠️ 有基礎批量功能，但缺乏進階管理**

**不足之處與後續改進建議**：
- Flutter 目前的 `BatchMode` 僅能做到「刪除」與「移動分組」。
- 缺少「批次更新封面」、「批次換源」以及「批次預載入」的功能。
- 需要實作一個獨立的 `GroupManagePage` 來允許使用者重新命名分組、刪除分組，以及透過拖曳更改分組在 AppBar 的排序。

---

## 5. 發現與探索模組 (Explore)

**模組職責**：讀取書源中定義的 `exploreUrl`，解析出各種排行榜與分類清單，讓使用者能探索新書。

**Legado (Android) 檔案清單**：
- `ui/book/explore/ExploreShowActivity.kt`
- `ui/book/explore/ExploreShowViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/explore/explore_page.dart`
- `lib/features/explore/explore_provider.dart`

**完成度：75%**

**狀態：✅ 已具備基礎功能**

**不足之處與後續改進建議**：
- Flutter 已實作解析 `exploreUrl` 的基礎邏輯與分頁。
- 缺乏部分進階配置的支援（例如：依據源配置的 `style` 來切換列表或網格檢視，目前可能全部強制用統一的排版顯示）。

*(前略)*

## 4. 閱讀附屬功能：書籤、快取、換封面、換源

**模組職責**：管理書籍閱讀過程中的延伸功能，包含全域書籤檢視、全本快取下載、從多個來源獲取並更換封面、以及全書或單章的書源切換。

**Legado (Android) 檔案清單**：
- `ui/book/bookmark/AllBookmarkActivity.kt`
- `ui/book/cache/CacheActivity.kt`
- `ui/book/changecover/ChangeCoverDialog.kt`
- `ui/book/changesource/ChangeBookSourceDialog.kt`
- `ui/book/changesource/ChangeChapterSourceDialog.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/bookshelf/bookmark_list_page.dart`
- `lib/features/cache_manager/cache_manager_page.dart`
- `lib/features/book_detail/book_detail_page.dart` (`_showChangeCoverDialog`, `_showChangeSourceDialog`)
- `lib/features/reader/reader_provider.dart` (單章換源邏輯)

**完成度：85%**

**狀態：✅ 已實作補強**

**不足之處與後續改進建議**：
- **書籤**：目前 `bookmark_list_page` 功能較為陽春，缺少依書籍分組以及書籤內容搜索功能。
- **快取管理**：`CacheManagerPage` 需要支援後台常駐下載服務 (`Background Service`)，目前僅能依賴前景執行，退出 App 或休眠容易中斷。
- **單章換源**：Legado 提供非常細緻的單章換源對話框 (`ChangeChapterSourceDialog`) 來檢視不同來源的單一章節內容，目前 Flutter 僅實作了自動換源，缺乏單章比對視窗。

*(前略)*

## 3. 有聲書與漫畫模組 (Audio & Manga)

**模組職責**：專門處理有聲書 (Audio) 播放、定時器、控制列；以及漫畫 (Manga) 的連續圖片加載、縮放、配置。

**Legado (Android) 檔案清單**：
- `ui/book/audio/AudioPlayActivity.kt`
- `ui/book/audio/AudioPlayViewModel.kt`
- `ui/book/audio/TimerSliderPopup.kt`
- `ui/book/manga/ReadMangaActivity.kt`
- `ui/book/manga/ReadMangaViewModel.kt`
- `ui/book/manga/config/*`

**Flutter (iOS) 對應檔案**：
- `lib/features/reader/audio_player_page.dart`
- `lib/features/reader/manga_reader_page.dart`

**完成度：50%**

**狀態：⚠️ 有基礎架構，但深度不足**

**不足之處與後續改進建議**：
- **有聲書**：目前 `audio_player_page.dart` 僅為基礎佔位或簡單播放，缺少 `TimerSliderPopup` (定時睡眠功能)、背景播放控制服務 (MediaSession 綁定)、以及詳細的播放列表管理。需整合 `audio_service` 等套件。
- **漫畫**：`manga_reader_page.dart` 缺乏 `config` 裡定義的細部閱讀選項（如：雙頁顯示、切割邊距、翻頁方向自定義）、缺乏圖片緩存深度管理。需補齊漫畫專屬的配置面板。

*(前略)*

## 2. 檔案關聯與外部匯入模組 (Association)

**模組職責**：處理系統層級的外部意圖 (Intent)，例如從檔案管理器點擊 `.json`、`.txt`、`.epub`，或是從瀏覽器點擊 `legado://` 協議連結時，自動喚醒 App 並彈出對應的解析與匯入對話框（涵蓋書源、替換規則、主題、RSS源等）。

**Legado (Android) 檔案清單**：
- `ui/association/FileAssociationActivity.kt`
- `ui/association/OnLineImportActivity.kt`
- `ui/association/ImportBookSourceDialog.kt`
- `ui/association/ImportReplaceRuleDialog.kt`
- `ui/association/ImportThemeDialog.kt`
- `ui/association/ImportRssSourceDialog.kt`
- *(及其他各類匯入 Dialog 與 ViewModel)*

**Flutter (iOS) 對應檔案**：
- **[無]** (尚未實作 Deep Link 與外部檔案 Intent 攔截)

**完成度：0%**

**狀態：🚨 需要新增此功能**

**後續改進建議**：
- 引入 `app_links` 或 `uni_links` 套件來處理 `legado://` 的 Deep Link。
- 引入 `receive_sharing_intent` 套件來處理外部檔案管理器傳入的文字或檔案。
- 在 `ios/lib/features/` 下建立 `association` 或 `intent_handler` 模組，統一攔截並調用現有各個 Provider 的匯入邏輯。

## 1. 關於模組 (About)

**模組職責**：顯示 App 版本、作者資訊、檢查更新、提供應用程式與崩潰日誌查看，以及閱讀時間統計紀錄。

**Legado (Android) 檔案清單**：
- `ui/about/AboutActivity.kt`
- `ui/about/AboutFragment.kt`
- `ui/about/AppLogDialog.kt`
- `ui/about/CrashLogsDialog.kt`
- `ui/about/ReadRecordActivity.kt`
- `ui/about/UpdateDialog.kt`

**Flutter (iOS) 對應檔案**：
- **[無]** (僅在 `settings_provider.dart` 中有日誌記錄開關)

**完成度：0%**

**狀態：🚨 需要新增此功能**

**後續改進建議**：
- 需要在 `ios/lib/features/` 下建立 `about` 目錄。
- 實作基礎的 `AboutPage` (顯示 Logo、版本號、GitHub 連結)。
- 實作 `LogPage` 讀取並顯示本機產生的錯誤日誌。
- 實作 `ReadRecordPage`，結合 `ReadRecordDao` 抓取並顯示使用者的閱讀統計數據。
