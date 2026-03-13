# FEATURE_AUDIT_v2.md

## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| 01 | 閱讀主界面 | 95% | ✅ | 高度對齊，包含 WebDAV 同步、分頁與 TTS |
| 02 | 書架主頁 | 90% | ✅ | 支援分組、排序與併發更新，實現深度對標 Android |
| 03 | 書籍詳情 | 95% | ✅ | 支援本地解析(TXT/EPUB)與 WebDAV 下載適配 |
| 04 | 書源管理 | 90% | ✅ | 包含書源遷移、導入及校驗服務集成 |
| 05 | 搜尋功能 | 85% | ✅ | 支援併發搜尋、結果聚合與搜尋範圍過濾 |
| 06 | 發現/探索 | - | ⏳ | 待審計 |
| ... | ... | ... | ... | ... |

---

## 01. 閱讀主界面
... (省略，保持原樣)

---

## 02. 書架主頁
... (省略，保持原樣)

---

## 03. 書籍詳情

**模組職責**：書籍詳情展示、目錄載入、書架狀態管理、本地書籍解析、WebDAV 檔案同步。
**Legado 檔案**：`BookInfoActivity.kt`, `BookInfoViewModel.kt`, `LocalBook.kt`
**Flutter (iOS) 對應檔案**：`book_detail_page.dart`, `book_detail_provider.dart`, `txt_parser.dart`, `epub_parser.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **本地解析**：iOS 專屬 `TxtParser` 與 `EpubParser`（對標 Android `LocalBook`）。
- ✅ **WebDAV 適配**：支援本地書籍缺失時自動從 WebDAV 下載（深度適配）。
- ✅ **詳情載入**：支援從搜尋結果轉換或書源請求詳情。
- ✅ **緩存管理**：支援清理章節內容緩存。

**不足之處**：
- [ ] **封面搜尋**：Android 支援 `BookCover.searchCover` 全網搜封面，iOS 目前主要依賴書源提供的封面。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **3.1 詳情載入** | `BookInfoViewModel.kt`: L168 (loadBookInfo) | `book_detail_provider.dart`: L98 (_loadChapters) | **Matched** | 兩端邏輯一致：檢查本地 -> 載入目錄 |
| **3.2 本地同步** | `BookInfoViewModel.kt`: L138 (refreshBook) | `book_detail_provider.dart`: L101 (WebDAVService download) | **Matched** | 均支援 WebDAV 檔案缺失補全 |
| **3.3 書架狀態** | `BookInfoViewModel.kt`: L77 (inBookshelf) | `book_detail_provider.dart`: L143 (toggleInBookshelf) | **Matched** | 加入/移出書架與數據庫同步一致 |
| **3.4 章節過濾** | `BookInfoActivity.kt`: search in TOC | `book_detail_provider.dart`: L39 (filteredChapters) | **Matched** | 支援目錄關鍵字搜尋與正反序切換 |

---

## 04. 書源管理

**模組職責**：書源 CRUD、導入（URL/Text/QR）、分組管理、書源遷移、有效性校驗。
**Legado 檔案**：`BookSourceViewModel.kt`, `SourceHelp.kt`, `BookSourceDao.kt`
**Flutter (iOS) 對應檔案**：`source_manager_page.dart`, `source_manager_provider.dart`, `check_source_service.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **書源導入**：支援 URL 批量導入、剪貼簿 Json 導入（對標 Android `importSource`）。
- ✅ **書源遷移**：支援 `migrateSource` 將書籍從舊源遷移至新源（深度對齊）。
- ✅ **批量管理**：支援批量啟用/禁用、刪除、導出。
- ✅ **校驗服務**：集成 `CheckSourceService` 進行書源有效性自動檢查。

**不足之處**：
- [ ] **書源編輯器**：iOS 端目前側重於 Json 或 URL 匯入，細粒度的規則編輯（UI）尚不如 Android 完整。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **4.1 書源遷移** | `SourceHelp.kt`: migrateSource | `source_manager_provider.dart`: L152 (migrateSource) | **Matched** | 核心邏輯完全一致：更新所有關聯書籍的 origin |
| **4.2 分組過濾** | `BookSourceViewModel.kt`: getBookSources | `source_manager_provider.dart`: L25 (where by group) | **Matched** | 支援多選分組過濾顯示 |
| **4.3 書源校驗** | `SourceDebug.kt` | `source_manager_provider.dart`: L144 (checkService.check) | **Equivalent** | iOS 使用專用服務類進行背景校驗 |
| **4.4 排序管理** | `BookSourceViewModel.kt`: top/bottomSource | `source_manager_provider.dart`: L58 (_applySort) | **Matched** | 均支援權重、響應速度與手動排序 |

---

## 05. 搜尋功能

**模組職責**：多書源並發搜尋、搜尋結果去重聚合、歷史記錄管理、搜尋範圍設定。
**Legado 檔案**：`SearchViewModel.kt`, `SearchModel.kt`, `SearchHistoryDao.kt`
**Flutter (iOS) 對應檔案**：`search_page.dart`, `search_provider.dart`, `search_history_dao.dart`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **併發搜尋**：使用 `Pool` 控制線程數（對標 Android `threadCount`）。
- ✅ **結果聚合**：依據書名+作者對不同來源進行去重聚合（對標 Android `AggregatedSearchBook`）。
- ✅ **搜尋範圍**：支援按分組搜尋（對標 Android `SearchScope`）。
- ✅ **搜尋歷史**：完整實現歷史記錄的新增、刪除與清理。

**不足之處**：
- [ ] **站內搜尋**：Android 在搜尋時可動態切換單站/全網，iOS 目前在 `SearchProvider` 雖有 `searchInSource` 但 UI 整合度較低。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **5.1 併發控制** | `AppConfig.kt` (threadCount) | `search_provider.dart`: L104 (searchPool with threadCount) | **Matched** | 均支援根據設定控制併發請求量 |
| **5.2 結果聚合** | `SearchModel.kt`: aggregate | `search_provider.dart`: L162 (_aggregateResults) | **Matched** | 聚合邏輯（書名+作者去重）對等 |
| **5.3 歷史記錄** | `SearchHistoryDao.kt` | `search_provider.dart`: L80 (add/loadHistory) | **Matched** | 使用本地數據庫持久化歷史記錄 |
| **5.4 搜尋終止** | `SearchModel.kt`: cancelSearch | `search_provider.dart`: L24 (stopSearch) | **Matched** | 均支援中途取消進行中的搜尋任務 |
