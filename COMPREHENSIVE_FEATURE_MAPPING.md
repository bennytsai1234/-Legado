# 🗺️ Legado (Android) ➔ Reader (iOS) 功能映射表 (Comprehensive Mapping)

本文件定義了 Android 端模組與 iOS 端實作檔案的對應關係，作為增量審計的導航手冊。

---

## 📂 核心模組映射清單 (Module 01-30)

| ID | 模組名稱 | Android (Kotlin/XML) 責任路徑 | iOS (Dart) 責任路徑 |
| :--- | :--- | :--- | :--- |
| **01** | **主框架 (Main)** | `ui/main/MainActivity.kt`, `MainViewModel.kt` | `lib/main.dart`, `lib/features/bookshelf/bookshelf_page.dart` |
| **02** | **關於 (About)** | `ui/about/ReadRecordActivity.kt`, `AppLogDialog.kt` | `lib/features/about/about_page.dart` |
| **03** | **檔案關聯 (Assoc)** | `ui/association/FileAssociationActivity.kt` | `lib/features/association/intent_handler_service.dart` |
| **04** | **有聲書 (Audio)** | `ui/book/audio/AudioPlayActivity.kt`, `AudioPlayViewModel.kt` | `lib/features/reader/audio_player_page.dart`, `lib/core/services/audio_play_service.dart` |
| **05** | **全域書籤 (Bookmark)** | `ui/book/bookmark/AllBookmarkActivity.kt` | `lib/features/bookshelf/bookmark_list_page.dart` |
| **06** | **快取下載 (Cache)** | `ui/book/cache/CacheActivity.kt`, `model/CacheBook.kt` | `lib/features/cache_manager/`, `lib/core/services/download_service.dart` |
| **07** | **換封面 (Cover)** | `ui/book/changecover/ChangeCoverDialog.kt` | `lib/features/book_detail/change_cover_sheet.dart` |
| **08** | **換源 (Source)** | `ui/book/changesource/ChangeBookSourceDialog.kt` | `lib/features/reader/change_chapter_source_sheet.dart` |
| **09** | **發現探索 (Explore)** | `ui/main/explore/ExploreFragment.kt` | `lib/features/explore/explore_page.dart` |
| **10** | **書架分組 (Group)** | `ui/book/group/GroupManageDialog.kt` | `lib/features/bookshelf/group_manage_page.dart` |
| **11** | **書籍詳情 (Info)** | `ui/book/info/BookInfoActivity.kt` | `lib/features/book_detail/book_detail_page.dart` |
| **12** | **匯入書籍 (Import)** | `ui/book/import/local/ImportBookActivity.kt` | `lib/features/local_book/smart_scan_page.dart` |
| **13** | **漫畫閱讀 (Manga)** | `ui/book/read/ReadMangaActivity.kt` | `lib/features/reader/manga_reader_page.dart` |
| **14** | **核心閱讀器 (Read)** | `ui/book/read/ReadBookActivity.kt`, `ReadBookViewModel.kt` | `lib/features/reader/reader_page.dart`, `lib/features/reader/reader_provider.dart` |
| **15** | **全書搜尋 (Search)** | `ui/book/search/SearchActivity.kt` | `lib/features/search/search_page.dart` |
| **16** | **內文搜尋 (Find)** | `ui/book/searchContent/SearchContentActivity.kt` | `lib/features/reader/reader_page.dart` (Search Function) |
| **17** | **書源管理 (SrcMgr)** | `ui/book/source/manage/BookSourceActivity.kt` | `lib/features/source_manager/source_manager_page.dart` |
| **18** | **目錄與書籤 (TOC)** | `ui/book/toc/TocActivity.kt` | `lib/features/book_detail/book_detail_page.dart` (TOC Tab) |
| **19** | **內建瀏覽器 (Web)** | `ui/browser/WebViewActivity.kt` | `lib/shared/widgets/browser_page.dart` |
| **20** | **設定備份 (Config)** | `ui/config/ConfigActivity.kt`, `help/storage/Backup.kt` | `lib/features/settings/`, `lib/core/services/webdav_service.dart` |
| **21** | **字典 (Dict)** | `ui/dict/DictDialog.kt` | `lib/core/services/dictionary_service.dart` |
| **22** | **字典規則 (Rule)** | `ui/dict/DictRuleActivity.kt` | `lib/core/models/dict_rule.dart` |
| **23** | **檔案總管 (File)** | `ui/file/FilePickerActivity.kt` | `lib/core/storage/file_doc.dart` |
| **24** | **字體管理 (Font)** | `ui/config/FontConfigFragment.kt` | `lib/features/settings/font_manager_page.dart` |
| **25** | **書源登入 (Login)** | `ui/book/source/edit/BookSourceEditActivity.kt` | `lib/features/source_manager/source_login_page.dart` |
| **26** | **掃描 (QrCode)** | `ui/qrcode/QrCodeActivity.kt` | `lib/features/source_manager/qr_scan_page.dart` |
| **27** | **替換規則 (Repl)** | `ui/book/read/ReplaceRuleActivity.kt` | `lib/features/replace_rule/` |
| **28** | **RSS 訂閱 (RSS)** | `ui/main/rss/RssFragment.kt` | `lib/features/rss/` |
| **29** | **歡迎頁 (Welcome)** | `ui/welcome/WelcomeActivity.kt` | `lib/features/welcome/welcome_page.dart` |
| **30** | **UI 元件 (Widget)** | `ui/widget/` | `lib/shared/widgets/` |

---

## 🧩 核心引擎映射 (Core Engines)

| 功能引擎 | Android (Kotlin) 路徑 | iOS (Dart) 路徑 |
| :--- | :--- | :--- |
| **解析引擎** | `model/analyzeRule/AnalyzeRule.kt` | `lib/core/engine/analyze_rule.dart` |
| **JS 引擎** | `model/SharedJsScope.kt`, `help/JsExtensions.kt` | `lib/core/engine/js/` |
| **資料庫 (DAO)** | `data/appDb.kt`, `data/entities/` | `lib/core/database/dao/` |
| **HTTP 網路** | `help/http/HttpHelper.kt` | `lib/core/services/http_client.dart` |
| **朗讀引擎** | `help/TTS.kt`, `model/ReadAloud.kt` | `lib/core/services/tts_service.dart` |
