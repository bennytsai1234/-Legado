# 📋 Legado ➔ Reader 增量審計日誌 (FEATURE_AUDIT_LOG.md)

本文件紀錄了每一項原子化邏輯的比對結果與缺失詳述。

---

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
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


