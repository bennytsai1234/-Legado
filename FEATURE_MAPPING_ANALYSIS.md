# iOS (Flutter) vs Android (Legado) 全功能對照與深度分析報告

本文件由 AI Agent 逐資料夾掃描 Android 原版功能並與 iOS 版本進行一對一對比產出。

---

## 📂 模組：`api` (伺服器交互與控制器)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/api/`
**功能描述**: 負責 Web 服務的路由分發與 API 回傳格式封裝 (`ReturnData`)，以及書架、書源、替換規則的遠端管理邏輯。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **ReturnData 封裝** | `core/models/api_response.dart` | 100% | 無。已實作統一的 ApiResponse Model 並應用於 WebService。 | 已完成。 |
| **BookController** | `core/services/web_service.dart` | 95% | 已補齊 `/saveBookProgress`, `/getChapterList`, `/refreshToc`, `/getBookContent`, `/saveBook`, `/deleteBook`, `/clearCache`。僅 `/addLocalBook` 因 multipart 解析缺失暫未全功能實作。 | 已完成大部分路由。未來需引入 `mime` 套件以支援本地書上傳。 |
| **BookSourceController** | `services/web_service.dart` | 90% | 已實作主要的獲取、儲存與刪除介面。 | 無須大幅改動，細節與 Android 字段對齊即可。 |
| **ReplaceRuleController** | `core/services/web_service.dart` | 100% | 已實作 `/getReplaceRules`, `/saveReplaceRule`, `/deleteReplaceRule`, `/testReplaceRule`。 | 已完成。 |
| **RSSSourceController** | `core/services/web_service.dart` | 100% | 已實作 `/getRssSources`, `/getRssSource`, `/saveRssSource`, `/saveRssSources`, `/deleteRssSources`。 | 已完成。 |

---

## 📂 模組：`base` (架構基礎層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/base/`
**功能描述**: 定義了 App 的核心架構，包括主題注入、生命週期綁定的非同步任務管裡、以及通用的 UI 組件基礎類。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **BaseViewModel** | `core/base/base_provider.dart` | 100% | 已建立 `BaseProvider` 基類，並在 `BookshelfProvider` 中應用。支援統一的 `isLoading` 與 `errorMessage` 處理。 | 已完成。 |
| **主題與 UI 基類** | `shared/widgets/base_scaffold.dart` | 100% | 已實作全域 `BaseScaffold` 佈局封裝，支援統一的 Loading 顯示、AppBar 管理與系統主題適配。 | 已完成。 |
| **非同步任務生命週期** | `core/base/base_provider.dart` | 100% | 已引入 `CancelToken` (Dio)，並在 `BaseProvider.dispose` 時自動取消。`AnalyzeUrl` 與 `BookSourceService` 已全面支援傳遞 `CancelToken`。 | 已完成。 |

---

## 📂 模組：`constant` (全域常量)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/constant/`
**功能描述**: App 的邏輯大腦，定義了所有業務狀態碼、正則模式、SharedPreferences 鍵值以及事件總線信號。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **BookType / SourceType** | `core/constant/book_type.dart` | 100% | 已將 `BookType`, `BookSourceType`, `SourceType` 抽離至獨立常量文件，並由 `Book` 模型匯出以維持相容性。 | 已完成。 |
| **AppPattern (正則定義)** | `core/constant/app_pattern.dart` | 100% | 已建立 `AppPattern` 並移植了 Android 版所有系統級正則。已在 `ContentProcessor` 中應用。 | 已完成。 |
| **PreferKey (配置項)** | `core/constant/prefer_key.dart` | 100% | 已完整移植 Android 版 `PreferKey.kt` 的所有配置 Key，並在 `SettingsProvider` 中開始應用，消除了大部分硬編碼。 | 已完成。 |
| **EventBus (事件信號)** | `core/services/event_bus.dart` | 100% | 已實作 `AppEventBus` 並移植了 Android 版所有核心事件常量。支援類型化與名稱化事件分發。 | 已完成。 |

---

## 📂 模組：`data` (數據持久化層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/data/`
**功能描述**: 數據核心，包含所有業務實體類 (`Entities`)、資料庫操作介面 (`DAO`) 以及跨版本的資料庫遷移邏輯 (`Migrations`)。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **數據實體類 (Entities)** | `core/models/*` | 100% | 核心實體已高度還原。已將 `Book` 的分組與類型位元運算邏輯封裝至 `BookBitwiseExtension` 中。 | 已完成。 |
| **資料庫存取 (DAO)** | `core/database/dao/*` | 100% | 已補齊複合查詢與批量操作，並在 `BookSourceDao` 中引入記憶體二級快取以優化高頻讀取。 | 已完成。 |
| **資料庫遷移 (Migrations)** | `core/database/app_database.dart` | 100% | 已規範化 `_onUpgrade` 切換邏輯，並加入詳細的升級日誌記錄以確保追蹤遷移過程。 | 已完成。 |
| **TypeConverters** | `core/models/*.fromJson` | 100% | 已實作 JSON 與資料庫原生類型的雙向轉換。 | 無。 |

---

## 📂 模組：`help` (工具與引擎擴展)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/help/`
**功能描述**: 提供書源解析所需的 JS 橋接、網路請求並發控制、WebDAV 同步以及各類媒體/文件助手。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **JsExtensions (JS橋接)** | `core/engine/js/js_extensions.dart` | 100% | 已實作 `getTxtInFolder` 的編碼自動偵測邏輯，並整合了 `EncodingDetect` 以支援多種中文編碼。 | 已完成。 |
| **AppWebDav (雲同步)** | `core/services/webdav_service.dart` | 90% | 已實作進度同步 (`syncAllBookProgress`)、自動建立遠端目錄與備份衝突解決邏輯。 | 已完成大部分核心邏輯。未來可引入 `workmanager` 實作背景自動同步。 |
| **ConcurrentRateLimiter** | `core/services/rate_limiter.dart` | 100% | 已完整移植「固定間隔」與「次數/毫秒」雙重限制邏輯。 | 無。 |
| **CrashHandler (崩潰日誌)** | N/A | 0% | **需要新增此功能**。目前 iOS 版崩潰後缺乏日誌儲存與反饋機制。 | 使用 `Sentry` 或實作本地 `log_service.dart` 捕獲 Flutter 異常並寫入文件。 |
| **DirectLinkUpload** | N/A | 0% | **需要新增此功能**。Android 版支援將書源、配置上傳至藍奏雲、Github 等直鏈平台。 | 補齊書源匯出至外部 Web 服務的邏輯。 |

---

## 📂 模組：`model` (核心業務邏輯層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/model/`
**功能描述**: 負責全 App 的業務調度，包含書源規則解析、漫畫渲染、自動快取控制以及調試工具。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **WebBook (網路書交互)** | `core/services/check_source_service.dart` | 100% | 已實作搜尋、詳情、目錄、正文獲取，並透過 `AppEventBus` 實作了「併發校驗」的詳細日誌即時回傳。 | 已完成。 |
| **ReadBook (閱讀邏輯)** | `features/reader/reader_provider.dart` | 85% | 已實作進度儲存、換源、自動翻頁，但缺失「閱讀日誌」記錄。 | 實作 `ReadRecordDao` 並在閱讀時自動統計每日閱讀時長與字數。 |
| **ReadManga (漫畫模式)** | `features/reader/manga_reader_page.dart` | 100% | 已實作漫畫閱讀器，支援圖片列表渲染、沉浸模式、亮度控制、目錄跳轉及預加載優化。 | 已完成。 |
| **Debug (調試工具)** | `features/debug/debug_page.dart` | 100% | 已在 `AnalyzeRule` 中加入詳細步驟日誌，並實作 `DebugPage` 以實時顯示解析過程與結果預覽。 | 已完成。 |
| **CacheBook (自動快取)** | `core/services/download_service.dart` | 80% | 已實作任務持久化，但缺乏「全自動預讀 5 章」的智能快取邏輯。 | 在 `ReaderProvider` 中加入後台靜默快取機制。 |

---

## 📂 模組：`service` (後台服務與任務層)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/service/`
**功能描述**: 負責全 App 的長時間任務處理，包含離線下載、語音朗讀、WebDAV 自動備份及本地 Web Server 運行。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **離線下載 (CacheService)** | `core/services/download_service.dart` | 100% | 已實作任務持久化與併發控制，並在任務結束時透過 `AppEventBus` 發送 `upBookshelf` 信號，觸發 `BookshelfProvider` 刷新。 | 已完成。 |
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
| **動態登入 (LoginUI)** | `features/source_manager/dynamic_form_builder.dart` | 100% | 已實作 `DynamicFormBuilder`，支援根據書源的 `loginUi` JSON 自動生成輸入框與按鈕，並在 `SourceLoginPage` 中整合。 | 已完成。 |
| **書架佈局 (Shelf)** | `features/bookshelf/*` | 100% | 已實作九宮格/清單模式切換，並在清單模式下支援「書籍長按拖曳排序」功能。 | 已完成。 |
| **文件選取器 (FilePicker)** | `features/bookshelf/bookshelf_provider.dart` | 70% | 依賴第三方套件，缺乏對「內部私有目錄」的系統性管理視圖。 | 實作 `core/local_book/file_manager.dart`，管理解壓後的臨時文件與字體資產。 |
| **桌面組件 (Widgets)** | N/A | 0% | **需要新增此功能**。Android 版支援在手機桌面顯示最近閱讀。 | 使用 Flutter 的 `HomeWidget` 套件實作 iOS 的 WidgetKit 支援。 |

---

## 📂 模組：`modules/*` (核心獨立模組)
**Android 路徑**: `legado/modules/`
**功能描述**: App 的技術引擎，包含排版渲染 (`book`)、JS 腳本執行環境 (`rhino`) 與基礎通訊協定 (`web`)。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **JS 虛擬環境 (Rhino)** | `core/engine/js/*` | 100% | 已實作全域 `_sharedScope` 模擬 JS 全域作用域，並補齊了 `java.put` 與 `java.get` 介面。 | 已完成。 |
| **排版引擎 (Book)** | `core/engine/parsers/*` | 45% | iOS 版目前僅實作了 TXT/EPUB 解析，缺失 PDF 與漫畫封裝層。 | 引入 `native_pdf_view` 並擴展現有的 `ChapterProvider` 支援多格式渲染。 |
| **Web 通訊 (Web)** | `core/services/http_client.dart` | 95% | 基於 Dio 實作，支援 Cookie 管理與全域攔截。 | 無。 |

---

## 📂 模組：`receiver` (系統事件監聽)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/receiver/`
**功能描述**: 監聽作業系統發送的廣播信號，實現耳機線控、網路狀態切換感應、電量預警等。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **媒體按鍵 (MediaButton)** | `core/services/tts_service.dart` | 20% | Android 支援上一首/下一首對應翻頁；iOS 目前僅支援基礎播放/暫停。 | 使用 `audio_service` 套件的 `onCustomAction` 實作音量鍵翻頁模擬。 |
| **網路狀態感應** | `core/services/http_client.dart` | 0% | **需要新增此功能**。iOS 版目前在網路切換（Wi-Fi 轉 5G）時不會自動暫停下載。 | 引入 `connectivity_plus` 並在全域 Provider 中監聽狀態。 |
| **定時/電量事件** | `features/reader/engine/page_view_widget.dart` | 100% | 已透過畫布重繪邏輯實作了狀態感知。 | 無。 |

---

## 📂 模組：`utils` (底層工具庫)
**Android 路徑**: `legado/app/src/main/java/io/legado/app/utils/`
**功能描述**: 包含極其龐大的擴展函數庫，特別是文件操作、中文處理、正則增強以及圖片轉換。

| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **虛擬文件系統 (FileDoc)** | `core/storage/file_doc.dart` | 100% | 已建立 `FileDoc` 類別，統一封裝了 Sandbox 內外文件的存取、列表、讀寫（含編碼偵測）與刪除操作。 | 已完成。 |
| **中文轉換 (ChineseUtils)** | `core/services/chinese_utils.dart` | 100% | 已完整移植簡繁體轉換邏輯。 | 無。 |
| **二進位/編碼擴展** | `core/engine/js/js_encode_utils.dart` | 100% | 已補齊 `CRC32` 算法，並增強了 `Base64` 對 `NO_PADDING` 與 `URL_SAFE` 等 flags 的支援。 | 已完成。 |

---
*(所有資料夾與核心模組掃描已完成，分析報告封存。)*
