# 📋 Legado ➔ Reader 增量審計日誌 (FEATURE_AUDIT_LOG.md)

本文件紀錄了每一項原子化邏輯的比對結果與缺失詳述。

---

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **1.1 BNV 雙擊回頂部/壓縮邏輯** | `MainActivity.kt`: L138-157 | `lib/main.dart`: L415-425 | **Matched** | - |
| **1.2 動態更新計數 Badge 顯示** | `MainViewModel.kt`: L166 | `lib/main.dart`: L435-460 | **Matched** | - |
| **1.3 啟動崩潰偵測與彈窗提醒** | `MainActivity.kt`: L104 | `lib/main.dart`: L305, L45-55 | **Matched** | - |
| **1.4 啟動版本號比對與更新日誌彈窗** | `MainActivity.kt`: L102 | `lib/main.dart`: L249-272 | **Matched** | - |
| **1.5 啟動 WebDav 修改時間比對** | `MainActivity.kt`: L105 | `lib/main.dart`: L327-352 | **Matched** | - |
| **2.1 閱讀時長格式化邏輯** | `ReadRecordActivity.kt`: L129 | `about_page.dart`: L236-248 | **Matched** | - |
| **2.2 三種排序模式** | `ReadRecordActivity.kt`: L141-151 | `about_page.dart`: L183-199 | **Matched** | - |
| **2.3 閱讀記錄連動搜尋邏輯** | `ReadRecordActivity.kt`: L183-195 | `about_page.dart`: L465-474 | **Matched** | - |
| **2.4 全域記憶體日誌管理** | `AppLog.kt` | `about_page.dart`: L503-525 | **Matched** | - |
| **3.1 JSON 內容特徵辨識** | `FileAssociationActivity.kt`: L71 | `intent_handler_service.dart`: L114-135 | **Matched** | - |
| **3.2 書籍導入物理搬移** | `FileAssociationActivity.kt`: L138 | `intent_handler_service.dart`: L85-105 | **Matched** | - |
| **3.3 格式不支援時的強制導入機制** | `FileAssociationActivity.kt`: L90 | `intent_handler_service.dart`: L142-161 | **Matched** | - |
| **4.1 四種播放模式切換與圖示聯動** | `AudioPlayActivity.kt`: L131, L151 | `audio_play_service.dart`: L41-66 | **Matched** | - |
| **4.2 定時睡眠倒數計時邏輯** | `AudioPlayActivity.kt`: L190 | `audio_play_service.dart`: L101-121 | **Matched** | - |
| **4.3 跨類型遷移跳轉** | `AudioPlayViewModel.kt`: L85 | `change_chapter_source_sheet.dart`: L286 | **Matched** | - |
| **5.1 依書籍分組顯示** | `AllBookmarkActivity.kt`: L55 | `bookmark_list_page.dart`: L186-210 | **Matched** | - |
| **5.2 書籤 JSON 導出功能** | `AllBookmarkViewModel.kt`: L21 | - | **Logic Gap** | iOS 缺失 JSON 格式導出 |
| **5.3 書籤內容/筆記編輯器** | `BookmarkDialog.kt` | - | **Logic Gap** | iOS 缺失書籤編輯 UI |
| **6.1 下載併發與全域暫停控制** | `CacheBook.kt`: L128 | `download_service.dart`: L41-57 | **Matched** | - |
| **6.2 調度互斥鎖 (Mutex)** | `CacheBook.kt`: L122 | `download_service.dart`: L136 | **Matched** | - |
| **6.3 離線書籍匯出 (TXT/EPUB)** | `CacheActivity.kt`: L116 | - | **Logic Gap** | iOS 缺失書籍匯出功能 |
| **7.1 並發搜尋封面演算法** | `ChangeCoverViewModel.kt`: L129 | `change_cover_provider.dart`: L67-76 | **Matched** | - |
| **7.2 搜尋結果資料庫快取** | `ChangeCoverViewModel.kt`: L78 | - | **Logic Gap** | iOS 未優先讀取 SearchBookDao |
| **7.3 精確過濾邏輯** | `ChangeCoverViewModel.kt`: L151 | `change_cover_provider.dart`: L83-86 | **Matched** | - |
| **8.1 換源優選排序** | `ChangeBookSourceViewModel.kt`: L122 | `change_chapter_source_sheet.dart`: L100 | **Matched** | - |
| **8.2 單章換源與目錄預覽** | `ChangeChapterSourceDialog.kt` | `change_chapter_source_sheet.dart` | **Matched** | - |
| **8.3 換源搜尋分組過濾** | `ChangeBookSourceViewModel.kt`: L178 | - | **Logic Gap** | iOS 缺失換源時的分組限制 |
| **9.1 分組過濾 UI 與解耦** | `ExploreFragment.kt`: L123 | `explore_page.dart`: L81-90 | **Matched** | - |
| **9.2 搜尋框 group:NAME 語法** | `ExploreFragment.kt`: L155 | `explore_page.dart`: L67-73 | **Matched** | - |
| **9.3 網格/列表切換** | `ExploreShowActivity.kt` | `explore_page.dart`: L133-141 | **Matched** | - |
| **10.1 64 個分組上限檢核** | `GroupManageDialog.kt`: L76 | `bookshelf_provider.dart`: L268-272 | **Matched** | - |
| **10.2 分組拖拽排序與 Order 更新** | `GroupManageDialog.kt`: L133 | `bookshelf_provider.dart`: L305-315 | **Matched** | - |
| **10.3 批量換源與併發 Pool** | `BookshelfManageActivity.kt`: L115 | `bookshelf_provider.dart`: L316-352 | **Matched** | - |
| **11.1 封面點擊交互** | `BookInfoActivity.kt`: L455 (OnClickListener) | `book_detail_page.dart`: L115 | **Logic Gap** | Android 支援長按查看大圖 (PhotoDialog)，iOS 僅有短按換封面。 |
| **11.2 閱讀按鈕分發** | `BookInfoActivity.kt`: L463 (readBook) | `book_detail_page.dart`: L141 | **Matched** | 均支援根據當前進度跳轉至閱讀器。 |
| **11.3 加入/移除書架** | `BookInfoActivity.kt`: L474 (tvShelf) | `book_detail_page.dart`: L25 | **Matched** | 邏輯一致，iOS 採用 AppBar 圖示切換。 |
| **11.4 換源彈窗觸發** | `BookInfoActivity.kt`: L502 (ChangeBookSourceDialog) | `book_detail_page.dart`: L145 | **Equivalent** | iOS 採用 BottomSheet 形式呈現。 |
| **11.5 核心目錄加載** | `BookInfoActivity.kt`: L415 (upLoading) | `book_detail_provider.dart`: L75 | **Matched** | 均支援在詳情頁自動加載最新目錄。 |
| **11.6 WebDav 上傳同步** | `BookInfoActivity.kt`: L361 (upLoadBook) | - | **Logic Gap** | iOS 端目前完全缺失詳情頁手動上傳書籍至 WebDav 的功能。 |
| **11.7 清理正文快取** | `BookInfoActivity.kt`: L231 (menu_clear_cache) | `book_detail_page.dart`: L33 | **Matched** | 均已實作清理該書所有章節正文的邏輯。 |
| **11.8 預加載後續章節** | - | `book_detail_page.dart`: L185 | **Equivalent** | iOS 額外實作了在詳情頁自定義數量預加載功能，Android 則偏向在書架自動更新。 |
| **11.9 本地書籍長章節分割** | `BookInfoActivity.kt`: L233 (split_long_chapter) | - | **Logic Gap** | iOS 目前針對本地大體積 TXT 缺少手動觸發的正則分割邏輯。 |
| **11.10 書籍資訊手動編輯** | `BookInfoActivity.kt`: L191 (infoEditResult) | `book_detail_page.dart`: L202 | **Matched** | 均支援手動修改書名、作者、簡介。 |
| **12.1 目錄導航與 UI 結構** | `ImportBookActivity.kt`: L140 (upPath) | `smart_scan_page.dart`: L103 | **Logic Gap** | Android 支援在頁面內瀏覽目錄結構；iOS 則採用彈出系統檔案選擇器後一次性展示掃描結果的模式。 |
| **12.2 遞迴掃描邏輯** | `ImportBookActivity.kt`: L162 (scanFolder) | `smart_scan_page.dart`: L23 (recursive) | **Matched** | 均支援遞迴掃描子資料夾尋找支援的書籍格式 (TXT, EPUB)。 |
| **12.3 檔案名 JS 解析** | `ImportBookActivity.kt`: L178 (alertImportFileName) | - | **Logic Gap** | iOS 目前缺失自定義 JS 或正則表達式來從檔案名中解析書名與作者的功能。 |
| **12.4 批量導入機制** | `ImportBookActivity.kt`: L101 (onClickSelectBarMainAction) | `smart_scan_page.dart`: L46 (_importSelected) | **Matched** | 均支援勾選多本書籍後批量加入書架。 |
| **12.5 重複導入檢測** | `ImportBookViewModel.kt` | `local_book_provider.dart`: L51 | **Matched** | 均在導入前檢查資料庫中是否已存在同路徑書籍。 |
| **12.6 掃描進度顯示** | `ImportBookActivity.kt`: L168 (refreshProgressBar) | `smart_scan_page.dart`: L108 | **Equivalent** | 均有掃描時的 Loading 狀態提示。 |
| **13.1 閱讀模式支援** | `ReadMangaActivity.kt`: L200 (setHorizontalScroll) | `manga_reader_page.dart`: L79 (ListView) | **Logic Gap** | Android 支援水平、垂直、Webtoon 等多種翻頁與捲動模式；iOS 目前僅有垂直捲動模式。 |
| **13.2 交互區域與手勢** | `ReadMangaActivity.kt`: L228 (onNextPage) | `manga_reader_page.dart`: L75 (onTap) | **Logic Gap** | Android 支援點擊左/中/右區域分別觸發上一頁、選單、下一頁；iOS 僅點擊觸發選單控制。 |
| **13.3 圖片預加載與緩存** | `ReadMangaActivity.kt`: L220 (mangaPreDownloadNum) | `manga_reader_page.dart`: L82 (cacheExtent) | **Logic Gap** | Android 支援精確控制圖片預加載數量且與 Glide 深度整合；iOS 目前依賴 ListView 基礎快取，缺乏專門的漫畫圖片調度引擎。 |
| **13.4 自動捲動功能** | `ReadMangaActivity.kt`: L368 (scrollBy) | - | **Logic Gap** | iOS 目前完全缺失自動捲動 (Auto Scroll) 漫畫的功能。 |
| **13.5 頁尾資訊條 (InfoBar)** | `ReadMangaActivity.kt`: L303 (upInfoBar) | - | **Logic Gap** | Android 支援顯示精確頁碼、電量、時間與百分比進度條；iOS 僅在選單展開時顯示章節進度。 |
| **13.6 濾鏡與 E-Ink 適配** | `ReadMangaActivity.kt`: L202 (MangaColorFilterConfig) | `manga_reader_page.dart`: L103 (brightness) | **Logic Gap** | Android 支援複雜的色彩濾鏡、灰色模式及 E-Ink 優化；iOS 僅提供基礎的螢幕亮度覆蓋。 |
| **13.7 進度雲端同步** | `ReadMangaActivity.kt`: L342 (syncProgress) | - | **Logic Gap** | iOS 目前尚未實作漫畫閱讀進度與 WebDav 或伺服器端的雙向同步。 |
| **14.1 九宮格點擊區域** | `ReadBookActivity.kt`: L1000+ (onTouch) | `reader_page.dart`: L95 (onTapUp) | **Matched** | 均支援將螢幕劃分為九宮格並自定義各區域的點擊動作（選單、翻頁等）。 |
| **14.2 翻頁動畫支援** | `ReadView.kt` | `reader_page.dart`: L135 (PageView) | **Logic Gap** | Android 支援覆蓋、翻書、幻燈片、滾輪等多種動畫；iOS 目前主要依賴 PageView 的水平/垂直平滑滑動及模擬覆蓋。 |
| **14.3 內容替換規則** | `ContentProcessor.kt` | `reader_provider.dart`: L250 (processContent) | **Matched** | 均支援在加載章節時即時應用正則替換規則。 |
| **14.4 文字選取與查詞** | `TextActionMenu.kt` | `reader_page.dart`: L125 (SelectionArea) | **Equivalent** | Android 使用自定義彈窗選單；iOS 使用系統原生 SelectionArea 配合自定義 ContextMenu。 |
| **14.5 長章節自動分割** | `ReadBookViewModel.kt`: L500 (splitChapter) | - | **Logic Gap** | iOS 目前缺乏針對單章節超長文本（如 500kb+）在加載時自動分割為虛擬子章節的邏輯。 |
| **14.6 朗讀背景服務** | `BaseReadAloudService.kt` | `reader_provider.dart`: L305 (TTSService) | **Equivalent** | Android 擁有獨立後台 Service 確保進程穩定性；iOS 依賴 Flutter 插件在背景執行，但在系統資源回收時穩定性略遜。 |
| **14.7 全書內容搜尋** | `SearchContentActivity.kt` | `reader_provider.dart`: L330 (searchContent) | **Matched** | 均支援在已快取的章節中進行全文關鍵字搜尋。 |
| **14.8 進度雲端同步** | `ReadBookActivity.kt`: L342 (syncProgress) | - | **Logic Gap** | iOS 目前在啟動閱讀器時缺少與雲端進度（WebDav）的比對與主動恢復提示邏輯。 |
| **15.1 併發搜尋機制** | `SearchViewModel.kt`: L150 (coroutine) | `search_provider.dart`: L85 (Future.wait) | **Matched** | 均採用非同步併發模式在多個書源中同時進行網路搜尋。 |
| **15.2 結果聚合與去重** | `SearchViewModel.kt`: L230 (aggregate) | `search_provider.dart`: L130 (_aggregateResults) | **Matched** | 均支援根據「書名+作者」對不同書源的搜尋結果進行聚合展示。 |
| **15.3 搜尋歷史與建議** | `SearchActivity.kt`: L423 (upHistory) | `search_page.dart`: L83 (_buildHistory) | **Matched** | 均支援顯示最近搜尋關鍵字並提供熱搜建議。 |
| **15.4 搜尋範圍過濾** | `SearchActivity.kt`: L115 (SearchScope) | `search_provider.dart`: L75 (setGroup) | **Equivalent** | Android 支援複雜的組合範圍選擇；iOS 目前僅支援單一分組過濾或「全部」。 |
| **15.5 搜尋狀態手動控制** | `SearchActivity.kt`: L315 (fbStartStop) | - | **Logic Gap** | Android 提供顯式的「停止/繼續」按鈕以管理正在進行的耗時搜尋任務；iOS 僅提供進度條，無法手動中斷。 |
| **15.6 精準搜尋模式** | `SearchActivity.kt`: R.id.menu_precision_search | - | **Logic Gap** | Android 提供「精準搜尋」開關以過濾非完全匹配的結果；iOS 目前尚未實作此過濾邏輯。 |
| **15.7 空結果引導提示** | `SearchActivity.kt`: L523 (alert) | - | **Logic Gap** | Android 在分組搜尋為空時會主動引導切換範圍或關閉精準搜尋；iOS 僅顯示空狀態。 |
| **16.1 全書內文檢索邏輯** | `SearchContentActivity.kt`: L168 (startContentSearch) | `reader_provider.dart`: L403 (searchContent) | **Matched** | 均支援遞迴掃描全書已快取章節的內文，尋找關鍵字並返回片段。 |
| **16.2 搜尋狀態控管** | `SearchContentActivity.kt`: L125 (fbStop) | - | **Logic Gap** | Android 支援在搜尋過程中手動停止檢索；iOS 採用 await 模式，無法在中途手動中斷。 |
| **16.3 搜尋結果定位** | `SearchContentActivity.kt`: L202 (openSearchResult) | `reader_page.dart`: L335 (onTap) | **Matched** | 均支援點擊搜尋結果後自動跳轉至對應章節。 |
| **16.4 替換規則套用** | `SearchContentActivity.kt`: L88 (menu_enable_replace) | - | **Logic Gap** | Android 可切換搜尋時是否套用正則替換規則；iOS 目前僅對加載後的內容套用規則，搜尋時使用的是原始快取文本。 |
| **16.5 下一處/上一處定位** | `SearchContentActivity.kt`: L112 (ivSearchContentTop/Bottom) | - | **Logic Gap** | Android 提供快速跳轉至首個/最後一個結果的按鈕；iOS 僅提供列表捲動。 |
| **17.1 多維度書源導入** | `BookSourceActivity.kt`: L120 (importDoc) | `source_manager_page.dart`: L220 (_scanQrCode) | **Matched** | 均支援掃碼、網路 URL、本地文件/剪貼簿導入書源。 |
| **17.2 書源校驗機制** | `CheckSource.kt` | `source_manager_page.dart`: L80 (checkService) | **Matched** | 均具備背景校驗書源有效性、紀錄響應時間並顯示進度的功能。 |
| **17.3 批量操作與管理** | `BookSourceActivity.kt`: L385 (SelectActionBar) | `source_manager_page.dart`: L185 (_buildBatchBottomBar) | **Matched** | 均支援進入批量模式進行校驗、匯出、刪除與啟用/禁用。 |
| **17.4 分組過濾與語法** | `BookSourceActivity.kt`: L285 (searchKey) | `source_manager_page.dart`: L115 (_buildGroupFilter) | **Equivalent** | Android 支援 `group:` 語法與多種預設分組；iOS 提供水平滑動的 FilterChip 進行分組切換。 |
| **17.5 高級排序演算法** | `BookSourceActivity.kt`: L295 (BookSourceSort) | - | **Logic Gap** | Android 支援按權重、URL、響應時間、更新時間等多維度排序；iOS 目前僅有默認排序。 |
| **17.6 域名聚合顯示** | `BookSourceActivity.kt`: L180 (groupSourcesByDomain) | - | **Logic Gap** | Android 支援按 Domain 聚合顯示書源以優化同站管理；iOS 尚未實作此視圖。 |
| **17.7 拖拽排序與持久化** | `ItemTouchCallback.kt` | - | **Logic Gap** | Android 支援手動拖拽調整書源權重順序；iOS 目前列表順序固定。 |
| **18.1 目錄/書籤雙標籤** | `TocActivity.kt`: L235 (TabFragmentPageAdapter) | - | **Logic Gap** | Android 採用 Tab 頁面同時管理目錄與書籤；iOS 的目錄位於詳情頁或閱讀器側邊欄，書籤則散落在全域書籤頁或需進階 UI 整合。 |
| **18.2 目錄搜尋與過濾** | `TocActivity.kt`: L100 (searchView) | `book_detail_page.dart`: L165 (_showSearchTocDialog) | **Matched** | 均支援透過關鍵字即時過濾章節標題。 |
| **18.3 目錄倒序排列** | `TocActivity.kt`: L145 (menu_reverse_toc) | `book_detail_page.dart`: L75 (toggleSort) | **Matched** | 均支援目錄標題的正序/倒序切換顯示。 |
| **18.4 自定義 TOC 正則** | `TocActivity.kt`: L135 (menu_toc_regex) | - | **Logic Gap** | Android 支援針對本地 TXT 手動輸入正則表達式解析目錄；iOS 目前依賴預設的 TxtParser 邏輯。 |
| **18.5 章節字數統計** | `TocActivity.kt`: L160 (menu_load_word_count) | - | **Logic Gap** | Android 支援在目錄列表中顯示每個章節的字數預算；iOS 目前僅顯示標題。 |
| **18.6 書籤匯出功能** | `TocActivity.kt`: L165 (menu_export_bookmark) | - | **Logic Gap** | Android 支援將單本書籍的書籤匯出為 JSON 或 Markdown；iOS 目前缺失此導出路徑。 |
| **19.1 Cookie 雙向同步** | `CookieStore.kt` | `browser_page.dart`: L50 (_captureCookies) | **Matched** | 均支援在網頁加載完成後擷取 Cookie 並同步至 App 全域儲存。 |
| **19.2 Cloudflare 挑戰自動識別** | `WebViewActivity.kt`: L300 (isCloudflareChallenge) | - | **Logic Gap** | Android 支援自動檢測 CF 驗證頁面並在通過後自動保存結果；iOS 僅提供基礎網頁展示，需手動操作。 |
| **19.3 聯機導入 Scheme 攔截** | `WebViewActivity.kt`: L315 (shouldOverrideUrlLoading) | - | **Logic Gap** | Android 可攔截 `legado://` 等私有協定觸發導入；iOS 目前僅處理標準 http/https 請求。 |
| **19.4 長按交互與圖片保存** | `WebViewActivity.kt`: L165 (OnLongClickListener) | - | **Logic Gap** | Android 支援長按網頁圖片進行保存或選取目錄；iOS 尚未實作此 WebView 擴展。 |
| **19.5 全屏模式與系統列控制** | `WebViewActivity.kt`: L125 (toggleFullScreen) | - | **Logic Gap** | Android 支援一鍵進入網頁全屏模式並隱藏系統狀態列；iOS 採用標準頁面模式。 |
| **19.6 自定義下載攔截** | `WebViewActivity.kt`: L185 (setDownloadListener) | - | **Logic Gap** | Android 支援攔截網頁下載請求並導向 App 內建下載器；iOS 依賴 WebView 默認處理或無反應。 |
| **20.1 WebDav 全量備份** | `Backup.kt`: L115 (backup) | `webdav_service.dart`: L65 (backup) | **Equivalent** | 均支援將資料庫內容序列化為 JSON 並打包為 ZIP 上傳至 WebDav。 |
| **20.2 備份項目完整度** | `Backup.kt`: L85 (backupFileNames) | `webdav_service.dart`: L80 | **Logic Gap** | Android 備份 20+ 個項目（含 SharedPreferences）；iOS 目前僅備份書架、書源、規則、分組、書籤、記錄等核心資料庫項。 |
| **20.3 自動備份觸發** | `Backup.kt`: L100 (autoBack) | - | **Logic Gap** | Android 支援啟動時根據時間間隔自動執行 WebDav 備份；iOS 目前僅有手動備份觸發。 |
| **20.4 設備名稱區分** | `Backup.kt`: L90 (getNowZipFileName) | - | **Logic Gap** | Android 備份檔名包含設備名稱以防多設備覆蓋；iOS 目前採用固定時間戳檔名。 |
| **20.5 備份加密 (AES)** | `Backup.kt`: L118 (aes.encrypt) | - | **Logic Gap** | Android 支援對備份中的敏感資訊（如密碼、伺服器）進行 AES 加密；iOS 目前為純 JSON 儲存。 |
| **20.6 背景圖片同步** | `Backup.kt`: L235 (upBgs) | - | **Logic Gap** | Android 支援同步閱讀器的自定義背景圖片至 WebDav；iOS 尚未實作圖片資源的同步邏輯。 |
| **20.7 閱讀進度單獨同步** | `AppWebDav.kt`: L300 (uploadBookProgress) | `webdav_service.dart`: L125 (uploadBookProgress) | **Matched** | 均支援針對單本書籍即時同步閱讀進度至 WebDav。 |









