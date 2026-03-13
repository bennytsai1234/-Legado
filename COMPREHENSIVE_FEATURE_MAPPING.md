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
| `ACache.kt` | 磁碟緩存工具 | - | ❌ Missing |
| `ActivityExtensions.kt` | Activity 視窗與 UI 擴展 | - | ❌ Missing |
| `ArchiveUtils.kt` | 壓縮擋 (ZIP/7z) 處理 | - | ❌ Missing |
| `BitmapUtils.kt` / `ImageUtils.kt` | 圖片處理、縮放、裁剪 | - | ❌ Missing |
| `ChineseUtils.kt` | 繁簡轉換 | `lib/core/services/chinese_utils.dart` | ✅ Matched |
| `ColorUtils.kt` | 顏色解析、轉換 | - | ❌ Missing |
| `ContextExtensions.kt` | Context 相關 (螢幕、權限、路徑) | - | ❌ Missing |
| `CookieManagerExtensions.kt` | Cookie 獲取與儲存 | - | ❌ Missing |
| `EncoderUtils.kt` / `MD5Utils.kt` | 編碼 (Base64/MD5) | `lib/core/engine/js/js_encode_utils.dart` | ⚠️ Partial |
| `EncodingDetect.kt` | 文件編碼自動偵測 | `lib/core/services/encoding_detect.dart` | ✅ Matched |
| `FileDocExtensions.kt` | 虛擬文件管理 (SAF) | `lib/core/storage/file_doc.dart` | ✅ Matched |
| `FileUtils.kt` | 基礎檔案操作 | `lib/core/storage/file_doc.dart` | ⚠️ Partial |
| `GsonExtensions.kt` / `JsonExtensions.kt` | JSON 解析封裝 | `dart:convert` (內建) | ✅ Matched |
| `HtmlFormatter.kt` / `JsoupExtensions.kt` | HTML 內容清理與格式化 | `lib/core/services/content_processor.dart` | ⚠️ Partial |
| `NetworkUtils.kt` | 代理、UA、網路狀態檢查 | - | ❌ Missing |
| `QRCodeUtils.kt` | 二維碼生成與識別 | - | ❌ Missing |
| `StringUtils.kt` / `StringExtensions.kt` | 字串處理、格式檢查 | `dart:core` (內建擴展) | ✅ Matched |
| `TimeUtils.kt` | 時間格式化、時差計算 | - | ❌ Missing |
| `ToastUtils.kt` / `Snackbars.kt` | 提示訊息 UI | - | ❌ Missing |
| `UriExtensions.kt` / `UrlUtil.kt` | URL 解析、編碼、合併 | - | ❌ Missing |
| `*Extensions.kt` (其他 40+ 檔案) | Android SDK 特有的擴展方法 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils/compress

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ZipUtils.kt` | ZIP 壓縮與解壓 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/help

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppWebDav.kt` | WebDAV 備份與同步服務 | `lib/core/services/webdav_service.dart` | ✅ Matched |
| `CacheManager.kt` | 全域快取生命週期管理 | - | ❌ Missing |
| `CrashHandler.kt` | 全域異常捕獲與日誌回傳 | - | ❌ Missing |
| `DefaultData.kt` | 預設書源、語音、規則初始化 | `lib/core/services/default_data.dart` | ✅ Matched |
| `JsEncodeUtils.kt` | JS 內的編碼加密工具 | `lib/core/engine/js/js_encode_utils.dart` | ✅ Matched |
| `JsExtensions.kt` | JS 環境中的全域方法擴展 | `lib/core/engine/js/js_extensions.dart` | ✅ Matched |
| `LauncherIconHelp.kt` | 更換應用程式圖示 | - | ❌ Missing |
| `LifecycleHelp.kt` | Activity/Service 生命週期監聽 | - | ❌ Missing |
| `MediaHelp.kt` | 音頻播放與多媒體控制 | - | ❌ Missing |
| `ReplaceAnalyzer.kt` | 替換規則解析與測試 | - | ❌ Missing |
| `TTS.kt` | 語音合成封裝 | - | ❌ Missing |

### 📂 子資料夾：help/source & help/book
| Android 檔案/路徑 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `help/source/*` | 書源解析、導入、驗證邏輯 | `lib/core/services/source_verification_service.dart` | ⚠️ Partial |
| `help/book/*` | 章節下載、內容抓取、本地書導入 | `lib/core/services/download_service.dart` | ⚠️ Partial |
| `help/storage/*` | SAF、外部存儲協作 | `lib/core/storage/file_doc.dart` | ✅ Matched |

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

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/model (業務邏輯對位)

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ReadBook.kt` | 閱讀器核心狀態與頁面調度 | `lib/features/book/book_provider.dart` | ⚠️ Partial |
| `CacheBook.kt` | 章節預加載與快取邏輯 | `lib/core/services/download_service.dart` | ⚠️ Partial |
| `CheckSource.kt` | 書源效能測試與驗證 | `lib/core/services/check_source_service.dart` | ✅ Matched |
| `Debug.kt` | 書源調試日誌與邏輯 | - | ❌ Missing |
| `SharedJsScope.kt` | JS 執行環境共用變數管理 | `lib/core/engine/js/shared_js_scope.dart` | ✅ Matched |
| `webBook/*` | 網路書源具體解析實作 | `lib/core/engine/book_source_engine.dart` | ⚠️ Partial |

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
| `ui/book` | 閱讀介面、章節列表、書籍詳情 | `lib/features/reader` & `book_detail` | ✅ Matched |
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
