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
