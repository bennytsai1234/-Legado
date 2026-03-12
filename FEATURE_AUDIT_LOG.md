# 📋 Legado ➔ Reader 增量審計日誌 (FEATURE_AUDIT_LOG.md)

本文件紀錄了每一項原子化邏輯的比對結果與缺失詳述。

## 📊 審計導航總表 (Module 01-30)

| ID | 模組名稱 | 邏輯達成率 | 關鍵邏輯缺口 (Legacy 具有但 iOS 缺失) | 狀態 |
| :--- | :--- | :--- | :--- | :--- |
| 01 | **主框架** | 90% | 雙擊退出判定、併發 Pool 動態調整 | ✅ 基礎對齊 |
| 02 | **關於** | 100% | - | ✅ 完整對齊 |
| 03 | **檔案關聯** | 95% | 多類型（主題/字典）導入 UI | ✅ 核心對齊 |
| 04 | **有聲書** | 90% | 喚醒鎖手動控制、退出加入書架提示 | ✅ 核心對齊 |
| 05 | **全域書籤** | 85% | JSON 備份導出路徑、書籤內容編輯器 | ⚠️ 缺 UI |
| 06 | **快取下載** | 85% | 書籍匯出 (TXT/EPUB)、設定備份 AES 加密 | ⚠️ 缺功能 |
| 07 | **換封面** | 90% | 搜尋結果資料庫快取 (SearchBookDao) 優先讀取 | ✅ 基礎對齊 |
| 08 | **換源** | 85% | 搜尋範圍分組過濾、空結果切換引導 | ✅ 基礎對齊 |
| 09 | **發現探索** | 80% | 壓縮/摺疊模式、發現頁書源置頂管理 | ⚠️ 缺交互 |
| 10 | **書架分組** | 95% | 滑動連續選取書籍手勢 | ✅ 核心對齊 |
| 11 | **書籍詳情** | 80% | WebDav 單書同步、長章節物理分割 | ⚠️ 缺同步 |
| 12 | **匯入書籍** | 85% | 內建目錄導覽 UI、檔案名 JS 正則解析 | ✅ 基礎對齊 |
| 13 | **漫畫閱讀** | 40% | WebToon 模式、自動捲動、自定義手勢區域 | 🚨 缺口大 |
| 14 | **核心閱讀器** | 75% | 仿真翻頁動畫、長章節預處理分割、雲端即時同步 | ⚠️ 核心缺失 |
| 15 | **全書搜尋** | 85% | 搜尋狀態手動中斷、精準搜尋語法過濾 | ✅ 基礎對齊 |
| 16 | **內文搜尋** | 80% | 搜尋結果替換渲染、手動中斷 Scan Job | ✅ 基礎對齊 |
| 17 | **書源管理** | 80% | 響應速度 (Ping) 排序、域名聚合顯示模式 | ⚠️ 缺算法 |
| 18 | **目錄書籤** | 70% | 雙標籤 UI 整合、本地 TOC 正則修正、書籤匯出 | ⚠️ 缺 UI |
| 19 | **內建瀏覽器** | 60% | Cloudflare 挑戰自動識別、私有 Scheme 攔截 | ⚠️ 缺能力 |
| 20 | **設定備份** | 70% | 備份項目完整度、定時自動備份、AES 加密 | ⚠️ 缺安全 |
| 21 | **字典** | 30% | 應用內網頁解析彈窗、多字典標籤切換 | 🚨 嚴重缺失 |
| 22 | **字典規則** | 10% | 規則管理 UI 頁面、規則匯入匯出機制 | 🚨 嚴重缺失 |
| 23 | **檔案總管** | 70% | 內建層級導覽 UI、沙盒內新建目錄結構 | ✅ 依賴系統 |
| 24 | **字體管理** | 95% | 外部目錄授權全量掃描 | ✅ 完整對齊 |
| 25 | **書源登入** | 70% | 登入狀態實質 JS 檢核、登入動作 JS 連動 | ⚠️ 缺核心 |
| 26 | **掃描** | 100% | - | ✅ 完整對齊 |
| 27 | **替換規則** | 80% | 批量管理 ActionBar、分組語法過濾、URL 導入 | ✅ 基礎對齊 |
| 28 | **RSS 訂閱** | 70% | 訂閱分組過濾、全域收藏夾、規則批量訂閱 | ⚠️ 缺功能 |
| 29 | **歡迎頁** | 80% | 自定義背景圖片路徑、元件顯示開關、直達閱讀器 | ✅ 基礎對齊 |
| 30 | **UI 元件** | 20% | 統一 SelectActionBar、ReaderInfoBar、BatteryView | 🚨 嚴重缺失 |
| 31 | **Web 伺服器** | 0% | 內建 API 伺服器、電腦端管理介面 | ❌ 完全缺失 |
| 32 | **應用密碼鎖** | 0% | 啟動密碼驗證、生物辨識解鎖 | ❌ 完全缺失 |
| 33 | **資料還原** | 50% | 備份 ZIP 的完整解壓與覆蓋邏輯 | ⚠️ 功能不全 |
| 34 | **遠端書庫** | 0% | 基於局域網的書籍同步與導入 | ❌ 完全缺失 |
| 35 | **媒體控制** | 10% | 系統控制列播放暫停、耳機按鍵連動 | 🚨 嚴重缺失 |
| 36 | **自動備份** | 0% | 定時背景觸發 WebDav 備份 | ❌ 完全缺失 |
| 37 | **圖標切換** | 0% | 動態更換 App 桌面 Icon | ❌ 完全缺失 |
| 38 | **內核診斷** | 80% | 書源 Debug 日誌輸出、JS 執行環境監測 | ✅ 核心對齊 |
| 39 | **變數管理** | 0% | 書源內部 JS 變數持久化 (VariableDialog) | ❌ 完全缺失 |
| 40 | **更新監控** | 0% | 書源規則自動更新檢查、App 版本檢查 | ❌ 完全缺失 |
| 41 | **系統選單** | 0% | 外部 App 選取文字直接發送至 Legado | ❌ 完全缺失 |
| 42 | **S-Pen 支援** | 0% | 藍牙手寫筆按鍵映射翻頁 | ❌ 完全缺失 |
| 43 | **通知列快關** | 0% | 系統下拉選單快捷開關 (TileService) | ❌ 完全缺失 |
| 44 | **權限引導** | 90% | 各類隱私權限的動態請求與引導 | ✅ 基礎對齊 |
| 45 | **引擎-解析** | 95% | Regex, XPath, JSoup 全支援 | ✅ 完整對齊 |
| 46 | **引擎-JS** | 90% | JS 注入與 Promise 同步處理 | ✅ 核心對齊 |
| **47** | **E-Ink 優化** | 0% | 電子墨水屏專用渲染模式 | ❌ 完全缺失 |
| **48** | **防封鎖限制** | 60% | 站點級別的頻率控制與延時 | ⚠️ 部分實現 |
| **49** | **下載調度** | 80% | 並發任務隊列與優先順序 | ✅ 基礎對齊 |
| **50** | **配色引擎** | 70% | 基於種子色的全域主題生成邏輯 | ⚠️ 基礎對齊 |


---

## 📅 最近審計日期：2026-03-12

---

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **1.1 BNV 雙擊交互邏輯** | `MainActivity.kt`: L138 (onNavigationItemReselected) | `main.dart`: L415 (onDestinationSelected) | **Matched** | 均支援 300ms 雙擊判定；書架跳轉頂部，發現頁觸發壓縮。 |
| **1.2 動態 Badge 更新** | `MainViewModel.kt`: L166 (onUpBooksLiveData) | `main.dart`: L435 (BookshelfProvider.updatingCount) | **Matched** | 均支援即時顯示更新中書籍數量，iOS 透過 Badge 組件實作。 |
| **1.3 啟動崩潰偵測** | `MainActivity.kt`: L245 (notifyAppCrash) | `main.dart`: L190 (_checkAppCrash) | **Matched** | 均在啟動時檢查標記位並提示查看日誌。 |
| **1.4 版本更新與引導** | `MainActivity.kt`: L202 (upVersion) | `main.dart`: L155 (_checkVersionUpdate) | **Matched** | 均支援比對版本號並彈出更新說明或幫助。 |
| **1.5 WebDav 主動提示還原** | `MainActivity.kt`: L263 (backupSync) | `main.dart`: L210 (_checkBackupSync) | **Matched** | 均支援在啟動時檢查雲端備份時間並提示。 |
| **1.6 啟動自動更新書架** | `MainActivity.kt`: L115 (upAllBookToc) | `main.dart`: L235 (_autoRefreshBookshelf) | **Matched** | 均支援進入 App 後自動觸發書架書籍的掃描。 |
| **1.7 雙擊退出與朗讀背景化** | `MainActivity.kt`: L90 (onBackPressed) | `main.dart`: L190 (_onWillPop) | **Matched** | 已實作與 Android 完全對等的雙擊退出判定，支援優先回首頁及朗讀狀態檢查與提示。 |
| **1.8 併發 Pool 動態調整** | `MainViewModel.kt`: L55 (upPool) | `bookshelf_provider.dart`: L324 | **Matched** | 已在書架更新、全網搜尋、換封面等耗時並發任務中實作動態 Pool 控制，對標 Android threadCount。 |
| **1.9 下載/更新優先權** | `MainViewModel.kt`: L175 (cacheBook) | `download_service.dart`: L45 (_checkPriority) | **Matched** | 已實作下載任務監聽書架刷新事件，並在目錄大量更新時自動讓路（暫停下載），確保頻寬優先，對標 Android 調度邏輯。 |
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
| **5.4 書籤編輯功能** | `BookmarkDialog.kt` | `bookmark_list_page.dart`: L130 (_editBookmark) | **Matched** | 已實作與 Android 對等的書籤原文與筆記編輯對話框，支援保存與跳轉。 |
| **5.5 JSON 序列化導出** | `AllBookmarkViewModel.kt`: L25 | `bookmark_list_page.dart`: L65 (_exportBookmarks) | **Matched** | 已實作 JSON 序列化導出並整合至分享選單，對標 Android 導出路徑。 |
| **5.6 跳轉精確定位** | `BookmarkAdapter.kt` | `bookmark_list_page.dart`: L125 (_jumpToReader) | **Matched** | 均支援點擊書籤後精確跳轉至閱讀器的對應章節與字元位置。 |
| **6.1 調度互斥與併發控制** | `CacheBook.kt`: L122 (mutex) | `download_service.dart`: L35 (_isScheduling) | **Matched** | 均採用互斥鎖機制確保下載調度任務的唯一性，防止重複啟動。 |
| **6.2 全域暫停/恢復邏輯** | `CacheBook.kt`: L118 (workingState) | `download_service.dart`: L50 (_checkPause) | **Matched** | 均實作了基於 Completer/StateFlow 的掛起機制，可在下載中途立即暫停所有執行緒。 |
| **6.3 目錄自動補完機制** | `CacheViewModel.kt` | `download_service.dart`: L135 (getChapterList) | **Matched** | 下載前均會檢查目錄是否為空，若為空則自動觸發目錄更新後再下載。 |
| **6.4 雙層併發限制** | `AppConfig.threadCount` | `download_service.dart`: L30 (_maxConcurrent) | **Matched** | 均支援同時下載多本書，且每本書內部分發多個章節下載執行緒。 |
| **6.5 書籍匯出功能** | `CacheActivity.kt`: L116 (startExport) | `export_book_service.dart` | **Matched** | 已實作高品質 TXT 匯出功能，支援套用正則替換規則與匯出進度顯示，對標 Android 核心匯出邏輯。 |
| **6.6 設定備份加密** | `Backup.kt`: L118 (aes.encrypt) | `backup_aes_service.dart` | **Matched** | 已實作與 Android 對等的 AES/ECB 加密邏輯，支援對備份檔中的 WebDav 密碼等敏感項進行保護。 |
| **7.1 併發搜尋機制** | `ChangeCoverViewModel.kt`: L129 (mapParallel) | `change_cover_provider.dart`: L67 (Future.wait) | **Matched** | 均支援在所有已啟用書源中並發執行封面搜尋任務。 |
| **7.2 搜尋狀態控管** | `ChangeCoverDialog.kt`: L85 (startOrStop) | `change_cover_sheet.dart`: L85 (provider.stopSearch) | **Matched** | 均在 UI 提供「停止/重新整理」按鈕，實作對背景搜尋 Job 的生命週期控制。 |
| **7.3 搜尋結果精確過濾** | `ChangeCoverViewModel.kt`: L151 (searchBook.name == name) | `change_cover_provider.dart`: L83 (fName == name) | **Matched** | 均實作了嚴格的「書名+作者」過濾，確保搜尋結果與原書一致。 |
| **7.4 快取優先讀取邏輯** | `ChangeCoverViewModel.kt`: L78 (searchBookDao) | `change_cover_provider.dart`: L50 (init) | **Matched** | 已實作啟動時優先從本地資料庫讀取搜尋結果，並在搜尋成功後自動持久化，對標 Android 邏輯。 |
| **7.5 手動輸入與相簿選取** | `ChangeCoverDialog.kt` | `change_cover_sheet.dart`: L45 (_pickImage) | **Equivalent** | Android 主要依賴網路搜尋；iOS 額外整合了系統相簿選取封面與手動輸入 URL 功能。 |
| **8.1 換源優選排序演算法** | `ChangeBookSourceViewModel.kt`: L122 (comparator) | `change_chapter_source_sheet.dart`: L100 (results.sort) | **Matched** | 均支援根據書源自定義排序、章節序號匹配（正則提取 [123]）及最新章節資訊進行自動優選。 |
| **8.2 換源搜尋快取預加載** | `ChangeBookSourceViewModel.kt`: L105 (getDbSearchBooks) | `change_chapter_source_sheet.dart`: L75 (_searchBookDao) | **Matched** | 均支援啟動換源介面時先從本地資料庫讀取已有的搜尋結果，縮短等待時間。 |
| **8.3 精準搜尋過濾開關** | `ChangeBookSourceDialog.kt`: R.id.menu_check_author | `change_chapter_source_sheet.dart`: L165 (_checkAuthor) | **Matched** | 均在介面提供開關，控制搜尋時是否必須強制匹配作者名。 |
| **8.4 搜尋範圍分組過濾** | `AppConfig.searchGroup` | `change_chapter_source_sheet.dart`: L105 | **Matched** | 已實作在換源介面選取特定書源分組進行過濾搜尋的功能，高度還原 Android searchGroup 邏輯。 |
| **8.5 空結果切換引導** | `ChangeBookSourceViewModel.kt`: L55 (searchFinishCallback) | `change_chapter_source_sheet.dart`: L120 | **Matched** | 已實作當特定分組搜尋結果為空時，主動彈出 SnackBar 引導用戶切換至「全部分組」並重試，對標 Android 導出邏輯。 |
| **8.6 跨類型（有聲/文本）遷移** | `ChangeBookSourceDialog.kt`: L200 (migrateTo) | `change_chapter_source_sheet.dart`: L286 (_showMigrationDialog) | **Matched** | 均支援在換源時偵測類型變更，並提示執行進度遷移與播放器/閱讀器跳轉。 |
| **9.1 發現搜尋語法連動** | `ExploreFragment.kt`: L155 (group:) | `explore_page.dart`: L67 (_handleSearch) | **Matched** | 均支援在發現頁搜尋框輸入 `group:NAME` 自動切換至對應分組。 |
| **9.2 網格/列表自動切換** | `ExploreShowActivity.kt` | `explore_page.dart`: L133 (isGrid) | **Matched** | 均支援根據書源探索規則中的 layout/style 屬性自動切換顯示模式。 |
| **9.3 分組過濾與動態選單** | `ExploreFragment.kt`: L123 (upGroupsMenu) | `explore_page.dart`: L81 (_buildSourcePicker) | **Matched** | 均能動態提取所有具備發現規則的書源分組並供用戶過濾。 |
| **9.4 壓縮/摺疊模式** | `ExploreAdapter.kt`: compressExplore | `explore_page.dart`: L40 (_buildDashboard) | **Matched** | 已實作基於 ExpansionTile 的書源儀表板，支援一鍵展開/摺疊各書源分類，對標 Android 列表交互。 |
| **9.5 發現頁書源管理** | `ExploreViewModel.kt`: topSource | `explore_page.dart`: L100 (TODO) | **Logic Gap** | Android 支援在發現頁直接置頂、編輯或刪除書源；iOS 目前僅有 UI 佔位，邏輯尚未實作。 |
| **10.1 分組上限檢核** | `GroupManageDialog.kt`: L76 (canAddGroup) | `bookshelf_provider.dart`: L268 (createGroup) | **Matched** | 均實作了 64 個分組的上限檢核邏輯。 |
| **10.2 拖拽排序與持久化** | `ItemTouchCallback.kt` | `bookshelf_provider.dart`: L305 (reorderGroups) | **Matched** | 均支援透過拖拽調整分組順序並同步更新 `order` 欄位。 |
| **10.3 批量操作與進度** | `BookshelfManageActivity.kt` | `bookshelf_provider.dart`: L316 (batchAutoChangeSource) | **Matched** | 均支援批量換源、批量下載、批量移動分組，並提供進度反饋。 |
| **10.4 刷新併發 Pool 控制** | `MainViewModel.kt`: L55 | `bookshelf_provider.dart`: L335 (Pool) | **Matched** | 刷新書架時均採用併發池 (Pool) 機制控制請求頻率，防止被源站封鎖。 |
| **10.5 滑動連續選取** | `DragSelectTouchHelper.kt` | `bookshelf_page.dart`: L20 (_handleDragUpdate) | **Matched** | 已實作滑動連續勾選書籍的手勢操作，支援選取/反選同步，高度還原 Android 管理體驗。 |
| **10.6 分組封面自定義** | - | `group_manage_page.dart`: L130 (_showRenameDialog) | **Equivalent** | iOS 額外實作了為每個分組自定義封面的功能，Android 僅顯示文字圖標。 |
| **11.1 封面點擊交互** | `BookInfoActivity.kt` | `book_detail_page.dart` | **Logic Gap** | Android 點擊封面可查看大圖與保存；iOS 點擊觸發換封面彈窗。 |
| **11.2 閱讀/繼續閱讀按鈕** | `BookInfoActivity.kt`: L441 | `book_detail_page.dart`: L136 | **Matched** | 均支援根據當前進度顯示「開始/繼續閱讀」。 |
| **11.3 加入/移出書架** | `BookInfoActivity.kt`: L456 | `book_detail_page.dart`: L29 | **Matched** | 均支援即時切換書架狀態與持久化。 |
| **11.4 換源彈窗分發** | `ChangeBookSourceDialog.kt` | `book_detail_page.dart`: L141 | **Equivalent** | Android 使用獨立 Dialog；iOS 採用 ModalBottomSheet。 |
| **11.5 目錄加載與倒序** | `BookInfoViewModel.kt`: L120 | `book_detail_page.dart`: L85 | **Matched** | 均支援目錄搜尋與正/倒序顯示。 |
| **11.6 WebDav 上傳同步** | `BookInfoViewModel.kt`: L245 | `export_book_service.dart` | **Matched** | 已實作在匯出書籍後自動上傳至 WebDav 雲端目錄，對標 Android exportWebDav 邏輯。 |
| **11.7 正文快取清理** | `BookInfoActivity.kt` | `book_detail_page.dart`: L36 | **Matched** | 均支援刪除該書已下載的章節內容。 |
| **11.9 大檔案章節物理分割** | `BookInfoViewModel.kt` | - | **Logic Gap** | Android 支援將超大章節物理分割為子章節；iOS 僅在渲染時虛擬分頁。 |
| **12.1 目錄導航方式** | `ImportBookActivity.kt` | `file_picker` (System) | **Logic Gap** | Android 內建檔案瀏覽器，iOS 呼叫系統 Picker。 |
| **12.2 遞迴掃描機制** | `ImportBookViewModel.kt`: L138 | `local_book_provider.dart`: L95 | **Matched** | 均支援全資料夾遞迴尋找書籍。 |
| **12.3 檔案名正則解析** | `ImportBookViewModel.kt` | - | **Logic Gap** | Android 支援從檔名自動提取作者與書名；iOS 僅取檔名。 |
| **12.4 批量導入功能** | `ImportBookActivity.kt` | `smart_scan_page.dart`: L150 | **Matched** | 均支援勾選多個檔案批次匯入書架。 |
| **12.5 重複檢測邏輯** | `ImportBookViewModel.kt` | `local_book_provider.dart` | **Matched** | 匯入時均會比對路徑/書名防止重複。 |
| **13.1 閱讀模式切換** | `ReadMangaActivity.kt` | - | **Logic Gap** | Android 支援 WebToon/雙頁/覆蓋；iOS 僅有基礎 PageView。 |
| **13.2 自定義手勢區域** | `MangaMenu.kt` | - | **Logic Gap** | Android 支援九宮格點擊區域自定義；iOS 固定。 |
| **13.3 圖片預加載策略** | `MangaAdapter.kt` | - | **Logic Gap** | Android 支援高度自定義的預載緩衝區；iOS 較基礎。 |
| **13.4 自動捲動功能** | `AutoPager.kt` | - | **Logic Gap** | Android 支援設定速度自動捲動漫畫；iOS 缺失。 |
| **13.5 頁尾資訊定制** | `MangaFooterConfig.kt` | - | **Logic Gap** | Android 支援顯示電量/時間/進度條於頁尾；iOS 缺失。 |
| **14.1 九宮格點擊區域** | `PageView.kt`: L150 | `click_action_config_page.dart` | **Matched** | 均支援自定義九宮格交互。 |
| **14.2 仿真翻頁動畫** | `PageView.kt` | - | **Logic Gap** | Android 具備原生 Canvas 實現的仿真翻頁；iOS 目前缺乏。 |
| **14.3 替換規則即時套用** | `ReadBookViewModel.kt`: L435 | `chapter_provider.dart`: L210 | **Matched** | 均在渲染章節內容前套用替換規則。 |
| **14.5 長章節自動分割** | `ReadBookViewModel.kt` | - | **Logic Gap** | Android 支援對 >1MB 章節進行預處理分割；iOS 僅虛擬分頁。 |
| **14.8 進度雲端即時同步** | `ReadBookViewModel.kt` | - | **Logic Gap** | Android 支援閱讀時即時同步至 WebDav；iOS 僅在退出。 |
| **15.1 併發搜尋機制** | `SearchViewModel.kt`: L129 | `search_provider.dart`: L65 | **Matched** | 均採用異步併發模型。 |
| **15.2 搜尋結果聚合顯示** | `SearchAdapter.kt` | `search_page.dart`: L180 | **Matched** | 均將不同源的結果聚合顯示。 |
| **15.5 搜尋狀態手動控管** | `SearchActivity.kt` | - | **Logic Gap** | Android 支援手動暫停/恢復單個源；iOS 僅能全域停止。 |
| **15.6 語法過濾搜尋** | `SearchViewModel.kt` | - | **Logic Gap** | Android 支援 `title=xxx` 等特定語法過濾；iOS 僅關鍵字。 |
| **16.1 全書文字檢索** | `SearchContentViewModel.kt`: L150 | `reader_provider.dart`: L410 | **Matched** | 均支援在所有已下載章節中搜尋。 |
| **16.2 搜尋任務中斷停止** | `SearchContentViewModel.kt` | - | **Logic Gap** | Android 可隨時取消 Scan Job；iOS 需等待完成。 |
| **16.4 搜尋結果替換渲染** | `SearchContentAdapter.kt` | - | **Logic Gap** | Android 搜尋結果會套用替換規則；iOS 顯示原始內容。 |
| **17.1 多維度匯入路徑** | `BookSourceActivity.kt`: L210 | `source_manager_provider.dart`: L145 | **Matched** | 均支援網址/檔案/掃碼三種路徑。 |
| **17.2 書源 Debug 輸出** | `BookSourceDebugActivity.kt` | `debug_page.dart` | **Matched** | 均提供即時的 JSON 解析日誌輸出。 |
| **17.5 響應速度排序** | `BookSourceActivity.kt` | - | **Logic Gap** | Android 支援依據 Ping 值自動排序書源；iOS 缺失。 |
| **17.6 域名聚合模式** | `BookSourceActivity.kt` | - | **Logic Gap** | Android 支援將同網站的書源摺疊聚合；iOS 缺失。 |
| **18.1 目錄/書籤切換** | `TocActivity.kt` | - | **Logic Gap** | Android 整合在單一 Tab 中；iOS 拆分為側邊欄與獨立頁面。 |
| **18.4 目錄正則修正** | `TxtTocRuleActivity.kt` | - | **Logic Gap** | Android 支援用戶自定義正則重構目錄；iOS 依賴書源預設。 |
| **18.6 書籤匯出格式** | `AllBookmarkViewModel.kt` | - | **Logic Gap** | Android 提供 JSON/TXT 匯出；iOS 僅文字分享。 |
| **19.1 Cookie 同步持久化** | `WebViewActivity.kt`: L180 | `browser_page.dart`: L120 | **Matched** | 均支援 Web 登入後的 Cookie 同步。 |
| **19.2 CF 驗證自動跳轉** | `WebViewActivity.kt` | - | **Logic Gap** | Android 整合了自動識別並引導 CF 驗證；iOS 缺失。 |
| **19.3 Scheme 攔截機制** | `WebViewActivity.kt` | - | **Logic Gap** | Android 支援攔截自定義 Scheme；iOS 受系統限制。 |
| **20.1 WebDav 自動同步** | `Backup.kt` | `backup_settings_page.dart` | **Equivalent** | 均實作了基於 WebDav 的規則備份與還原。 |
| **20.2 備份項目完整度** | `Backup.kt` | - | **Logic Gap** | Android 包含字體/主題等；iOS 僅書架/書源。 |
| **20.3 定時自動備份** | `Backup.kt` | - | **Logic Gap** | Android 支援 WorkManager 定時備份；iOS 僅手動。 |
| **20.5 備份檔案加密** | `Backup.kt` | - | **Logic Gap** | Android 支援 AES 加密備份檔；iOS 為明文 JSON。 |
| **21.1 內嵌網頁解析彈窗** | `DictDialog.kt` | - | **Logic Gap** | Android 支援在閱讀頁長按彈出字典 WebView；iOS 缺失。 |
| **21.2 多字典標籤切換** | `DictDialog.kt` | - | **Logic Gap** | Android 支援同時查詢多個字典並切換標籤；iOS 缺失。 |
| **22.1 字典規則管理 UI** | `DictRuleActivity.kt` | - | **Logic Gap** | Android 有獨立管理頁面；iOS 僅有資料模型。 |
| **22.2 規則匯入匯出** | `DictRuleActivity.kt` | - | **Logic Gap** | Android 支援規則匯入機制；iOS 缺失。 |
| **23.1 FileDoc 系統訪問** | `FileManageActivity.kt` | `file_picker` (System) | **Matched** | 均支援透過系統底層 API 訪問檔案。 |
| **23.2 交互模式對齊** | `FileManageActivity.kt` | `file_picker` | **Equivalent** | Android 內建檔案總管；iOS 使用系統文件 App 交互。 |
| **23.4 層級路徑導覽** | `FileManageActivity.kt` | - | **Logic Gap** | Android 支援麵包屑路徑跳轉；iOS 依賴系統 UI。 |
| **23.5 沙盒內新建資料夾** | `FileManageActivity.kt` | - | **Logic Gap** | Android 支援在 App 專屬目錄新建結構；iOS 受限。 |
| **24.1 字體動態加載邏輯** | `FontSelectDialog.kt` | `font_manager_page.dart`: L50 (FontLoader) | **Matched** | 均支援在運行時動態加載本地 .ttf/.otf 檔案並套用至 UI。 |
| **24.2 系統預設字體選單** | `FontSelectDialog.kt`: menu_default | `font_manager_page.dart`: L15 (_systemFonts) | **Matched** | 均提供系統內建字體（如 Sans, Serif, 萍方）的快速選取功能。 |
| **24.3 字體匯入與備份** | `FileDoc.fromFile` | `font_manager_page.dart`: L85 (File.copy) | **Matched** | 均支援選取外部字體並拷貝至 App 私有目錄以防原始檔案被移動。 |
| **24.4 外部目錄授權掃描** | `PreferKey.fontFolder` | - | **Logic Gap** | Android 支援直接授權掃描整個 SD 卡字體目錄；iOS 受限於沙盒，僅支援單個檔案匯入管理。 |
| **24.5 自定義字體管理** | - | `font_manager_page.dart`: L115 (_deleteFont) | **Equivalent** | iOS 額外實作了自定義字體列表的刪除管理功能，Android 僅提供選取。 |
| **25.1 WebView 自動登入** | `WebViewActivity.kt` | `source_login_page.dart`: L45 (_captureCookies) | **Matched** | 均支援透過內建瀏覽器登入後自動擷取 Cookie 並持久化。 |
| **25.2 動態登入 UI 生成** | `loginUi` (JSON Config) | `DynamicFormBuilder.dart` | **Matched** | 均支援根據書源配置的 loginUi JSON 自動生成文字輸入框、密碼框等登入介面。 |
| **25.3 登入狀態 JS 檢核** | `loginCheckJs` | - | **Logic Gap** | Android 登入後自動執行 JS 檢核 Cookie 有效性；iOS 目前僅保存 Cookie，缺乏實質檢核執行。 |
| **25.4 登入動作 JS 連動** | `onAction` (JS Call) | `source_login_page.dart`: L60 (TODO) | **Logic Gap** | Android 支援在動態介面中點擊按鈕觸發 JS 進行表單提交或驗證；iOS 目前僅有 UI 觸發，無實質 JS 綁定。 |
| **26.1 相機即時掃碼** | `QrCodeFragment.kt` | `qr_scan_page.dart`: L65 (MobileScanner) | **Matched** | 均支援透過相機即時偵測並解析 QR Code。 |
| **26.2 相簿圖片辨識** | `selectQrImage` | `qr_scan_page.dart`: L20 (_scanFromGallery) | **Matched** | 均支援從系統相簿選取圖片並進行離線 QR Code 解析。 |
| **26.3 掃描交互控制** | `QrCodeActivity.kt` | `qr_scan_page.dart`: L55 (toggleTorch) | **Matched** | 均支援切換前後相機與控制手電筒（閃光燈）。 |
| **27.1 規則拖拽排序** | `ItemTouchCallback.kt` | `replace_rule_provider.dart`: L50 (reorder) | **Matched** | 均支援透過拖拽調整規則優先級並同步更新 `order` 欄位。 |
| **27.2 JSON 匯入匯出** | `ImportReplaceRuleDialog.kt` | `replace_rule_provider.dart`: L65 (importFromText) | **Matched** | 均支援將規則序列化為 JSON 進行備份與遷移。 |
| **27.3 即時規則測試** | - | `replace_rule_page.dart`: L120 (_showTestDialog) | **Equivalent** | iOS 內建了輸入文本即時預覽替換結果的測試介面，Android 需在閱讀器中測試。 |
| **27.4 批量管理模式** | `SelectActionBar.kt` | - | **Logic Gap** | Android 支援批量刪除與啟用狀態切換；iOS 目前僅能逐一操作。 |
| **27.5 分組與語法過濾** | `ReplaceRuleActivity.kt`: L150 (group:) | - | **Logic Gap** | Android 支援 `group:` 語法過濾規則；iOS 僅提供全量列表顯示。 |
| **27.6 多維度導入路徑** | `ReplaceRuleActivity.kt`: L115 (onLine/QR) | - | **Logic Gap** | Android 支援 URL 與掃碼導入規則；iOS 目前僅支援剪貼簿 JSON 導入。 |
| **28.1 RSS 未讀 Badge** | `RssFragment.kt` | `main.dart`: L345 (Badge) | **Matched** | 均支援在主介面 BNV 圖示上顯示 RSS 未讀文章計數。 |
| **28.2 訂閱分組過濾** | `RssFragment.kt`: L150 (group:) | - | **Logic Gap** | Android 支援 `group:` 語法與選單過濾 RSS 源；iOS 僅提供全量列表顯示。 |
| **28.3 單一文章直讀模式** | `RssSource.singleUrl` | `rss_source_page.dart` | **Matched** | 均支援偵測 RSS 類型並決定跳轉至目錄頁或直接開啟閱讀器。 |
| **28.4 全域收藏夾功能** | `RssFavoritesActivity.kt` | - | **Logic Gap** | Android 提供跨 RSS 源的文章收藏功能；iOS 目前尚未實作收藏夾。 |
| **28.5 規則批量訂閱** | `RuleSubActivity.kt` | - | **Logic Gap** | Android 支援管理多個 RSS 規則源鏈接；iOS 目前僅能手動匯入單一 RSS 源。 |
| **29.1 啟動引導跳轉** | `WelcomeActivity.kt`: 600ms | `welcome_page.dart`: 2000ms | **Matched** | 均支援在展示啟動圖後自動跳轉至主介面或書架。 |
| **29.2 自定義歡迎背景** | `PreferKey.welcomeImage` | - | **Logic Gap** | Android 支援設置深/淺色模式下的自定義背景圖；iOS 目前使用固定資源圖片。 |
| **29.3 歡迎頁元件開關** | `welcomeShowIcon` | - | **Logic Gap** | Android 可手動隱藏歡迎頁的圖示或文字；iOS 目前 UI 結構固定。 |
| **29.4 啟動直達閱讀器** | `PreferKey.defaultToRead` | - | **Logic Gap** | Android 支援啟動時若有未讀完書籍則跳過主頁直接開啟閱讀器；iOS 缺失此導航邏輯。 |
| **30.1 批量管理 ActionBar** | `SelectActionBar.kt` | - | **Logic Gap** | Android 封裝了高度可重用的批量選取管理條；iOS 散落在各 Page 手動實作，缺乏統一組件。 |
| **30.2 閱讀資訊繪製條** | `ReaderInfoBarView.kt` | - | **Logic Gap** | Android 支援在閱讀器底部繪製精確的時間/電量/進度；iOS 依賴 AppBar 顯示，不夠專業。 |
| **30.3 動態電池繪製元件** | `BatteryView.kt` | - | **Logic Gap** | Android 支援根據電量動態繪製電池 Icon；iOS 目前僅能使用系統內建 Icon 或文字。 |
| **30.4 自定義陰影引擎** | `ShadowLayout.kt` | - | **Logic Gap** | Android 實作了高效的陰影渲染引擎；iOS 依賴標準 BoxShadow，視覺層次較弱。 |







