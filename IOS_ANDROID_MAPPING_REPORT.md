# iOS (Flutter) 與 Android (Legado) 架構與檔案對照分析報告

本報告針對 `legado_reader` (iOS/Flutter) 專案的所有檔案進行全面梳理，並與原版 Android (Legado) 專案進行一對一的對照與分析，以協助開發者快速理解跨平台專案的架構映射關係。

## 1. 核心進入點與共用

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/main.dart` | `App.kt` / `ui/main/MainActivity.kt` | 應用程式進入點、全域狀態 Provider 註冊、底部導航主頁。 |
| `lib/shared/theme/app_theme.dart` | `ui/base/Theme.kt` / `help/config/ThemeConfig.kt` | 應用程式主題與閱讀器色彩配置。 |

---

## 2. 資料庫與 DAO (Data Access Object)

iOS 版本使用 `sqflite` 實作，Android 版本使用 `Room`。

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/core/database/app_database.dart` | `data/AppDatabase.kt` | 資料庫實例管理與表格建立/遷移邏輯 (`_onCreate`, `_onUpgrade`)。 |
| `lib/core/database/dao/book_dao.dart` | `data/dao/BookDao.kt` | 書籍 (Bookshelf) 存取。 |
| `lib/core/database/dao/book_source_dao.dart` | `data/dao/BookSourceDao.kt` | 書源存取與管理。 |
| `lib/core/database/dao/chapter_dao.dart` | `data/dao/BookChapterDao.kt` | 書籍章節目錄與正文內容快取。 |
| `lib/core/database/dao/bookmark_dao.dart` | `data/dao/BookmarkDao.kt` | 閱讀書籤存取。 |
| `lib/core/database/dao/cache_dao.dart` | `data/dao/CacheDao.kt` | 通用快取管理 (未使用於正文，偏向網路快取)。 |
| `lib/core/database/dao/cookie_dao.dart` | `data/dao/CookieDao.kt` | 網路請求 Cookie 持久化。 |
| `lib/core/database/dao/replace_rule_dao.dart`| `data/dao/ReplaceRuleDao.kt` | 正文替換淨化規則。 |
| `lib/core/database/dao/search_history_dao.dart`| `data/dao/SearchHistoryDao.kt` | 搜尋歷史紀錄。 |
| `lib/core/database/dao/book_group_dao.dart` | `data/dao/BookGroupDao.kt` | 書籍分組管理。 |
| `lib/core/database/dao/read_record_dao.dart` | `data/dao/ReadRecordDao.kt` | 閱讀時間/紀錄統計。 |
| `lib/core/database/dao/rss_source_dao.dart` | `data/dao/RssSourceDao.kt` | RSS 訂閱源存取。 |
| `lib/core/database/dao/rss_article_dao.dart` | `data/dao/RssArticleDao.kt` | RSS 文章列表存取。 |
| `lib/core/database/dao/dict_rule_dao.dart` | `data/dao/DictRuleDao.kt` | 自訂字典查詞規則。 |
| `lib/core/database/dao/http_tts_dao.dart` | `data/dao/HttpTTSDao.kt` | 線上語音合成 (HTTP TTS) 引擎配置。 |
| `lib/core/database/dao/keyboard_assist_dao.dart`| `data/dao/KeyboardAssistDao.kt` | 鍵盤輔助/自訂按鍵規則。 |
| `lib/core/database/dao/rss_read_record_dao.dart`| `data/dao/RssStarDao.kt` (或相關) | RSS 文章閱讀狀態紀錄。 |
| `lib/core/database/dao/rss_star_dao.dart` | `data/dao/RssStarDao.kt` | RSS 文章收藏紀錄。 |
| `lib/core/database/dao/rule_sub_dao.dart` | `data/dao/RuleSubDao.kt` | 規則訂閱 (自訂規則匯入)。 |
| `lib/core/database/dao/search_keyword_dao.dart`| `data/dao/SearchKeywordDao.kt` | 搜尋關鍵字熱度與統計。 |
| `lib/core/database/dao/txt_toc_rule_dao.dart` | `data/dao/TxtTocRuleDao.kt` | 本地 TXT 電子書目錄解析規則。 |

---

## 3. 資料模型 (Models / Entities)

iOS 版本將 Android 的 `@Entity` 資料類別轉換為標準 Dart 類別，並提供 `fromJson` / `toJson` 支援跨平台書源 JSON 格式相容。

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/core/models/base_book.dart` | `data/entities/BaseBook.kt` | 書籍基礎介面。 |
| `lib/core/models/base_source.dart` | `data/entities/BaseSource.kt` | 書源基礎介面。 |
| `lib/core/models/base_rss_article.dart` | `data/entities/BaseRssArticle.kt` | RSS 文章基礎介面。 |
| `lib/core/models/book.dart` | `data/entities/Book.kt` | 書架書籍實體。 |
| `lib/core/models/book_source.dart` | `data/entities/BookSource.kt` | 書源實體 (最核心，包含所有解析規則)。 |
| `lib/core/models/chapter.dart` | `data/entities/BookChapter.kt` | 書籍章節實體。 |
| `lib/core/models/search_book.dart` | `data/entities/SearchBook.kt` | 網路搜尋結果實體。 |
| `lib/core/models/replace_rule.dart` | `data/entities/ReplaceRule.kt` | 替換規則實體。 |
| `lib/core/models/rss_source.dart` | `data/entities/RssSource.kt` | RSS 訂閱源實體。 |
| `lib/core/models/rss_article.dart` | `data/entities/RssArticle.kt` | RSS 文章實體。 |
| `lib/core/models/bookmark.dart` | `data/entities/Bookmark.kt` | 閱讀書籤實體。 |
| `lib/core/models/book_group.dart` | `data/entities/BookGroup.kt` | 書籍分組實體。 |
| `lib/core/models/cache.dart` | `data/entities/Cache.kt` | 網路/其他快取實體。 |
| `lib/core/models/cookie.dart` | `data/entities/Cookie.kt` | 儲存登入憑證實體。 |
| `lib/core/models/dict_rule.dart` | `data/entities/DictRule.kt` | 字典規則實體。 |
| `lib/core/models/http_tts.dart` | `data/entities/HttpTTS.kt` | 網路 TTS 引擎實體。 |
| `lib/core/models/keyboard_assist.dart` | `data/entities/KeyboardAssist.kt` | 鍵盤輔助實體。 |
| `lib/core/models/read_record.dart` | `data/entities/ReadRecord.kt` | 閱讀統計實體。 |
| `lib/core/models/rss_read_record.dart` | `data/entities/RssReadRecord.kt` | RSS 閱讀紀錄實體。 |
| `lib/core/models/rss_star.dart` | `data/entities/RssStar.kt` | RSS 收藏實體。 |
| `lib/core/models/rule_data_interface.dart` | `data/entities/RuleDataInterface.kt` | 規則資料共用介面。 |
| `lib/core/models/rule_sub.dart` | `data/entities/RuleSub.kt` | 規則訂閱實體。 |
| `lib/core/models/search_keyword.dart` | `data/entities/SearchKeyword.kt` | 搜尋關鍵字實體。 |
| `lib/core/models/server.dart` | `data/entities/Server.kt` | Web 伺服器設定實體。 |
| `lib/core/models/txt_toc_rule.dart` | `data/entities/TxtTocRule.kt` | TXT 目錄規則實體。 |

---

## 4. 解析引擎與 JS 橋接 (Engine & Parsers)

iOS 版本使用 `xpath_selector`、`json_path` 與 `flutter_js` 完全重寫了 Android 的 Rhino/Jsoup 邏輯。

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/core/engine/analyze_rule.dart` | `model/analyzeRule/AnalyzeRule.kt` | 規則解析總控器 (分發給 Regex, XPath, JsonPath, CSS)。 |
| `lib/core/engine/analyze_url.dart` | `model/analyzeRule/AnalyzeUrl.kt` | 動態 URL 解析 (處理分頁、JS 標籤、POST 參數)。 |
| `lib/core/engine/rule_analyzer.dart` | `model/analyzeRule/...` | 輔助的字串處理與規則切分工具。 |
| `lib/core/engine/parsers/analyze_by_css.dart`| `model/analyzeRule/AnalyzeByJsoup.kt` | 基於 CSS Selector 提取資料。 |
| `lib/core/engine/parsers/analyze_by_json_path.dart`| `model/analyzeRule/AnalyzeByJsonPath.kt`| 基於 JsonPath 提取 API 資料。 |
| `lib/core/engine/parsers/analyze_by_regex.dart`| `model/analyzeRule/AnalyzeByRegex.kt` | 基於正規表達式提取資料。 |
| `lib/core/engine/parsers/analyze_by_xpath.dart`| `model/analyzeRule/AnalyzeByXPath.kt` | 基於 XPath 提取資料。 |
| `lib/core/engine/js/js_engine.dart` | `help/JsExtensions.kt` (Rhino) | JavaScript 引擎封裝，用於執行 `@js:` 規則。 |
| `lib/core/engine/js/js_extensions.dart` | `help/JsExtensions.kt` | JS 到 Dart 的原生方法映射 (如 `java.ajax`, `java.t2s`)。 |
| `lib/core/engine/js/js_encode_utils.dart` | `utils/EncoderUtils.kt` | JS 可呼叫的 Base64/MD5/URL 編碼工具。 |
| `lib/core/engine/js/shared_js_scope.dart` | 引擎上下文管理 | 管理全域變數注入。 |
| `lib/core/engine/js/query_ttf.dart` | 處理特殊字體反爬機制 | 針對起點等平台自訂字體反爬的解析處理。 |

---

## 5. 核心服務 (Services / Helpers)

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/core/services/book_source_service.dart`| `model/webBook/WebBook.kt` | 處理書源的網路搜尋、詳情獲取、目錄獲取與正文獲取。 |
| `lib/core/services/http_client.dart` | `help/http/Res.kt` / Retrofit | 全域 HTTP 客戶端 (Dio)，處理 Header、Charset 與請求重試。 |
| `lib/core/services/cookie_store.dart` | `help/http/CookieStore.kt` | 攔截與儲存/提供登入狀態的 Cookie。 |
| `lib/core/services/content_processor.dart`| `help/book/ContentProcessor.kt` | 正文處理：排版、段落整理、替換規則應用與繁簡轉換。 |
| `lib/core/services/chinese_utils.dart` | `utils/ChineseUtils.kt` | 繁簡轉換器 (內建高頻字對照表)。 |
| `lib/core/services/download_service.dart` | `service/DownloadService.kt` | 背景章節批量下載服務。 |
| `lib/core/services/cache_manager.dart` | `help/book/BookHelp.kt` (部分) | 快取生命週期管理。 |
| `lib/core/services/check_source_service.dart`| `service/CheckSourceService.kt` | 書源可用性與速度校驗服務。 |
| `lib/core/services/export_book_service.dart`| `service/ExportBookService.kt` | 快取書籍匯出為 TXT 並分享的服務。 |
| `lib/core/services/backstage_webview.dart`| `service/BaseWebView.kt` | 無頭瀏覽器，處理需 JS 渲染或 Cloudflare 驗證的網頁。 |
| `lib/core/services/webdav_service.dart` | `help/storage/WebDavHelp.kt` | WebDAV 備份與還原服務。 |
| `lib/core/services/tts_service.dart` | `service/ReadAloudService.kt` | 系統原生 TTS (Text-to-Speech) 朗讀服務。 |
| `lib/core/services/audio_play_service.dart`| `service/AudioPlayService.kt` | 音頻書籍/有聲書的播放服務 (`just_audio`)。 |
| `lib/core/services/http_tts_service.dart` | `service/HttpReadAloudService.kt`| 第三方線上 HTTP API 語音合成服務。 |
| `lib/core/services/rss_parser.dart` | `model/rss/RssParser*.kt` | RSS 與 Atom 訂閱源的 XML/規則解析器。 |
| `lib/core/services/dictionary_service.dart`| `ui/dict/DictDialog.kt` | 文字長按查詞與字典整合。 |
| `lib/core/services/default_data.dart` | `help/DefaultData.kt` | App 首次啟動時預設書源、規則的載入器。 |
| `lib/core/services/rate_limiter.dart` | 請求頻率限制工具 | 控制高併發請求，避免 IP 被封鎖。 |

---

## 6. 本地書籍解析 (Local Book Parsers)

| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/core/local_book/txt_parser.dart` | `model/localBook/TextFile.kt` | 解析 TXT 檔案，支援正則匹配章節與 GBK 編碼自動識別。 |
| `lib/core/local_book/epub_parser.dart` | `model/localBook/EpubFile.kt` | 解析 EPUB 檔案，提取 TOC、正文 HTML 與封面圖。 |

---

## 7. UI 層與功能模組 (Features)

iOS 使用 `Provider` 進行狀態管理，Android 則使用 `ViewModel` / `LiveData` (或 Flow)。

### 書架 (Bookshelf)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/bookshelf/bookshelf_page.dart` | `ui/main/bookshelf/BookshelfFragment.kt`| 書架列表 UI，支援宮格與列表模式。 |
| `lib/features/bookshelf/bookshelf_provider.dart`| `ui/main/bookshelf/BookshelfViewModel.kt`| 書架資料加載、書籍刪除、置頂與分組切換。 |
| `lib/features/local_book/local_book_provider.dart`| `ui/file/FilePickerViewModel.kt` (部分)| 本地 TXT/EPUB 匯入並寫入書架的控制器。 |

### 發現/書城 (Explore)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/explore/explore_page.dart` | `ui/main/explore/ExploreFragment.kt` | 發現頁面，呈現支援探索規則的書源分類。 |
| `lib/features/explore/explore_provider.dart` | `ui/main/explore/ExploreViewModel.kt` | 發現頁資料請求與列表分頁加載。 |

### 書源管理 (Source Manager)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/source_manager/source_manager_page.dart`| `ui/book/source/manage/BookSourceActivity.kt`| 書源列表，支援匯入、匯出、刪除、批量操作。 |
| `lib/features/source_manager/source_manager_provider.dart`| `ui/book/source/manage/BookSourceViewModel.kt`| 書源管理業務邏輯與校驗分發。 |
| `lib/features/source_manager/source_editor_page.dart`| `ui/book/source/edit/BookSourceEditActivity.kt`| 書源編輯器 (表單/JSON 雙模式)。 |
| `lib/features/source_manager/source_login_page.dart`| `ui/login/LoginActivity.kt` | 書源登入 WebView 攔截器。 |
| `lib/features/source_manager/qr_scan_page.dart` | `ui/qrcode/QrCodeActivity.kt` | 掃描 QR Code 直接匯入書源 JSON。 |

### 網路搜尋 (Search)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/search/search_page.dart` | `ui/book/search/SearchActivity.kt` | 全網搜尋輸入介面與結果呈現。 |
| `lib/features/search/search_provider.dart` | `ui/book/search/SearchViewModel.kt` | 多書源併發搜尋引擎與結果聚合。 |

### 書籍詳情與換源 (Book Detail)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/book_detail/book_detail_page.dart` | `ui/book/info/BookInfoActivity.kt` | 書籍封面、簡介、目錄預覽與操作按鈕。 |
| `lib/features/book_detail/book_detail_provider.dart`| `ui/book/info/BookInfoViewModel.kt`| 詳情獲取與目錄刷新邏輯。 |
| *(整合在 Page 內)* | `ui/book/changesource/ChangeSourceDialog.kt`| 精確搜尋同名書籍以進行換源。 |
| *(整合在 Page 內)* | `ui/book/changecover/ChangeCoverDialog.kt`| 長按封面進行封面圖片替換。 |

### 閱讀器核心 (Reader Engine)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/reader/reader_page.dart` | `ui/book/read/ReadBookActivity.kt` | 閱讀器主 UI，包含頂部與底部操作面板。 |
| `lib/features/reader/reader_provider.dart` | `ui/book/read/ReadBookViewModel.kt` | 閱讀狀態、字體/主題設定、上下章加載控制器。 |
| `lib/features/reader/engine/chapter_provider.dart`| `ui/book/read/page/provider/ChapterProvider.kt`| 文字排版與分頁算法引擎 (極重要核心)。 |
| `lib/features/reader/engine/page_view_widget.dart`| `ui/book/read/page/ContentTextView.kt`| 基於 CustomPainter 繪製文字與進度頁首/尾。 |
| `lib/features/reader/engine/text_page.dart` | `ui/book/read/page/entities/TextPage.kt`| 單頁文字模型資料。 |
| `lib/features/reader/manga_reader_page.dart` | `ui/book/manga/MangaReadActivity.kt`| 圖片串列與縮放支援的漫畫閱讀器。 |
| `lib/features/reader/audio_player_page.dart` | `ui/book/audio/AudioPlayActivity.kt`| 支援背景播放與進度控制的有聲書播放器。 |
| `lib/features/replace_rule/replace_rule_page.dart`| `ui/replace/edit/ReplaceEditActivity.kt`| 正文替換淨化規則管理器。 |
| `lib/features/replace_rule/replace_rule_provider.dart`| `ui/replace/ReplaceRuleViewModel.kt`| 淨化規則的 CRUD。 |

### 快取管理 (Cache Manager)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/cache_manager/cache_manager_page.dart`| `ui/book/cache/CacheActivity.kt` | 顯示書籍快取狀態，提供批量下載與刪除。 |
| `lib/features/cache_manager/cache_manager_provider.dart`| `ui/book/cache/CacheViewModel.kt` | 快取清單管理與下載服務調用。 |

### RSS 訂閱 (RSS/Feeds)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/rss/rss_source_page.dart` | `ui/rss/source/manage/RssSourceActivity.kt`| RSS 訂閱來源管理頁面。 |
| `lib/features/rss/rss_source_provider.dart` | `ui/rss/source/manage/RssSourceViewModel.kt`| RSS 來源狀態維護。 |
| `lib/features/rss/rss_source_editor_page.dart` | `ui/rss/source/edit/RssSourceEditActivity.kt`| RSS 自訂規則編輯器。 |
| `lib/features/rss/rss_article_page.dart` | `ui/rss/article/RssArticlesActivity.kt`| 某一 RSS 來源的文章清單頁面。 |
| `lib/features/rss/rss_article_provider.dart` | `ui/rss/article/RssArticlesViewModel.kt`| RSS 文章解析與分頁控制器。 |
| `lib/features/rss/rss_read_page.dart` | `ui/rss/read/RssReadActivity.kt` | RSS 文章內文閱讀 (WebView 模式或規則提取)。 |

### 設定與偏好 (Settings)
| iOS (Flutter) 路徑 | Android (Legado) 對應路徑 | 說明 |
| :--- | :--- | :--- |
| `lib/features/settings/settings_page.dart` | `ui/config/ConfigActivity.kt` | 應用程式整體設定 (主題、備份、關於)。 |
| `lib/features/settings/settings_provider.dart` | `help/config/AppConfig.kt` | 全域偏好設定持久化與 WebDAV 同步中心。 |
| `lib/features/settings/font_manager_page.dart` | `ui/font/FontActivity.kt` | 系統字體切換與本地 TTF/OTF 載入器。 |

---

## 總結
目前 iOS `legado_reader` 專案已經以極高的完成度重現了 Android 原版 Legado 的核心功能。其檔案結構嚴格遵循領域驅動設計 (Domain-Driven Design)，並針對 Flutter 平台的特性（如 `sqflite` 資料庫、`CustomPainter` 排版、`Provider` 狀態管理）進行了最佳化適配，是一個成熟且功能完整的跨平台閱讀器核心。