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


