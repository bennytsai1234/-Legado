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
