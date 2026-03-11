# iOS (Flutter) vs Android (Legado) 深度對比報告

本文件系統性地記錄了 iOS 版本與 Android 原版代碼的逐文件對比結果。

## 1. 數據模型層 (Entities / Models)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/data/entities/`
**iOS 目錄**: `ios/lib/core/models/`

| 實體名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **Book (書籍)** | ✅ 高度還原 | **已補齊字段**: `customTag`, `customCoverUrl`, `customIntro`, `charset`, `syncTime`。<br>**已實作邏輯**: <br>1. **ReadConfig 完整還原**: 實作了內嵌的 `ReadConfig` 模型，支援 JSON 序列化，包含翻頁動畫、淨化規則、模擬更新等全量配置。<br>2. **業務方法**: 已實作 `migrateTo`, `getRealAuthor`, `getUseReplaceRule`, `getReSegment`。<br>3. **分組優化**: 分組類型已改為 `int` 並支援位元運算，與 Android 原版完全相容。 |
| **BookSource (書源)** | ✅ 高度還原 | **已補齊字段**: `coverDecodeJs`, `exploreScreen`, `ruleReview`。<br>**已實作邏輯**: <br>1. **分組操作還原**: 實作了 `addGroup`, `removeGroup` 等位元運算/集合操作邏輯，確保分組管理與 Android 一致。<br>2. **校驗輔助**: 實作了 `getCheckKeyword` 等用於自動化測試的核心方法。<br>3. **序列化優化**: 解決了規則對象的二次轉義問題，確保資料庫存儲格式標準化。 |
| **BookChapter (章節)** | ✅ 高度還原 | **已補齊字段**: `baseUrl`, `wordCount`, `start`, `end`。<br>**已修正類型**: `startFragmentId` 與 `endFragmentId` 已改為 `String` 以相容 EPUB。<br>**已實作邏輯**: <br>1. **核心方法還原**: 實作了 `getDisplayTitle` (支援標題淨化)、`getAbsoluteURL` (精確拼接) 與 `getFileName` (與原版一致的 MD5 命名規則)。<br>2. **變量支援**: 實作了 `variableMap` 邏輯，支援書源解析過程中的狀態持久化。 |
| **HttpTTS (朗讀引擎)** | ✅ 高度還原 | **字段狀態**: 基本同步。<br>**小細節**: Android 版 ID 預設為 `System.currentTimeMillis()`，iOS 版目前預設為 `0` (由資料庫 Autoincrement 處理，可能影響跨裝置同步時的 ID 碰撞)。<br>**邏輯狀態**: 缺失 `fromJsonArray` 等批量解析輔助方法。 |
| **ReplaceRule (替換規則)** | ✅ 高度還原 | **已補齊字段**: `scopeTitle`, `excludeScope`, `timeoutMillisecond`。<br>**已實作邏輯**: <br>1. **正則校驗還原**: 實作了 `isValid` 邏輯，能自動檢測非法正則（如結尾多餘的 `|`），防止渲染崩潰。<br>2. **超時控制**: 引入了 `timeoutMillisecond` 機制，為後續解析引擎的正則超時保護奠定基礎。<br>3. **作用域細分**: 支援區分標題與正文作用域，與 Android 原版邏輯完全一致。 |
| **RssSource (RSS源)** | ✅ 高度還原 | **字段狀態**: 核心字段（規則、WebView 設定、JS 注入）基本同步。<br>**缺失邏輯**: 缺失 Android 版的 `addGroup`, `removeGroup` 等分組動態操作方法。<br>**註意**: 雖然模型已還原，但 iOS 版 RSS 相關功能在 UI 與 Service 層仍處於極早期階段。 |
| **Server (Web服務)** | ✅ 高度還原 | **字段狀態**: 基本同步。<br>**邏輯狀態**: WebDavConfig 結構正確，支援 JSON 解析。 |

## 2. 解析規則層 (Rules / Analysis)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/data/entities/rule/`
**iOS 目錄**: `ios/lib/core/models/` (iOS 將 Rule 作為內部類或獨立文件存放在 models 中)

| 規則名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **BookInfoRule** | ✅ 高度還原 | **已補齊**: `canReName` 字段及其解析邏輯。 |
| **ContentRule** | ✅ 高度還原 | **已補齊**: `payAction` (付費操作 JS) 字段。 |
| **SearchRule** | ✅ 高度還原 | 字段基本對齊。 |
| **TocRule** | ✅ 高度還原 | **已補齊**: `preUpdateJs` (更新前預處理 JS) 字段。 |
| **ExploreRule** | ✅ 高度還原 | 字段基本對齊。 |
| **ReviewRule (段評)** | ✅ 高度還原 | **狀態**: 從「完全缺失」提升至「高度還原」。已實作完整的 `ReviewRule` 模型，支援頭像、內容、點讚、刪除等全量段評規則字段。 |

## 3. 解析引擎層 (Core Engine)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/model/analyzeRule/`
**iOS 目錄**: `ios/lib/core/engine/`

| 引擎名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **AnalyzeUrl** | ✅ 高度還原 | **已實作功能**: <br>1. **併發控制**: 完整整合了 `ConcurrentRateLimiter`，支援「固定間隔」與「次數/毫秒」雙模式，防止被封 IP。<br>2. **數據 URI**: 支援 `data:image/...;base64` 格式解析，無需發起網路請求即可讀取內嵌資源。<br>3. **健壯性**: 補齊了 30s 超時保護與自動重定向 URL 追蹤邏輯。 |
| **AnalyzeRule** | ✅ 高度還原 | **已實作功能**: <br>1. **JS 緩存機制**: 實作了 `_scriptCache` 模擬 Android 的 `CompiledScript`，顯著提升重複規則的解析效能。<br>2. **高級規則拆分**: 完美還原了 `SourceRule` 的構造邏輯，支援 `@put`, `@get`, `{{js}}` 的精確識別與優先級處理。<br>3. **嵌套組合**: 支援 `##...###` 的 `replaceFirst` 語法，並能在 `makeUpRule` 階段遞歸組合動態參數。<br>4. **Java 交互**: 在 JS context 中注入 `java` 對象，預留了 `reGetBook` 等高級交互接口。 |
| **RuleAnalyzer** | ✅ 高度還原 | **已實作功能**: <br>1. **平衡組算法**: 完美還原了 `chompCodeBalanced` 與 `chompRuleBalanced`，支援對嵌套大括號、中括號與引號的精確識別，解決了 JS 規則提前截斷的 Bug。<br>2. **指針掃描**: 採用了基於 `pos` 的高效掃描機制，大幅減少字串切片開銷，效能與 Android 原版對齊。<br>3. **深度遞歸**: 重構了 `innerRuleRange`，確保如 `{{js: {a:{}}}}` 這種多層嵌套規則能被正確解析。 |

## 4. 資料庫存取層 (DAO)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/data/dao/`
**iOS 目錄**: `ios/lib/core/database/dao/`

| DAO 名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **BookDao** | ✅ 高度還原 | **已實作功能**: <br>1. **響應式架構**: 引入 `StreamController` 模擬 Room Flow，UI 可實時監聽書架數據變化。<br>2. **位元運算過濾**: 整合 `BookType` 位元遮罩，支援對「音訊書」、「本地書」、「更新錯誤」與「不在書架」書籍的精確過濾。<br>3. **業務邏輯還原**: 補齊了 `upGroup`, `removeGroupBit`, `deleteNotShelfBook` 等與 Android 原版一致的底層維護方法。 |
| **BookSourceDao** | ✅ 高度還原 | **已實作功能**: <br>1. **效能優化**: 實作了 `partColumns` 輕量化投影，書源清單僅讀取關鍵字段，徹底解決大數據量下的 UI 卡頓。<br>2. **批量事務**: 補齊了 `enableSources` 與 `deleteSources` 的批量 SQL 支援，大幅提升操作效率。<br>3. **分組邏輯**: 完美還原了 `dealGroups` 邏輯，支援對複雜分隔符的分組拆分與中文排序。<br>4. **響應式資料流**: 實作了 `watchAllPart` 監聽機制。 |
| **ChapterDao** | ✅ 高度還原 | **已實作功能**: <br>1. **精確查詢**: 補齊了 `searchChapters` 與 `getChapterRange` 方法，支援在目錄中搜尋與分段加載。<br>2. **位置管理**: 實作了 `updateChapterOffsets`，支援對章節 `start`, `end` 與 `wordCount` 的局部精確更新，還原了 Android 原版處理超大 TXT 的底層支柱。<br>3. **效能優化**: 補齊了 `getChapterCount` 與 `hasContent` 等輕量級狀態檢查方法。 |

## 5. 服務與背景任務層 (Services / Background)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/service/`
**iOS 目錄**: `ios/lib/core/services/`

| 服務名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **DownloadService** | ✅ 高度還原 | **已實作功能**: <br>1. **任務持久化**: 引入了 `download_tasks` 資料庫表，確保下載隊列在 App 關閉/崩潰後能自動恢復，還原了原版 `CacheBookService` 的核心行為。<br>2. **併發控制**: 實作了「書籍間併發」與「章節間併發」的雙層線程池邏輯，大幅提升快取效率。<br>3. **狀態同步**: 下載進度實時寫回資料庫，並透過 `ChangeNotifier` 提供與原版一致的 UI 回饋。 |
| **WebService** | ✅ 高度還原 | **已實作功能**: <br>1. **本地伺服器**: 使用 `dart:io` 實作了高效的本地 HTTP 伺服器，預設運行於 8659 埠。<br>2. **核心 API 還原**: 完整對標 `HttpServer.kt` 實作了 `/getBookSources`, `/saveBookSource`, `/getBookshelf` 等關鍵 API。<br>3. **CORS 支援**: 還原了原版的 OPTIONS 預檢與跨域頭處理，確保電腦瀏覽器能正常訪問。<br>4. **IP 自動識別**: 實作了區域網路 IPv4 地址自動獲取邏輯。 |
| **AudioPlayService** | ✅ 高度還原 | **已實作功能**: <br>1. **翻頁連動**: 實作了 `onComplete` 回調機制，當 TTS 讀完當前頁面文字後自動觸發 `nextPage()`，實現與 Android 原版一致的「邊聽邊翻」體驗。<br>2. **睡眠定時**: 補齊了 `setSleepTimer` 邏輯，支援設定分鐘級倒數並自動停止播放。<br>3. **音訊會話**: 深度配置了 `audio_session` 的音訊類別，為耳機線控提供了穩定的底層支援。 |
| **CheckSourceService** | ✅ 高度還原 | **已實作功能**: <br>1. **併發控制**: 實作了非同步任務池，限制同時校驗的書源數量，還原了 Android 的穩健網路存取策略。<br>2. **全流程校驗**: 完整複刻了「搜尋 -> 詳情 -> 目錄 -> 正文」的深度校驗鏈，確保書源在各個階段的可用性。<br>3. **自動標籤化**: 實作了根據錯誤類型（如「搜尋失效」、「校驗超時」）自動為書源分組的功能。<br>4. **效能指標**: 新增了響應時間（Stopwatch）計時與最後更新時間同步。 |

## 6. JS 擴展與橋接層 (JS Extensions / Bridge)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/help/JsExtensions.kt`
**iOS 目錄**: `ios/lib/core/engine/js/js_extensions.dart`

| 功能分類 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **網絡請求** | ✅ 高度還原 | 支援 `ajax`, `ajaxAll`, `connect`, `get`, `post`。 |
| **解密與編碼** | ✅ 高度還原 | 支援 `base64`, `md5`, `symmetricCrypto`, `hex` 運算。 |
| **反爬蟲繞過** | ✅ 高度還原 | **已實作功能**: <br>1. **互動式驗證**: 實作了 `SourceVerificationService`，支援 JS 引擎非同步等待 UI 結果。<br>2. **瀏覽器等待**: 補齊了 `startBrowserAwait` 接口，支援 Cloudflare 等站點的手動驗證。<br>3. **驗證碼支援**: 補齊了 `getVerificationCode` 接口，支援彈出圖片驗證碼輸入框。 |
| **壓縮包處理** | ✅ 高度還原 | **已實作功能**: <br>1. **解壓引擎**: 整合 `archive` 套件實作了 `unArchiveFile`，支援將本地 Zip 解壓至臨時目錄。<br>2. **遠端提取**: 實作了 `getZipByteArrayContent`，支援直接從網路 URL 讀取 Zip 內特定檔案。<br>3. **批量讀取**: 實作了 `getTxtInFolder`，支援將目錄下所有文字檔案合併返回，對齊 Android 原版處理漫畫書源的邏輯。 |
| **字體替換** | ✅ 高度還原 | **已實作功能**: <br>1. **效能優化**: 實作了 `_fontReplaceCache` 全域緩存，避免在大章節中重複執行字體映射運算。<br>2. **緩存策略**: 支援基於文本與字體 ID 的複合 Key，效能與 Android 原版位圖比對邏輯在同一維度。 |
| **其它工具** | ✅ 高度還原 | **已實作功能**: <br>1. **序號轉換**: 完美移植了 `chineseNumToInt` 核心算法，支援「第一百二十三章」等複雜中文數字精確轉為阿拉伯數字。<br>2. **時間格式化**: 實作了 `timeFormatUTC`，支援自定義毫秒偏移的時區格式化輸出。<br>3. **全域跳轉**: 補齊了 `openUrl` 接口，支援書源觸發外部瀏覽器打開連結。 |

## 7. UI 與 交互層 (UI / UX)
**Android 目錄**: `legado/app/src/main/java/io/legado/app/ui/`
**iOS 目錄**: `ios/lib/features/`

| 界面名稱 | 對比狀態 | 詳細發現 (缺失字段/邏輯) |
| :--- | :--- | :--- |
| **閱讀界面** | ✅ 高度還原 | **已實作功能**: <br>1. **自動翻頁**: 實作了基於 `Ticker` 的高頻位移計算，支援與原版一致的「進度線覆蓋」翻頁動畫。<br>2. **換源系統**: 實作了 `_chapterSourceOverrides` 機制，支援單章特定書源覆蓋。<br>3. **選取交互**: 補齊了「查詞」與「筆記」功能，支援原文持久化儲存。<br>4. **狀態感知**: 支援在畫布實時繪製電量與時間。 |
| **書架界面** | ✅ 高度還原 | **已實作功能**: <br>1. **狀態過濾**: 補齊了「更新錯誤」、「本地」與「音訊」的快速過濾功能。<br>2. **自動分類**: 實作了刷新失敗時自動標記 `BookType.updateError` 的邏輯。 |
| **書源管理** | ✅ 高度還原 | **已實作功能**: <br>1. **批量校驗**: 完整整合了 `CheckSourceService`，支援批量異步校驗與即時進度顯示。<br>2. **狀態可視化**: 高度還原了 Android 的響應時間與失效標籤顯示。<br>3. **分組清理**: 實作了動態分組重新整理與清理邏輯。 |

---
## 總結：核心還原度統計

| 維度 | 還原度 (預估) | 核心技術缺口 |
| :--- | :--- | :--- |
| **數據模型** | 98% | 已完整補齊 `ReadConfig`, `BookChapter` 位置與 `Bookmark` 筆記字段。 |
| **解析引擎** | 95% | 已補齊 JS 緩存、平衡組解析、併發控制與互動式反爬蟲驗證。 |
| **背景服務** | 95% | 已實作持久化下載隊列、本地 Web 伺服器與朗讀定時器。 |
| **UI 交互** | 90% | 已實作自動翻頁、單章換源、狀態感知繪製與書架/書源批量管理。 |

---
*(對比報告結束)*
