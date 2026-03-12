# 🗺️ Legado ➔ Reader 全量功能映射地圖 (The Ultimate Mapping)

本文件是依據「增量式代碼對齊流程 (SOP v3)」階段一所建立的**終極全量責任區劃分**。它涵蓋了 Android (Legado) 專案 100% 的原始碼目錄，確保跨平台遷移時沒有任何一行邏輯被遺漏。

---

## 🏗️ 第一層：核心底層引擎 (Core Engines)
這些是支撐整個 App 運作的基礎設施，通常沒有直接的 UI 頁面。

| ID | 引擎名稱 | Android 責任區 (Kotlin) | iOS 預期對應位置 (Dart) | 狀態 |
|:---|:---|:---|:---|:---|
| **E01** | **規則解析引擎** | `model/analyzeRule/` (Regex, XPath, JSoup, JsonPath) | `core/engine/analyze_rule.dart` | ✅ 基礎對齊 |
| **E02** | **網路通訊引擎** | `help/http/` (Cronet, CookieStore, Interceptors) | `core/services/http_client.dart` | ✅ 基礎對齊 |
| **E03** | **資料庫與實體** | `data/dao/`, `data/entities/` | `core/database/` | ✅ 基礎對齊 |
| **E04** | **JS 運行時環境** | `model/SharedJsScope.kt`, `help/JsExtensions.kt` | `core/engine/js/` | ✅ 基礎對齊 |
| **E05** | **非同步併發控制** | `help/coroutine/` (CompositeCoroutine, Monitor) | `core/utils/` (Futures/Isolates) | ⚠️ 需優化 |
| **E06** | **圖片加載與濾鏡** | `help/glide/` (Blur, Progress, E-Ink Filter) | `cached_network_image` 配置 | 🚨 缺濾鏡 |

---

## 📚 第二層：閱讀器核心業務 (Reading Core)
這是 App 最複雜、程式碼最密集的區域。

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **01** | **文本閱讀器** | `ui/book/read/`, `model/ReadBook.kt`, `PageView.kt` | `features/reader/reader_page.dart` | ⚠️ 缺排版動畫 |
| **02** | **漫畫閱讀器** | `ui/book/manga/`, `model/ReadManga.kt` | `features/reader/manga_reader_page.dart` | 🚨 缺 WebToon |
| **03** | **有聲書播放器** | `ui/book/audio/`, `service/AudioPlayService.kt` | `features/reader/audio_player_page.dart` | ✅ 核心對齊 |
| **04** | **系統 TTS 朗讀** | `service/TTSReadAloudService.kt`, `help/TTS.kt` | `core/services/tts_service.dart` | ✅ 核心對齊 |
| **05** | **網路 HttpTTS** | `service/HttpReadAloudService.kt`, `dao/HttpTTSDao` | `core/services/http_tts_service.dart` | 🚨 嚴重缺失 |
| **06** | **內容替換規則** | `ui/replace/`, `help/ReplaceAnalyzer.kt` | `features/replace_rule/` | ✅ 基礎對齊 |
| **07** | **內文全書搜尋** | `ui/book/searchContent/`, `ViewModel` | `features/reader/reader_page.dart` (搜尋) | ✅ 基礎對齊 |
| **08** | **字典與查詞** | `ui/dict/`, `dao/DictRuleDao.kt` | `features/dict/` (待建立) | 🚨 嚴重缺失 |
| **09** | **目錄與書籤** | `ui/book/toc/`, `ui/book/bookmark/` | `features/book_detail/` (TOC Tab) | ⚠️ 缺 UI |
| **10** | **TXT 規則目錄** | `ui/book/toc/rule/TxtTocRuleActivity` | `core/local_book/` (解析) | 🚨 嚴重缺失 |

---

## 🌐 第三層：網路書源與發現 (Source & Network)

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **11** | **書源管理** | `ui/book/source/manage/`, `help/source/SourceHelp` | `features/source_manager/` | ⚠️ 缺進階排序 |
| **12** | **書源編輯與登錄** | `ui/book/source/edit/`, `ui/login/` | `features/source_manager/` | ⚠️ 缺 JS 連動 |
| **13** | **書源網路偵錯** | `ui/book/source/debug/`, `model/Debug.kt` | `features/source_manager/debug_page.dart` | ✅ 核心對齊 |
| **14** | **全網搜書** | `ui/book/search/`, `model/SearchModel.kt` | `features/search/` | ✅ 基礎對齊 |
| **15** | **發現與探索** | `ui/book/explore/`, `ui/main/explore/` | `features/explore/` | ⚠️ 缺摺疊交互 |
| **16** | **書籍換源** | `ui/book/changesource/` | `features/reader/change_chapter_source_sheet` | ✅ 基礎對齊 |
| **17** | **換封面** | `ui/book/changecover/` | `features/book_detail/change_cover_sheet` | ✅ 基礎對齊 |
| **18** | **書源靜默校驗** | `service/CheckSourceService.kt`, `model/CheckSource` | 背景隔離服務 (待建立) | 🚨 嚴重缺失 |
| **19** | **內建網頁瀏覽器** | `ui/browser/WebViewActivity.kt` | `shared/widgets/browser_page.dart` | ⚠️ 缺 Scheme |

---

## 📚 第四層：書架與檔案管理 (Library & File)

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **20** | **主框架與書架** | `ui/main/`, `ui/book/manage/` | `main.dart`, `features/bookshelf/` | ✅ 基礎對齊 |
| **21** | **書架分組管理** | `ui/book/group/` | `features/bookshelf/group_manage_page` | ✅ 核心對齊 |
| **22** | **書籍詳情頁** | `ui/book/info/` | `features/book_detail/` | ⚠️ 缺同步 |
| **23** | **快取與背景下載** | `ui/book/cache/`, `service/DownloadService.kt` | `features/cache_manager/` | ⚠️ 缺匯出 |
| **24** | **本地書籍匯入** | `ui/book/import/local/` | `features/local_book/smart_scan_page.dart` | ✅ 基礎對齊 |
| **25** | **遠端書庫導入** | `ui/book/import/remote/`, `model/remote/` | `features/local_book/remote_import.dart` | 🚨 嚴重缺失 |
| **26** | **大批書籍匯出** | `service/ExportBookService.kt` | 匯出服務 (待建立) | 🚨 嚴重缺失 |
| **27** | **檔案總管與關聯** | `ui/file/`, `ui/association/`, `FileDoc.kt` | `features/association/` | ✅ 核心對齊 |

---

## 📡 第五層：RSS 與進階功能 (RSS & Advanced)

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **28** | **RSS 訂閱管理** | `ui/rss/`, `ui/main/rss/`, `model/rss/` | `features/rss/` | ⚠️ 缺規則訂閱 |
| **29** | **Web 管理伺服器** | `api/`, `service/WebService.kt`, `WebTileService` | 內建伺服器 (待建立) | 🚨 嚴重缺失 |
| **30** | **全域設定與備份** | `ui/config/`, `help/storage/` | `features/settings/` | ⚠️ 缺加密/定時 |
| **31** | **字體管理** | `ui/font/` | `features/settings/font_manager_page.dart` | ✅ 完整對齊 |
| **32** | **主題與 UI 配置** | `lib/theme/`, `ui/config/ThemeConfigFragment` | `features/settings/theme_settings_page` | ✅ 基礎對齊 |
| **33** | **關於與日誌統計** | `ui/about/`, `constant/AppLog.kt` | `features/about/` | ✅ 完整對齊 |
| **34** | **歡迎頁引導** | `ui/welcome/` | `features/welcome/` | ✅ 基礎對齊 |
| **35** | **二維碼掃描** | `ui/qrcode/` | `features/source_manager/qr_scan_page` | ✅ 完整對齊 |
| **36** | **應用程式密碼鎖** | `ui/login/PasswordActivity.kt` | 啟動驗證邏輯 (待建立) | 🚨 嚴重缺失 |
| **37** | **桌面圖標切換** | `help/LauncherIconHelp.kt` | iOS Alternate Icons | 🚨 嚴重缺失 |

---

## ⚙️ 第六層：系統級深度整合 (System Integration)
這部分依賴於原生作業系統的 API，跨平台難度最高。

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **38** | **通知列媒體控制** | `receiver/MediaButtonReceiver.kt` | `audio_session`, `MPRemoteCommandCenter` | 🚨 嚴重缺失 |
| **39** | **全域文字選單攔截**| `receiver/SharedReceiverActivity.kt` | iOS Share Extension / Action Extension | 🚨 嚴重缺失 |
| **40** | **系統崩潰與凍結監控**| `help/CrashHandler.kt`, `help/AppFreezeMonitor` | `Catcher` / 系統 Crashlytics | ⚠️ 缺凍結監控 |
| **41** | **外部數據提供者** | `api/ReaderProvider.kt` (ContentProvider) | iOS 無對等機制 (或 App Group) | 🚨 架構差異 |
| **42** | **App 更新檢查器** | `help/update/AppUpdate.kt` | 檢查 GitHub Release 邏輯 | 🚨 嚴重缺失 |
| **43** | **S-Pen 藍牙翻頁** | `com.samsung.android.support.REMOTE_ACTION` | 無對等硬體 (或適配音量鍵翻頁) | 🚨 平台差異 |
| **44** | **權限沙盒引導** | `lib/permission/` | iOS Info.plist 權限請求 | ✅ 系統差異處理 |
| **45** | **全域 UI 元件庫** | `ui/widget/` (SelectActionBar, InfoBar, etc.) | `shared/widgets/` | 🚨 嚴重缺失 |
