# 📋 Legado ➔ Reader 增量審計日誌 (FEATURE_AUDIT_LOG.md)

本文件紀錄了每一項原子化邏輯的比對結果與缺失詳述。

---

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **1.1 BNV 雙擊交互邏輯** | `MainActivity.kt`: L138 (onNavigationItemReselected) | `main.dart`: L415 (onDestinationSelected) | **Matched** | 均支援 300ms 雙擊判定；書架跳轉頂部，發現頁觸發壓縮。 |
| **1.2 動態 Badge 更新** | `MainViewModel.kt`: L166 (onUpBooksLiveData) | `main.dart`: L435 (BookshelfProvider.updatingCount) | **Matched** | 均支援即時顯示更新中書籍數量，iOS 透過 Badge 組件實作。 |
| **1.3 啟動崩潰偵測** | `MainActivity.kt`: L245 (notifyAppCrash) | `main.dart`: L190 (_checkAppCrash) | **Matched** | 均在啟動時檢查標記位並提示查看日誌。 |
| **1.4 版本更新與引導** | `MainActivity.kt`: L202 (upVersion) | `main.dart`: L155 (_checkVersionUpdate) | **Matched** | 均支援比對版本號並彈出更新說明或幫助。 |
| **1.5 WebDav 主動提示還原** | `MainActivity.kt`: L263 (backupSync) | `main.dart`: L210 (_checkBackupSync) | **Matched** | 均支援在啟動時檢查雲端備份時間並提示。 |
| **1.6 啟動自動更新書架** | `MainActivity.kt`: L115 (upAllBookToc) | `main.dart`: L235 (_autoRefreshBookshelf) | **Matched** | 均支援進入 App 後自動觸發書架書籍的掃描。 |
| **1.7 雙擊退出與朗讀背景化** | `MainActivity.kt`: L90 (onBackPressed) | - | **Logic Gap** | Android 支援雙擊退出判定，且朗讀時僅退至背景；iOS 依賴系統手勢，無雙擊退出邏輯。 |
| **1.8 併發 Pool 動態調整** | `MainViewModel.kt`: L55 (upPool) | - | **Logic Gap** | Android 可根據設置即時調整更新執行緒數（最高 128）；iOS 目前固定併發數或由系統調度。 |
| **1.9 下載/更新優先權** | `MainViewModel.kt`: L175 (cacheBook) | - | **Logic Gap** | Android 在更新目錄時會暫停背景下載以避開併發限制；iOS 目前下載與更新為獨立併發。 |
| **2.1 閱讀時長格式化** | `ReadRecordActivity.kt`: L129 (formatDuring) | `about_page.dart`: L236 (_formatDuration) | **Matched** | 均支援將 ms 轉換為「天小時分秒」的邏輯。 |
| **2.2 三向排序模式** | `ReadRecordActivity.kt`: L141-151 | `about_page.dart`: L183 (_SortMode) | **Matched** | 均支援按名稱、時長、最後閱讀時間排序，且邏輯一致。 |
| **2.3 記錄連動搜尋** | `ReadRecordActivity.kt`: L183 (startSearch) | `about_page.dart`: L465 (onTap) | **Matched** | 均支援點擊記錄時，若書架無書則自動跳轉至搜尋頁搜尋該書名。 |
| **2.4 記憶體日誌上限** | `AppLog.kt` | `about_page.dart`: L503 (AppLog) | **Matched** | 均支援在內存中維護最多 500 條運行日誌，包含 Exception 堆疊。 |
| **2.5 全量清除邏輯** | `ReadRecordActivity.kt`: L100 (dao.clear) | `about_page.dart`: L210 (_clearAll) | **Matched** | 均支援一鍵清空所有閱讀時長紀錄。 |
| **2.6 記錄全域開關** | `ReadRecordActivity.kt`: L65 (enableReadRecord) | `about_page.dart`: L385 (settings.enableReadRecord) | **Matched** | 均支援透過配置位控制是否紀錄閱讀時長。 |
| **3.1 JSON 內容特徵辨識** | `FileAssociationActivity.kt`: L71 (successLive) | `intent_handler_service.dart`: L114 (_handleSharedFile) | **Matched** | 均支援根據 JSON 鍵值（如 bookSourceUrl）自動識別書源、RSS 等類型。 |
| **3.2 書籍物理搬移備份** | `FileAssociationActivity.kt`: L138 (copyTo) | `intent_handler_service.dart`: L85 (_handleSharedBook) | **Matched** | 均支援將外部導入書籍拷貝至 App 專屬沙盒目錄（LegadoBooks）以防遺失。 |
| **3.3 私有 Scheme 處理** | `FileAssociationActivity.kt`: L55 (onLineImportLive) | `intent_handler_service.dart`: L60 (_handleUri) | **Matched** | 均支援處理 `legado://import/` 等私有鏈接觸發聯機導入。 |
| **3.4 強制導入機制** | `FileAssociationActivity.kt`: L90 (notSupportedLiveData) | `intent_handler_service.dart`: L142 (_showForceImportDialog) | **Matched** | 當格式無法辨識時，均支援提示用戶是否作為書籍檔案強制導入。 |
| **3.5 多類型導入對話框** | `ImportBookSourceDialog.kt` 等 | `intent_handler_service.dart`: L163 (_showImportDialog) | **Equivalent** | Android 為每種類型準備獨立 Activity/Dialog；iOS 採用單一動態分發彈窗處理。 |
| **4.1 播放模式完整對齊** | `AudioPlay.kt`: PlayMode | `audio_play_service.dart`: L7 (AudioPlayMode) | **Matched** | 均支援單曲、列表循環、隨機、列表結束停止四種模式，邏輯 1:1 對齊。 |
| **4.2 定時睡眠倒數邏輯** | `TimerSliderPopup.kt` | `audio_play_service.dart`: L80 (setSleepTimer) | **Matched** | 均支援分鐘級定時，且 iOS 實作了每秒更新的剩餘時間監聽。 |
| **4.3 跨類型遷移跳轉** | `AudioPlayActivity.kt`: L195 (migrateTo) | `change_chapter_source_sheet.dart`: L286 | **Matched** | 均支援在換源時，若來源為文本書籍則遷移進度並重啟 Activity/Page。 |
| **4.4 倍速調節步進** | `AudioPlayActivity.kt`: L175 (adjustSpeed) | `audio_player_page.dart`: L245 (_showSpeedDialog) | **Equivalent** | Android 支援 0.1x 步進調節；iOS 提供常用倍速選擇彈窗。 |
| **4.5 喚醒鎖保持邏輯** | `AppConfig.audioPlayUseWakeLock` | - | **Logic Gap** | Android 可手動控制是否使用 WakeLock 保持 CPU 喚醒；iOS 依賴系統對音頻會話的自動管理，無手動開關。 |
| **4.6 退出加入書架提示** | `AudioPlayActivity.kt`: L215 (finish) | - | **Logic Gap** | Android 在結束播放時若書籍不在書架會彈窗提示加入；iOS 目前直接退出。 |
| **5.1 書籍分組顯示** | `BookmarkDecoration.kt` | `bookmark_list_page.dart`: L186 (_buildGroupedList) | **Matched** | 均支援將全域書籤按書籍名稱進行聚合分組顯示。 |
| **5.2 Markdown 格式導出** | `AllBookmarkViewModel.kt`: L45 | `bookmark_list_page.dart`: L75 (_exportBookmarks) | **Matched** | 均支援生成含書名、章節、原文及筆記的 MD 結構並匯出。 |
| **5.3 搜尋與即時過濾** | `AllBookmarkActivity.kt`: L45 (collect) | `bookmark_list_page.dart`: L50 (_loadBookmarks) | **Matched** | 均支援透過關鍵字即時過濾書名、標題與筆記內容。 |
| **5.4 書籤編輯功能** | `BookmarkDialog.kt` | - | **Logic Gap** | Android 支援在列表直接點擊彈窗編輯書籤筆記；iOS 目前僅有跳轉與刪除，缺失編輯介面。 |
| **5.5 JSON 序列化導出** | `AllBookmarkViewModel.kt`: L25 | - | **Logic Gap** | Android 提供標準的 JSON 備份導出路徑；iOS 僅實作了文字版 MD 分享。 |
| **5.6 跳轉精確定位** | `BookmarkAdapter.kt` | `bookmark_list_page.dart`: L125 (_jumpToReader) | **Matched** | 均支援點擊書籤後精確跳轉至閱讀器的對應章節與字元位置。 |
| **6.1 調度互斥與併發控制** | `CacheBook.kt`: L122 (mutex) | `download_service.dart`: L35 (_isScheduling) | **Matched** | 均採用互斥鎖機制確保下載調度任務的唯一性，防止重複啟動。 |
| **6.2 全域暫停/恢復邏輯** | `CacheBook.kt`: L118 (workingState) | `download_service.dart`: L50 (_checkPause) | **Matched** | 均實作了基於 Completer/StateFlow 的掛起機制，可在下載中途立即暫停所有執行緒。 |
| **6.3 目錄自動補完機制** | `CacheViewModel.kt` | `download_service.dart`: L135 (getChapterList) | **Matched** | 下載前均會檢查目錄是否為空，若為空則自動觸發目錄更新後再下載。 |
| **6.4 雙層併發限制** | `AppConfig.threadCount` | `download_service.dart`: L30 (_maxConcurrent) | **Matched** | 均支援同時下載多本書，且每本書內部分發多個章節下載執行緒。 |
| **6.5 書籍匯出功能** | `CacheActivity.kt`: L116 (startExport) | - | **Logic Gap** | Android 支援將快取書籍匯出為 TXT/EPUB；iOS 目前完全缺失本地書籍匯出路徑。 |
| **6.6 設定備份加密** | `Backup.kt`: L118 (aes.encrypt) | - | **Logic Gap** | Android 支援對導出的設定檔案進行 AES 加密；iOS 目前僅為明文 JSON。 |





