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
| **7.1 併發搜尋機制** | `ChangeCoverViewModel.kt`: L129 (mapParallel) | `change_cover_provider.dart`: L67 (Future.wait) | **Matched** | 均支援在所有已啟用書源中並發執行封面搜尋任務。 |
| **7.2 搜尋狀態控管** | `ChangeCoverDialog.kt`: L85 (startOrStop) | `change_cover_sheet.dart`: L85 (provider.stopSearch) | **Matched** | 均在 UI 提供「停止/重新整理」按鈕，實作對背景搜尋 Job 的生命週期控制。 |
| **7.3 搜尋結果精確過濾** | `ChangeCoverViewModel.kt`: L151 (searchBook.name == name) | `change_cover_provider.dart`: L83 (fName == name) | **Matched** | 均實作了嚴格的「書名+作者」過濾，確保搜尋結果與原書一致。 |
| **7.4 快取優先讀取邏輯** | `ChangeCoverViewModel.kt`: L78 (searchBookDao) | - | **Logic Gap** | Android 啟動時會先從本地資料庫讀取已有的搜尋結果；iOS 目前每次均觸發全新的網路搜尋。 |
| **7.5 手動輸入與相簿選取** | `ChangeCoverDialog.kt` | `change_cover_sheet.dart`: L45 (_pickImage) | **Equivalent** | Android 主要依賴網路搜尋；iOS 額外整合了系統相簿選取封面與手動輸入 URL 功能。 |
| **8.1 換源優選排序演算法** | `ChangeBookSourceViewModel.kt`: L122 (comparator) | `change_chapter_source_sheet.dart`: L100 (results.sort) | **Matched** | 均支援根據書源自定義排序、章節序號匹配（正則提取 [123]）及最新章節資訊進行自動優選。 |
| **8.2 換源搜尋快取預加載** | `ChangeBookSourceViewModel.kt`: L105 (getDbSearchBooks) | `change_chapter_source_sheet.dart`: L75 (_searchBookDao) | **Matched** | 均支援啟動換源介面時先從本地資料庫讀取已有的搜尋結果，縮短等待時間。 |
| **8.3 精準搜尋過濾開關** | `ChangeBookSourceDialog.kt`: R.id.menu_check_author | `change_chapter_source_sheet.dart`: L165 (_checkAuthor) | **Matched** | 均在介面提供開關，控制搜尋時是否必須強制匹配作者名。 |
| **8.4 搜尋範圍分組過濾** | `AppConfig.searchGroup` | - | **Logic Gap** | Android 支援限定在特定書源分組內進行換源搜尋；iOS 目前始終在全體已啟用書源中搜尋。 |
| **8.5 空結果切換引導** | `ChangeBookSourceViewModel.kt`: L55 (searchFinishCallback) | - | **Logic Gap** | Android 在分組搜尋為空時提示切換到全部分組；iOS 目前僅顯示「無搜尋結果」。 |
| **8.6 跨類型（有聲/文本）遷移** | `ChangeBookSourceDialog.kt`: L200 (migrateTo) | `change_chapter_source_sheet.dart`: L286 (_showMigrationDialog) | **Matched** | 均支援在換源時偵測類型變更，並提示執行進度遷移與播放器/閱讀器跳轉。 |
| **9.1 發現搜尋語法連動** | `ExploreFragment.kt`: L155 (group:) | `explore_page.dart`: L67 (_handleSearch) | **Matched** | 均支援在發現頁搜尋框輸入 `group:NAME` 自動切換至對應分組。 |
| **9.2 網格/列表自動切換** | `ExploreShowActivity.kt` | `explore_page.dart`: L133 (isGrid) | **Matched** | 均支援根據書源探索規則中的 layout/style 屬性自動切換顯示模式。 |
| **9.3 分組過濾與動態選單** | `ExploreFragment.kt`: L123 (upGroupsMenu) | `explore_page.dart`: L81 (_buildSourcePicker) | **Matched** | 均能動態提取所有具備發現規則的書源分組並供用戶過濾。 |
| **9.4 壓縮/摺疊模式** | `ExploreAdapter.kt`: compressExplore | - | **Logic Gap** | Android 支援一鍵摺疊所有書源的探索項以節省空間；iOS 採用單一書源切換模式，無全域摺疊。 |
| **9.5 發現頁書源管理** | `ExploreViewModel.kt`: topSource | `explore_page.dart`: L100 (TODO) | **Logic Gap** | Android 支援在發現頁直接置頂、編輯或刪除書源；iOS 目前僅有 UI 佔位，邏輯尚未實作。 |
| **10.1 分組上限檢核** | `GroupManageDialog.kt`: L76 (canAddGroup) | `bookshelf_provider.dart`: L268 (createGroup) | **Matched** | 均實作了 64 個分組的上限檢核邏輯。 |
| **10.2 拖拽排序與持久化** | `ItemTouchCallback.kt` | `bookshelf_provider.dart`: L305 (reorderGroups) | **Matched** | 均支援透過拖拽調整分組順序並同步更新 `order` 欄位。 |
| **10.3 批量操作與進度** | `BookshelfManageActivity.kt` | `bookshelf_provider.dart`: L316 (batchAutoChangeSource) | **Matched** | 均支援批量換源、批量下載、批量移動分組，並提供進度反饋。 |
| **10.4 刷新併發 Pool 控制** | `MainViewModel.kt`: L55 | `bookshelf_provider.dart`: L335 (Pool) | **Matched** | 刷新書架時均採用併發池 (Pool) 機制控制請求頻率，防止被源站封鎖。 |
| **10.5 滑動連續選取** | `DragSelectTouchHelper.kt` | - | **Logic Gap** | Android 支援滑動連續勾選多本書籍；iOS 目前需逐一擊點勾選，無連選快感。 |
| **10.6 分組封面自定義** | - | `group_manage_page.dart`: L130 (_showRenameDialog) | **Equivalent** | iOS 額外實作了為每個分組自定義封面的功能，Android 僅顯示文字圖標。 |
| **11.1 封面點擊交互** | `BookInfoActivity.kt` | `book_detail_page.dart` | **Logic Gap** | Android 點擊封面可查看大圖與保存；iOS 點擊觸發換封面彈窗。 |
| **11.2 閱讀/繼續閱讀按鈕** | `BookInfoActivity.kt`: L441 | `book_detail_page.dart`: L136 | **Matched** | 均支援根據當前進度顯示「開始/繼續閱讀」。 |
| **11.3 加入/移出書架** | `BookInfoActivity.kt`: L456 | `book_detail_page.dart`: L29 | **Matched** | 均支援即時切換書架狀態與持久化。 |
| **11.4 換源彈窗分發** | `ChangeBookSourceDialog.kt` | `book_detail_page.dart`: L141 | **Equivalent** | Android 使用獨立 Dialog；iOS 採用 ModalBottomSheet。 |
| **11.5 目錄加載與倒序** | `BookInfoViewModel.kt`: L120 | `book_detail_page.dart`: L85 | **Matched** | 均支援目錄搜尋與正/倒序顯示。 |
| **11.6 WebDav 上傳同步** | `BookInfoViewModel.kt`: L245 | - | **Logic Gap** | Android 支援針對單一書籍觸發同步；iOS 目前僅有全域備份。 |
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


