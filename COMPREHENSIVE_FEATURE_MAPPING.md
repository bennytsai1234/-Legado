# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping)
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/constant

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConst.kt` | 全域常數、支援格式、超時設定 | `lib/core/constant/app_const.dart` | ✅ Matched |
| `AppLog.kt` | 紀錄層級、日誌相關標記 | `lib/core/services/app_log_service.dart` | ✅ Matched |
| `AppPattern.kt` | 正規表達式模式定義 | `lib/core/constant/app_pattern.dart` | ✅ Matched |
| `BookSourceType.kt` | 書源類型列舉 | `lib/core/constant/book_type.dart` | ✅ Matched |
| `BookType.kt` | 書籍類型 (位元運算) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `PageAnim.kt` | 翻頁動畫類型定義 | `lib/core/constant/page_anim.dart` | ✅ Matched |
| `PreferKey.kt" | SharedPreferences 鍵名 | `lib/core/constant/prefer_key.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/exception

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `*Exception.kt` | 各類業務自定義異常 | `lib/core/exception/app_exception.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ACache.kt` | 磁碟快取工具 | `lib/core/storage/app_cache.dart` | ✅ Matched |
| `AlphanumComparator.kt` | 檔名自然排序 | `lib/core/utils/alphanum_comparator.dart` | ✅ Matched |
| `ArchiveUtils.kt` | 壓縮擋 (ZIP/7z) 處理 | `lib/core/utils/archive_utils.dart` | ✅ Matched |
| `ChineseUtils.kt" | 繁簡轉換工具 | `lib/core/services/chinese_utils.dart` | ✅ Matched |
| `ColorUtils.kt" | 顏色解析與轉換 | `lib/core/utils/color_utils.dart` | ✅ Matched |
| `EncoderUtils.kt" | 編碼 (Base64/MD5) | `lib/core/utils/encoder_utils.dart` | ✅ Matched |
| `EncodingDetect.kt" | 文件編碼偵測 | `lib/core/services/encoding_detect.dart` | ✅ Matched |
| `FileDocExtensions.kt" | SAF 虛擬文件管理 | `lib/core/storage/file_doc.dart` | ✅ Matched |
| `FileUtils.kt" | 基礎檔案操作 | `lib/core/utils/file_utils.dart` | ✅ Matched |
| `HtmlFormatter.kt" | HTML 內容格式化 | `lib/core/utils/html_formatter.dart` | ✅ Matched |
| `NetworkUtils.kt" | 網路狀態、UA 管理 | `lib/core/utils/network_utils.dart` | ✅ Matched |
| `StringUtils.kt" | 字串處理擴展 | `lib/core/utils/string_utils.dart` | ✅ Matched |
| `TimeUtils.kt" | 時間格式化 | `lib/core/utils/time_utils.dart` | ✅ Matched |
| `UrlUtil.kt" | URL 解析與合併 | `lib/core/utils/url_util.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/help

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppWebDav.kt` | WebDAV 同步服務 | `lib/core/services/webdav_service.dart` | ✅ Matched |
| `CacheManager.kt` | 雙層快取管理 (記憶體+磁碟) | `lib/core/services/cache_manager.dart` | ✅ Matched |
| `ConcurrentRateLimiter.kt` | 併發頻率限制 | `lib/core/services/rate_limiter.dart` | ✅ Matched |
| `CrashHandler.kt` | 異常捕獲與設備資訊收集 | `lib/core/services/crash_handler.dart` | ✅ Matched |
| `DefaultData.kt` | 預設資料 (Assets JSON) 載入 | `lib/core/services/default_data.dart` | ✅ Matched |
| `EventMessage.kt" | 事件總線訊息定義 | `lib/core/services/event_bus.dart` | ✅ Matched |
| `JsEncodeUtils.kt" | JS 加密工具 | `lib/core/engine/js/js_encode_utils.dart` | ✅ Matched |
| `JsExtensions.kt" | JS 引擎全域擴展 | `lib/core/engine/js/js_extensions.dart` | ✅ Matched |
| `MediaHelp.kt" | 音訊焦點與控制 | `lib/core/services/audio_play_service.dart` | ✅ Matched |
| `ReplaceAnalyzer.kt" | 替換規則 JSON 解析 | `lib/core/models/replace_rule.dart` | ✅ Matched |
| `TTS.kt" | 語音合成 (TTS) 封裝 | `lib/core/services/tts_service.dart` | ✅ Matched |

### 📂 子資料夾：help/config (配置管理)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConfig.kt` | 全域應用程式配置管理 | `lib/core/constant/prefer_key.dart` | ✅ Matched |
| `ReadBookConfig.kt` | 閱讀器排版配置 (動態 JSON) | `lib/shared/theme/app_theme.dart` | ✅ Matched |
| `ThemeConfig.kt` | 主題色彩配置 | `lib/shared/theme/app_theme.dart` | ✅ Matched |

### 📂 子資料夾：help/book (書籍處理)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ContentProcessor.kt` | 正文清理與 reSegment 演算法 | `lib/core/services/content_processor.dart` | ✅ Matched |
| `ContentHelp.kt" | 內容抓取輔助工具 | `lib/core/services/content_processor.dart` | ✅ Matched |
| `BookHelp.kt" | 書籍管理、路徑獲取 | `lib/core/services/download_service.dart` | ⚠️ Partial |

### 📂 子資料夾：help/update (自動更新)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppUpdateGitHub.kt` | GitHub Releases 更新檢查 | `lib/core/services/update_service.dart` | ✅ Matched |
| `AppUpdate.kt" | 更新介面定義 | `lib/core/services/update_service.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/data/entities

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `Book.kt` | 書籍資訊實體 | `lib/core/models/book.dart` | ✅ Matched |
| `BookSource.kt` | 書源規則實體 | `lib/core/models/book_source.dart` | ✅ Matched |
| `BookChapter.kt` | 章節資訊實體 | `lib/core/models/chapter.dart` | ✅ Matched |
| `ReplaceRule.kt" | 替換規則實體 | `lib/core/models/replace_rule.dart` | ✅ Matched |
| `RssSource.kt" | RSS 訂閱源實體 | `lib/core/models/rss_source.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/model

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AudioPlay.kt` | 音頻播放總控 | `lib/core/services/audio_play_service.dart` | ✅ Matched |
| `CacheBook.kt` | 書籍快取任務管理 | `lib/core/services/download_service.dart` | ✅ Matched |
| `ReadAloud.kt" | 朗讀狀態與調度 | `lib/core/services/tts_service.dart` | ✅ Matched |
| `ReadBook.kt" | 閱讀器核心狀態管理 | `lib/features/reader/reader_provider.dart` | ✅ Matched |
| `SharedJsScope.kt" | JS 執行環境共用變數 | `lib/core/engine/js/shared_js_scope.dart` | ✅ Matched |

### 📂 子資料夾：model/analyzeRule (解析引擎)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AnalyzeRule.kt` | 規則解析核心總控 | `lib/core/engine/analyze_rule.dart` | ✅ Matched |
| `AnalyzeUrl.kt` | 動態 URL 解析 (含 JS) | `lib/core/engine/analyze_url.dart` | ✅ Matched |
| `AnalyzeBy*` | 各類解析實作 (CSS/JSON/XPath) | `lib/core/engine/parsers/*` | ✅ Matched |
| `QueryTTF.java` | 字體輪廓資料解析 | `lib/core/engine/js/query_ttf.dart` | ✅ Matched |

### 📂 子資料夾：model/localBook (本地書籍)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `EpubFile.kt` | EPUB 格式解析 | `lib/core/local_book/epub_parser.dart` | ✅ Matched |
| `TextFile.kt" | TXT 分章解析 | `lib/core/local_book/txt_parser.dart` | ✅ Matched |
| `UmdFile.kt" | UMD 格式解析 | `lib/core/local_book/umd_parser.dart` | ✅ Matched |

### 📂 子資料夾：model/webBook (網路書籍)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `WebBook.kt` | 網路請求與解析業務發起 | `lib/core/engine/book_source_engine.dart` | ✅ Matched |
| `SearchModel.kt" | 併發搜尋調度 | `lib/core/services/book_source_service.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/service

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AudioPlayService.kt` | 聽書前景服務 | `lib/core/services/audio_play_service.dart` | ✅ Matched |
| `CacheBookService.kt` | 章節離線快取服務 | `lib/core/services/download_service.dart` | ✅ Matched |
| `DownloadService.kt" | 單一檔案下載服務 | `lib/core/services/download_service.dart` | ✅ Matched |
| `ExportBookService.kt" | 書籍匯出 (TXT) 服務 | `lib/core/services/export_book_service.dart` | ✅ Matched |
| `WebService.kt" | 本地管理介面伺服器 | `lib/core/services/web_service.dart` | ✅ Matched |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/ui

### 📍 ui/main (主介面)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `bookshelf/*` | 書架、分組、書籍卡片 | `lib/features/bookshelf` | ✅ Matched |
| `explore/*` | 發現頁、分源瀏覽 | `lib/features/explore` | ✅ Matched |

### 📍 ui/book/read/page (閱讀渲染)
| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ChapterProvider.kt` | 分頁與排版演算法 | `lib/features/reader/engine/chapter_provider.dart` | ✅ Matched |
| `PageView.kt" | 手勢與頁面容器 | `lib/features/reader/engine/page_view_model.dart` | ✅ Matched |
| `SimulationPageDelegate.kt" | 仿真翻頁動畫 | `lib/features/reader/engine/simulation_page_anim.dart` | ✅ Matched |

---

## 遞迴進度回報
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [x] `help`
- [x] `data/entities`
- [x] `model`
- [x] `service`
- [x] `ui`

✅ **100% 遞迴映射完成**
