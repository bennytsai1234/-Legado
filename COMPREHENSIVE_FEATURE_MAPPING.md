# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping)
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/constant

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConst.kt` | 全域常數、支援格式、超時設定 | `lib/core/constant/app_const.dart` | ✅ Matched |
| `AppLog.kt` | 紀錄層級、日誌相關標記 | `lib/core/services/app_log_service.dart` | ✅ Matched |
| `AppPattern.kt` | 正規表達式模式定義 (日期、URL 等) | `lib/core/constant/app_pattern.dart` | ✅ Matched |
| `BookSourceType.kt` | 書源類型列舉 (文字、音訊等) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `BookType.kt` | 書籍類型 (本地、網路等) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `EventBus.kt` | 事件總線標記 (雖然 Flutter 多用 Stream) | - (使用 Stream 替代) | ✅ Matched |
| `IntentAction.kt` | Android Intent 動作定義 | - (系統特有) | ✅ Matched |
| `NotificationId.kt` | 通知 ID 定義 | - (系統特有) | ✅ Matched |
| `PageAnim.kt` | 翻頁動畫類型 | `lib/core/constant/page_anim.dart` | ✅ Matched |
| `PreferKey.kt` | SharedPreferences 鍵名定義 | `lib/core/constant/prefer_key.dart` | ✅ Matched |
| `SourceType.kt` | 來源類型 (書源、RSS) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `Status.kt` | 下載或同步狀態 | `lib/core/constant/app_const.dart` | ✅ Matched |
| `Theme.kt` | 主題相關常數 | `lib/core/constant/app_const.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/exception

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ConcurrentException.kt` | 併發衝突異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `ContentEmptyException.kt` | 內容為空異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `EmptyFileException.kt` | 檔案為空異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `InvalidBooksDirException.kt` | 書籍目錄無效異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `NoBooksDirException.kt` | 書籍目錄不存在異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `NoStackTraceException.kt` | 無堆疊軌跡異常基類 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `RegexTimeoutException.kt` | 正則匹配超時異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |
| `TocEmptyException.kt` | 目錄為空異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ACache.kt` | 磁碟緩存工具 | `lib/core/storage/app_cache.dart` | ✅ Matched |
| `AlphanumComparator.kt` | 檔名/章節號自然排序 | `lib/core/utils/alphanum_comparator.dart` | ✅ Matched |
| `ActivityExtensions.kt` | Activity 視窗與 UI 擴展 | `Flutter Framework` (Navigator/MediaQuery) | ✅ Absorbed |
| `ArchiveUtils.kt` | 壓縮擋 (ZIP/7z) 處理 | `lib/core/utils/archive_utils.dart` | ✅ Matched |
| `BitmapUtils.kt` / `ImageUtils.kt` | 圖片處理、縮放、裁剪 | `flutter_image_compress` / `package:image` | ⚠️ Plugin |
| `ChineseUtils.kt` | 繁簡轉換 | `lib/core/services/chinese_utils.dart` | ✅ Matched |
| `ColorUtils.kt` | 顏色解析、轉換 | `lib/core/utils/color_utils.dart` | ✅ Matched |
| `ContextExtensions.kt` | Context 相關 (螢幕、權限、路徑) | `MediaQuery` / `path_provider` / `share_plus` | ✅ Absorbed |
| `CookieManagerExtensions.kt` | Cookie 獲取與儲存 | `dio_cookie_manager` | ⚠️ Plugin |
| `EncoderUtils.kt` / `MD5Utils.kt` | 編碼 (Base64/MD5) | `lib/core/utils/encoder_utils.dart` | ✅ Matched |
| `EncodingDetect.kt` | 文件編碼自動偵測 | `lib/core/services/encoding_detect.dart` | ✅ Matched |
| `FileDocExtensions.kt` | 虛擬文件管理 (SAF) | `lib/core/storage/file_doc.dart` | ✅ Matched |
| `FileUtils.kt` | 基礎檔案操作 | `lib/core/utils/file_utils.dart` | ✅ Matched |
| `GsonExtensions.kt` / `JsonExtensions.kt` | JSON 解析封裝 | `dart:convert` (內建) | ✅ Matched |
| `HtmlFormatter.kt` / `JsoupExtensions.kt` | HTML 內容清理與格式化 | `lib/core/utils/html_formatter.dart` & `html_utils.dart` | ✅ Matched |
| `NetworkUtils.kt` | 代理、UA、網路狀態檢查 | `lib/core/utils/network_utils.dart` | ✅ Matched |
| `QRCodeUtils.kt` | 二維碼生成與識別 | `qr_flutter` / `mobile_scanner` | ⚠️ Plugin |
| `StringUtils.kt` / `StringExtensions.kt` | 字串處理、格式檢查 | `lib/core/utils/string_utils.dart` | ✅ Matched |
| `TimeUtils.kt` | 時間格式化、時差計算 | `lib/core/utils/time_utils.dart` | ✅ Matched |
| `ToastUtils.kt` / `Snackbars.kt` | 提示訊息 UI | `ScaffoldMessenger` / `oktoast` | ✅ Absorbed |
| `UriExtensions.kt` / `UrlUtil.kt` | URL 解析、編碼、合併 | `lib/core/utils/url_util.dart` | ✅ Matched |
| `*Extensions.kt` (其他 40+ 檔案) | Android SDK 特有的擴展方法 | `Flutter/Dart 內建` | ✅ Absorbed |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils/compress

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ZipUtils.kt` | ZIP 壓縮與解壓 | `lib/core/utils/archive_utils.dart` | ✅ Matched |
| `LibArchiveUtils.kt` | 高級壓縮格式 (7z/RAR) | `lib/core/utils/archive_utils.dart` | ⚠️ Partial |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/help

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppWebDav.kt` | WebDAV 備份與同步服務 | `lib/core/services/webdav_service.dart` | ✅ Matched |
| `CacheManager.kt` | 全域快取生命週期管理 (記憶體+磁碟) | `lib/core/services/cache_manager.dart` | ⚠️ Partial |
| `ConcurrentRateLimiter.kt` | 併發頻率限制工具 | `lib/core/services/rate_limiter.dart` | ✅ Matched |
| `CrashHandler.kt` | 全域異常捕獲與日誌記錄 | `lib/core/services/crash_handler.dart` | ⚠️ Partial |
| `DefaultData.kt` | 預設書源、語音、規則初始化 | `lib/core/services/default_data.dart` | ⚠️ Partial |
| `EventMessage.kt` | 事件總線訊息定義 | `lib/core/services/event_bus.dart` | ✅ Matched |
| `JsEncodeUtils.kt` | JS 內的編碼加密工具 (AES/DES/MD5) | `lib/core/engine/js/js_encode_utils.dart` | ✅ Matched |
| `JsExtensions.kt` | JS 環境中的全域方法擴展 (Ajax/WebView) | `lib/core/engine/js/js_extensions.dart` | ✅ Matched |
| `LauncherIconHelp.kt` | 動態更換應用程式圖示 | - | ❌ Missing |
| `LifecycleHelp.kt` | 生命週期監聽 | `WidgetsBindingObserver` | ✅ Absorbed |
| `MediaHelp.kt` | 音頻播放與多媒體控制 | `lib/core/services/audio_play_service.dart` | ✅ Matched |
| `ReplaceAnalyzer.kt` | 替換規則 JSON 解析與校驗 | `lib/core/models/replace_rule.dart` | ✅ Matched |
| `TTS.kt` | 語音合成 (TTS) 封裝 | `lib/core/services/tts_service.dart` | ✅ Matched |
| `RuleComplete.kt" | 規則完整性校驗 | - | ❌ Missing |

### 📂 子資料夾：help/config (配置管理)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConfig.kt` | 全域應用程式配置管理 | `lib/core/constant/prefer_key.dart` | ✅ Matched |
| `ReadBookConfig.kt` | 閱讀器專屬配置 (字體、間距等) | - | ❌ Missing |
| `ThemeConfig.kt` | 主題色彩配置 | - | ❌ Missing |
| `LocalConfig.kt" | 本地運行狀態配置 | - | ❌ Missing |

### 📂 子資料夾：help/book (書籍邏輯)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ContentProcessor.kt` | 正文清理與排版預處理 | `lib/core/services/content_processor.dart` | ✅ Matched |
| `ContentHelp.kt` | 內容抓取輔助工具 | `lib/core/services/content_processor.dart` | ✅ Matched |
| `BookHelp.kt` | 書籍管理、路徑獲取、快取清理 | `lib/core/services/download_service.dart` | ⚠️ Partial |
| `BookContent.kt" | 本地書籍內容讀取 | `lib/core/local_book/*` | ✅ Matched |

### 📂 子資料夾：help/http (網路協定)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `HttpHelper.kt` | OKHttp 封裝與請求輔助 | `lib/core/services/http_client.dart` | ✅ Matched |
| `CookieStore.kt` | Cookie 持久化儲存 | `lib/core/services/cookie_store.dart` | ✅ Matched |
| `BackstageWebView.kt` | 背景 WebView 解析服務 | `lib/core/services/backstage_webview.dart` | ✅ Matched |
| `SSLHelper.kt` | 證書校驗與 HTTPS 處理 | `lib/core/services/http_client.dart` | ✅ Matched |
| `Cronet.kt" | Google Cronet 引擎整合 | `lib/core/services/http_client.dart` | ✅ Absorbed |

### 📂 子資料夾：help/source (書源輔助)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `SourceHelp.kt` | 書源導入、排序、群組管理 | `lib/core/services/book_source_service.dart` | ✅ Matched |
| `SourceVerificationHelp.kt` | 書源驗證與瀏覽器互動 (Captcha) | `lib/core/services/source_verification_service.dart` | ✅ Matched |
| `BookSourceExtensions.kt" | 書源相關擴展方法 | - | ❌ Missing |

### 📂 子資料夾：help/storage (備份還原)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `BackupAES.kt` | 加密備份實作 | `lib/core/services/backup_aes_service.dart` | ✅ Matched |
| `Restore.kt` | 備份還原邏輯 | `lib/core/services/restore_service.dart` | ✅ Matched |
| `Backup.kt" | 基礎備份邏輯 | `lib/core/services/backup_aes_service.dart` | ⚠️ Partial |

### 📂 子資料夾：help/update (自動更新)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppUpdateGitHub.kt` | GitHub Releases 自動更新檢查 | - | ❌ Missing |
| `AppUpdate.kt" | 更新介面定義 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/data/entities (對標 iOS models)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `Book.kt` | 書籍資訊實體 | `lib/core/models/book.dart` | ✅ Matched |
| `BookSource.kt` | 書源規則實體 | `lib/core/models/book_source.dart` | ✅ Matched |
| `BookChapter.kt` | 章節資訊實體 | `lib/core/models/chapter.dart` | ✅ Matched |
| `BookGroup.kt` | 書籍分組實體 | `lib/core/models/book_group.dart` | ✅ Matched |
| `Bookmark.kt` | 書籤實體 | `lib/core/models/bookmark.dart` | ✅ Matched |
| `HttpTTS.kt` | 自定義 TTS 引擎實體 | `lib/core/models/http_tts.dart` | ✅ Matched |
| `ReplaceRule.kt` | 內容替換規則實體 | `lib/core/models/replace_rule.dart` | ✅ Matched |
| `RssSource.kt` | RSS 訂閱源實體 | `lib/core/models/rss_source.dart` | ✅ Matched |
| `SearchBook.kt` | 搜尋結果書籍實體 | `lib/core/models/search_book.dart` | ✅ Matched |
| `TxtTocRule.kt` | 本地書目錄規則實體 | `lib/core/models/txt_toc_rule.dart` | ✅ Matched |
| `Base*` / `Rss*` (其餘 15+) | 其他輔助與 RSS 相關實體 | `lib/core/models/*.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/model (業務邏輯)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AudioPlay.kt` | 音頻播放總控 (聽書) | `lib/core/services/audio_play_service.dart` | ✅ Matched |
| `BookCover.kt` | 書籍封面獲取與預設封面生成 | `lib/core/services/image_loader.dart` | ⚠️ Partial |
| `CacheBook.kt` | 多執行緒書籍快取管理 | `lib/core/services/download_service.dart` | ✅ Matched |
| `CheckSource.kt` | 書源可用性效能測試 | `lib/core/services/check_source_service.dart` | ✅ Matched |
| `Debug.kt` | 書源解析日誌收集與調試 | `lib/features/debug/debug_page.dart` | ⚠️ Partial |
| `Download.kt` | 背景下載任務發起 | `lib/core/services/download_service.dart` | ✅ Matched |
| `ReadAloud.kt` | 朗讀狀態與語音調度 | `lib/core/services/tts_service.dart` | ✅ Matched |
| `ReadBook.kt` | 閱讀器核心狀態管理 (進度、頁面、章節) | `lib/features/reader/reader_provider.dart` | ✅ Matched |
| `ReadManga.kt` | 漫畫閱讀器核心邏輯 | `lib/features/reader/manga_reader_page.dart` | ⚠️ Partial |
| `SharedJsScope.kt` | JS 執行環境共用變數 | `lib/core/engine/js/shared_js_scope.dart` | ✅ Matched |

### 📂 子資料夾：model/analyzeRule (解析引擎)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AnalyzeRule.kt` | 規則解析核心總控 | `lib/core/engine/analyze_rule.dart` | ✅ Matched |
| `AnalyzeUrl.kt` | 動態 URL 解析 (含 JS 執行) | `lib/core/engine/analyze_url.dart` | ✅ Matched |
| `RuleAnalyzer.kt" | 規則文本提取與清理 | `lib/core/engine/rule_analyzer.dart` | ✅ Matched |
| `AnalyzeByJSoup.kt` | CSS 選擇器解析實作 | `lib/core/engine/parsers/analyze_by_css.dart` | ✅ Matched |
| `AnalyzeByJSonPath.kt` | JSONPath 解析實作 | `lib/core/engine/parsers/analyze_by_json_path.dart` | ✅ Matched |
| `AnalyzeByXPath.kt` | XPath 解析實作 | `lib/core/engine/parsers/analyze_by_xpath.dart` | ✅ Matched |
| `AnalyzeByRegex.kt` | 正規表達式解析實作 | `lib/core/engine/parsers/analyze_by_regex.dart` | ✅ Matched |
| `QueryTTF.java` | 字體輪廓資料解析 (用於字體反爬) | `lib/core/engine/js/query_ttf.dart` | ✅ Matched |
| `RuleDataInterface.kt` | 規則資料接口定義 | `lib/core/models/rule_data_interface.dart` | ✅ Matched |

### 📂 子資料夾：model/localBook (本地解析)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `EpubFile.kt` | EPUB 格式解析 | `lib/core/local_book/epub_parser.dart` | ✅ Matched |
| `TextFile.kt` | TXT 格式分章解析 | `lib/core/local_book/txt_parser.dart` | ✅ Matched |
| `UmdFile.kt` | UMD 格式解析 | `lib/core/local_book/umd_parser.dart` | ✅ Matched |
| `MobiFile.kt` | MOBI 格式解析 | - | ❌ Missing |
| `PdfFile.kt` | PDF 格式解析 | - | ❌ Missing |

### 📂 子資料夾：model/rss (RSS 解析)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `Rss.kt` | RSS 解析總控 | `lib/core/services/rss_parser.dart` | ✅ Matched |
| `RssParserByRule.kt` | 自定義規則 RSS 解析 | `lib/core/services/rss_parser.dart` | ✅ Matched |
| `RssParserDefault.kt` | 標準 RSS 協定解析 | `lib/core/services/rss_parser.dart` | ✅ Matched |

### 📂 子資料夾：model/webBook (網路書源)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `WebBook.kt` | 網路書源具體業務發起 (搜尋、目錄、詳情) | `lib/core/engine/book_source_engine.dart` | ✅ Matched |
| `SearchModel.kt` | 多源併發搜尋模型 | `lib/core/services/book_source_service.dart` | ✅ Matched |
| `BookInfo.kt` | 書籍詳情解析封裝 | `lib/core/models/book.dart` | ✅ Matched |
| `BookChapterList.kt" | 章節列表解析封裝 | `lib/core/models/chapter.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/service

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AudioPlayService.kt` | 音頻播放背景服務 (聽書) | - | ❌ Missing |
| `CacheBookService.kt` | 章節離線快取服務 | `lib/core/services/download_service.dart` | ✅ Matched |
| `CheckSourceService.kt` | 書源可用性定期檢查服務 | `lib/core/services/check_source_service.dart` | ✅ Matched |
| `DownloadService.kt` | 檔案/書籍下載管理 | `lib/core/services/download_service.dart` | ✅ Matched |
| `ExportBookService.kt` | 書籍匯出 (EPUB/TXT) 服務 | `lib/core/services/export_book_service.dart` | ✅ Matched |
| `WebService.kt` | 本地 HTTP 伺服器 (用於管理書源/書架) | `lib/core/services/web_service.dart` | ✅ Matched |
| `ReadAloudService.kt` | 朗讀服務 (TTS) | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/ui (UI 功能對位)

| Android 資料夾 | 職責描述 | iOS/Flutter 對位路徑 | 狀態 |
|:---|:---|:---|:---|
| `ui/main` | 主界面、書架、底部導航 | `lib/features/bookshelf` | ✅ Matched |
### 📂 子資料夾：ui/book/read/page (閱讀器渲染引擎)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `PageView.kt` | 頁面容器與手勢處理 | `lib/features/reader/engine/page_view_model.dart` | ✅ Matched |
| `ReadView.kt` | 閱讀介面核心畫布 | `lib/features/reader/reader_page.dart` | ✅ Matched |
| `TextPage.kt` | 單頁排版資料結構 | `lib/features/reader/engine/text_page.dart` | ✅ Matched |
| `TextChapter.kt` | 單章排版資料結構 | `lib/features/reader/engine/chapter_provider.dart` | ✅ Matched |
| `ChapterProvider.kt` | 分頁與排版演算法核心 | `lib/features/reader/engine/chapter_provider.dart` | ✅ Matched |
| `SimulationPageDelegate.kt` | 仿真翻頁動畫實作 | `lib/features/reader/engine/simulation_page_anim.dart` | ✅ Matched |
| `ScrollPageDelegate.kt` | 滾動翻頁動畫實作 | `Flutter ScrollView` | ✅ Absorbed |
| `SlidePageDelegate.kt` | 滑動翻頁動畫實作 | `Flutter PageView` | ✅ Absorbed |
| `TextMeasure.kt` | 文字測量與折行計算 | `TextPainter` (Flutter) | ✅ Absorbed |
| `AutoPager.kt` | 自動翻頁邏輯 | `lib/features/reader/reader_provider.dart` | ✅ Matched |

### 📂 子資料夾：ui/book/audio & ui/book/read/config
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AudioPlayActivity.kt` | 聽書播放介面 | `lib/features/reader/audio_player_page.dart` | ✅ Matched |
| `AutoReadDialog.kt` | 自動翻頁設定對話框 | `lib/features/reader/auto_read_dialog.dart` | ✅ Matched |
| `ClickActionConfigDialog.kt` | 點擊區域行為設定 | `lib/features/reader/click_action_config_dialog.dart` | ✅ Matched |
| `ReadAloudDialog.kt` | 朗讀設定對話框 (TTS) | `lib/features/settings/aloud_settings_page.dart` | ✅ Matched |
| `ui/rss` | RSS 訂閱列表、內容展示 | `lib/features/rss` | ✅ Matched |
| `ui/replace` | 替換規則管理界面 | `lib/features/replace_rule` | ✅ Matched |
| `ui/welcome` | 啟動頁 (Splash Screen) | `lib/features/welcome` | ✅ Matched |
| `ui/about` | 關於頁面、版本資訊 | `lib/features/about` | ✅ Matched |
| `ui/config` | 設置中心、書源管理、分組管理 | `lib/features/settings` & `source_manager` | ✅ Matched |
| `ui/file` | 文件選擇器、本地書匯入 | `lib/features/local_book` | ✅ Matched |
| `ui/browser` | 內建瀏覽器 (用於登入書源) | - | ❌ Missing |
| `ui/qrcode` | 掃描與生成二維碼 | - | ❌ Missing |
| `ui/widget` | 桌面小部件 (Widget) | - | ❌ Missing |
| `ui/login` | 網頁登入 (Cookie 獲取) | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/api (系統端介面)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ReaderProvider.kt` | ContentProvider (跨應用數據共享) | - | ❌ Missing |
| `ShortCuts.kt` | 桌面快捷方式管理 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/base (框架基類)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `BaseActivity.kt` / `BaseFragment.kt` | 通用視窗與片段邏輯 | `lib/core/base/base_provider.dart` | ⚠️ Partial |
| `BaseViewModel.kt` | ViewModel 基礎邏輯 | `lib/core/base/base_provider.dart` | ⚠️ Partial |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/data/dao (資料持久層)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `BookDao.kt` | 書籍資料庫操作 | `lib/core/database/dao/book_dao.dart` | ✅ Matched |
| `BookSourceDao.kt` | 書源資料庫操作 | `lib/core/database/dao/book_source_dao.dart` | ✅ Matched |
| `BookChapterDao.kt` | 章節資料庫操作 | `lib/core/database/dao/chapter_dao.dart` | ✅ Matched |
| `ReplaceRuleDao.kt` | 替換規則資料庫操作 | `lib/core/database/dao/replace_rule_dao.dart` | ✅ Matched |
| `RssSourceDao.kt` | RSS 源資料庫操作 | `lib/core/database/dao/rss_source_dao.dart` | ✅ Matched |
| `*Dao.kt` (其餘 15+) | 其他實體資料庫操作 | `lib/core/database/dao/*.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/receiver (廣播接收器)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `MediaButtonReceiver.kt` | 耳機鍵/媒體鍵監聽 (聽書切換) | - | ❌ Missing |
| `NetworkChangedListener.kt` | 網路狀態變化監聽 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/web (內置服務端)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `HttpServer.kt` | NanoHTTPD 伺服器核心 | `lib/core/services/web_service.dart` | ✅ Matched |
| `WebSocketServer.kt` | 雙向通信服務 (日誌/同步) | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/modules (核心模組對位)

| Android 模組 | 職責描述 | iOS/Flutter 對位路徑 | 狀態 |
|:---|:---|:---|:---|
| `modules/book` | 各類電子書格式解析 (EPUB, UMD, TXT) | `lib/core/local_book` | ✅ Matched |
| `modules/rhino` | Rhino JS 引擎封裝與橋接 | `lib/core/engine/js` | ⚠️ Partial |
| `modules/web` | **Web 管理介面 (Vue.js 原始碼)** | - (iOS 端並無此管理介面) | ❌ Missing |

---

## 遞迴進度回報
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [x] `help`
- [x] `model`
- [x] `data` (entities)
- [x] `service`
- [x] `ui`
- [x] `modules`

✅ **100% 遞迴映射完成**
