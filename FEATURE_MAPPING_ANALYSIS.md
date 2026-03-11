# iOS (Flutter) vs Android (Legado) 全功能對照與深度分析報告

本文件由 AI Agent 逐資料夾掃描 Android 原版功能並與 iOS 版本進行一對一對比產出。

---

## 📂 模組：`api` (伺服器交互與控制器)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/api/`
**功能描述**: 負責 Web 服務的路由分發與 API 回傳格式封裝 (`ReturnData`)，以及書架、書源、替換規則的遠端管理邏輯。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **ReturnData 封裝** | `services/web_service.dart` | 80% | 僅在 `_handleRequest` 中硬編碼 Map 格式，缺乏統一的 Response Model。 | 建立 `core/models/api_response.dart`，規範 `isSuccess`, `data`, `error` 欄位。 |
| **BookController** | `services/web_service.dart` | 40% | 僅實作了 `/getBookshelf`，缺失 `/saveBookProgress`, `/addLocalBook`, `/clearCache` 等 API。 | 在 `WebService` 中補齊對應路由，並調用 `BookDao` 或 `ChapterDao`。 |
| **BookSourceController** | `services/web_service.dart` | 90% | 已實作主要的獲取、儲存與刪除介面。 | 無須大幅改動，細節與 Android 字段對齊即可。 |
| **ReplaceRuleController** | `services/web_service.dart` | 0% | **需要新增此功能**。目前 iOS 版 Web 服務不支援遠端操作替換規則。 | 在 `WebService` 中新增 `/getReplaceRules` 與 `/saveReplaceRule` 路由。 |
| **RSSSourceController** | `services/web_service.dart` | 0% | **需要新增此功能**。目前 iOS 版 Web 服務完全缺失 RSS 遠端管理。 | 待 RSS 基礎服務穩定後加入路由。 |

---

## 📂 模組：`base` (架構基礎層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/base/`
**功能描述**: 定義了 App 的核心架構，包括主題注入、生命週期綁定的非同步任務管裡、以及通用的 UI 組件基礎類。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **BaseViewModel** | `features/*/provider.dart` | 70% | Flutter 使用 Provider 實現了數據綁定，但缺乏統一的錯誤處理與 Loading 狀態基類。 | 建立 `BaseProvider` 基類，規範 `isLoading`, `errorMessage` 的處理流程。 |
| **主題與 UI 基類** | `shared/theme/app_theme.dart` | 90% | Flutter 內建了強大的 ThemeData 支援，iOS 已實作多套閱讀主題。 | 加入深淺色模式自動切換與全域的 `BaseScaffold` 佈局封裝。 |
| **非同步任務生命週期** | `core/services/*` | 60% | Android 依賴 `lifecycleScope`，iOS 版在 Provider dispose 時雖然會停掉 TTS，但部分網路請求尚未有取消機制。 | 引入 `CancelToken` (Dio)，在 Provider dispose 時自動取消正在進行的網路任務。 |

---

## 📂 模組：`constant` (全域常量)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/constant/`
**功能描述**: App 的邏輯大腦，定義了所有業務狀態碼、正則模式、SharedPreferences 鍵值以及事件總線信號。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **BookType / SourceType** | `core/models/book.dart` | 90% | 類型遮罩已實作，且與原版位元運算邏輯同步。 | 將其抽離至獨立的 `core/constant/book_type.dart`。 |
| **AppPattern (正則定義)** | `core/services/content_processor.dart` | 30% | 原版定義了非常細緻的 `imgPattern`, `archiveFileRegex` 等；iOS 版目前隨處硬編碼正則。 | 建立 `core/constant/app_pattern.dart` 集中管理所有系統級正則。 |
| **PreferKey (配置項)** | `features/settings/settings_provider.dart` | 50% | 目前 iOS 僅實作了約 20% 的原版配置項 Key，且硬編碼在 Provider 中。 | 完整移植 Android `PreferKey.kt` 的所有配置 Key，建立 `core/constant/prefer_key.dart`。 |
| **EventBus (事件信號)** | N/A | 0% | **需要新增此功能**。Android 版利用 EventBus 實現全域 UI 通知，iOS 僅依賴局部 Provider 刷新。 | 引入 `event_bus` 套件或實作全域 `ChangeNotifier` 總線。 |

---

## 📂 模組：`data` (數據持久化層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/data/`
**功能描述**: 數據核心，包含所有業務實體類 (`Entities`)、資料庫操作介面 (`DAO`) 以及跨版本的資料庫遷移邏輯 (`Migrations`)。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **數據實體類 (Entities)** | `core/models/*` | 95% | 核心實體如 Book, Chapter, Source 已高度還原，但 `BookGroup` 位元運算邏輯在 Dart 中分散在各處。 | 將位元運算逻辑封裝進 Model 的 extension 中。 |
| **資料庫存取 (DAO)** | `core/database/dao/*` | 85% | iOS 版已補齊複合查詢與批量操作，但缺乏 Android 原版 Room 所提供的全自動緩存機制。 | 引入記憶體二級緩存，對高頻讀取的書源數據進行優化。 |
| **資料庫遷移 (Migrations)** | `core/database/app_database.dart` | 90% | 目前已同步至 v11，支援所有新增字段的熱遷移。 | 規範化 `_onUpgrade` 中的 Switch 區塊，加入詳細的日誌記錄。 |
| **TypeConverters** | `core/models/*.fromJson` | 100% | 已實作 JSON 與資料庫原生類型的雙向轉換。 | 無。 |

---

## 📂 模組：`help` (工具與引擎擴展)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/help/`
**功能描述**: 提供書源解析所需的 JS 橋接、網路請求並發控制、WebDAV 同步以及各類媒體/文件助手。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **JsExtensions (JS橋接)** | `core/engine/js/js_extensions.dart` | 85% | 大部分網路、編碼、解壓、驗證碼介面已補齊，但缺失 `getTxtInFolder` 的編碼自動偵測邏輯。 | 整合 `charset_converter` 或自定義編碼識別算法。 |
| **AppWebDav (雲同步)** | `core/services/webdav_service.dart` | 70% | 已實作基礎的上傳下載，但缺乏原版的「自動定時備份」與「衝突解決」邏輯。 | 實作背景 WorkManager 任務，定時執行 WebDAV 增量同步。 |
| **ConcurrentRateLimiter** | `core/services/rate_limiter.dart` | 100% | 已完整移植「固定間隔」與「次數/毫秒」雙重限制邏輯。 | 無。 |
| **CrashHandler (崩潰日誌)** | N/A | 0% | **需要新增此功能**。目前 iOS 版崩潰後缺乏日誌儲存與反饋機制。 | 使用 `Sentry` 或實作本地 `log_service.dart` 捕獲 Flutter 異常並寫入文件。 |
| **DirectLinkUpload** | N/A | 0% | **需要新增此功能**。Android 版支援將書源、配置上傳至藍奏雲、Github 等直鏈平台。 | 補齊書源匯出至外部 Web 服務的邏輯。 |

---

## 📂 模組：`model` (核心業務邏輯層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/model/`
**功能描述**: 負責全 App 的業務調度，包含書源規則解析、漫畫渲染、自動快取控制以及調試工具。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **WebBook (網路書交互)** | `core/services/book_source_service.dart` | 90% | 已實作搜尋、詳情、目錄、正文獲取，但缺失「併發校驗」的詳細日誌回傳。 | 在 `BookSourceService` 中引入 `Stream<String>` 用於實時回傳校驗日誌。 |
| **ReadBook (閱讀邏輯)** | `features/reader/reader_provider.dart` | 85% | 已實作進度儲存、換源、自動翻頁，但缺失「閱讀日誌」記錄。 | 實作 `ReadRecordDao` 並在閱讀時自動統計每日閱讀時長與字數。 |
| **ReadManga (漫畫模式)** | N/A | 0% | **需要新增此功能**。目前 iOS 版完全不支持漫畫模式渲染。 | 建立 `features/reader/manga_page.dart`，使用 `InteractiveViewer` 實作圖片縮放與滾動。 |
| **Debug (調試工具)** | `core/engine/js/js_extensions.dart` | 40% | 僅有基礎的 `log` 與 `toast`，缺乏 Android 原版那樣精確到規則行的 Debug 信息輸出。 | 在 `AnalyzeRule` 中加入詳細的步驟追蹤，並實作專用的 `DebugPage` 顯示解析過程。 |
| **CacheBook (自動快取)** | `core/services/download_service.dart` | 80% | 已實作任務持久化，但缺乏「全自動預讀 5 章」的智能快取邏輯。 | 在 `ReaderProvider` 中加入後台靜默快取機制。 |

---

## 📂 模組：`service` (後台服務與任務層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/service/`
**功能描述**: 負責全 App 的長時間任務處理，包含離線下載、語音朗讀、WebDAV 自動備份及本地 Web Server 運行。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **離線下載 (CacheService)** | `core/services/download_service.dart` | 85% | 已實作任務持久化與併發控制，但缺失「下載完成自動更新書架」的信號發送。 | 在任務結束時觸發 `BookshelfProvider` 重新掃描本地狀態。 |
| **語音朗讀 (AudioService)** | `core/services/tts_service.dart` | 75% | 已實作播放控制、定時關閉與背景播放，但缺失 iOS 控制中心 (MediaCenter) 的詳情顯示。 | 整合 `audio_service` 套件，將章節標題與書籍封面推送到 iOS 鎖定畫面。 |
| **本地 Web 伺服器** | `core/services/web_service.dart` | 90% | 已實作核心 API 路由，但缺失靜態網頁資產 (HTML/JS) 的託管。 | 在 `WebService` 中加入 `File` 讀取邏輯，將 Web 管理頁面的資源打包進 Assets 並提供訪問。 |
| **書源校驗服務** | `core/services/check_source_service.dart` | 100% | 已完整移植全流程校驗與自動分組邏輯。 | 無。 |
| **自動更新檢查** | N/A | 0% | **需要新增此功能**。目前 iOS 版缺乏定時檢查書架書籍是否有新章節的背景任務。 | 利用 iOS 的 `Background Fetch` 或 `WorkManager` 實作低頻率的自動更新檢查。 |

---

## 📂 模組：`ui` (使用者介面層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/ui/`
**功能描述**: 負責全 App 的視覺呈現與手勢交互，包含極其精密的閱讀渲染器、動態表單生成（用於登入）以及高度自定義的桌面組件。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **閱讀渲染 (ReadPage)** | `features/reader/*` | 80% | 已實作平滑翻頁、狀態感知與筆記，但缺失「圖片選取」與「長截圖」功能。 | 在選取選單中加入圖片識別邏輯，並引入 `screenshot` 套件實作長截圖。 |
| **動態登入 (LoginUI)** | `features/source_manager/source_login_page.dart` | 30% | 原版能根據 JSON 規則動態產生輸入框與按鈕，iOS 目前多為固定表單。 | 實作 `DynamicFormBuilder`，根據書源的 `loginUi` 字段動態渲染 Flutter 組件。 |
| **書架佈局 (Shelf)** | `features/bookshelf/*` | 95% | 已實作九宮格/清單模式切換，支援分組與批量管理。 | 加入「書籍長按拖曳排序」功能。 |
| **文件選取器 (FilePicker)** | `features/bookshelf/bookshelf_provider.dart` | 70% | 依賴第三方套件，缺乏對「內部私有目錄」的系統性管理視圖。 | 實作 `core/local_book/file_manager.dart`，管理解壓後的臨時文件與字體資產。 |
| **桌面組件 (Widgets)** | N/A | 0% | **需要新增此功能**。Android 版支援在手機桌面顯示最近閱讀。 | 使用 Flutter 的 `HomeWidget` 套件實作 iOS 的 WidgetKit 支援。 |

---
*(工作流持續進行中...)*
