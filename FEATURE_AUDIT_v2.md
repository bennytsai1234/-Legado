# FEATURE_AUDIT_v2.md

## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| 01 | 閱讀主界面 | 95% | ✅ | 高度對齊，包含 WebDAV 同步、分頁與 TTS |
| 02 | 書架主頁 | 90% | ✅ | 支援分組、排序與併發更新，實現深度對標 Android |
| 03 | 書籍詳情 | - | ⏳ | 待審計 |
| ... | ... | ... | ... | ... |

---

## 01. 閱讀主界面

**模組職責**：書籍內容載入、分頁演算、閱讀狀態（進度、字體、主題）管理、TTS 播放與 WebDAV 同步。
**Legado 檔案**：`ReadBook.kt`, `ReadBookViewModel.kt`, `ContentProcessor.kt`
**Flutter (iOS) 對應檔案**：`reader_provider.dart`, `chapter_provider.dart`, `content_processor.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **WebDAV 進度同步**：啟動同步與關閉/載入時上傳。
- ✅ **章節快取與載入**：支援本地快取、網路載入及預載下一章。
- ✅ **分頁演算**：基於 `viewSize` 與樣式進行動態分頁。
- ✅ **TTS 支援**：支援系統 TTS 與自定義 HTTP TTS（對標 Legado 核心功能）。
- ✅ **書籤管理**：支援書籤添加、刪除與快照生成。

**不足之處**：
- [ ] **多執行緒分頁**：Android 端使用 `mapParallelSafe` 加速，iOS 目前為單執行緒 `_doPaginate`。
- [ ] **精確搜尋細節**：Android 支援全書正則搜尋，iOS 目前為簡單子字串搜尋。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **1.1 進度上傳** | `ReadBook.kt`: L240 (uploadProgress) | `reader_provider.dart`: L460 (dispose) | **Matched** | 兩端均在關閉時觸發 WebDAV 上傳 |
| **1.2 章節載入** | `ReadBook.kt`: L301 (loadContent) | `reader_provider.dart`: L301 (loadChapter) | **Matched** | 邏輯一致：檢查快取 -> 網路請求 -> 保存快取 |
| **1.3 進度同步** | `ReadBook.kt`: L260 (syncProgress) | `reader_provider.dart`: L130 (_init) | **Matched** | 啟動時均會調用 WebDAV 同步 |
| **1.4 內容清洗** | `ContentProcessor.kt` | `content_processor.dart` | **Matched** | 處理正則替換與簡繁轉換邏輯對等 |
| **1.5 預載邏輯** | `ReadBook.kt`: L87 (preDownloadTask) | `reader_provider.dart`: L333 (_preloadNextChapter) | **Matched** | 支援非同步預載下一章內容 |
| **1.6 TTS 控制** | `ReadAloud.kt` | `reader_provider.dart`: L408 (toggleTts) | **Equivalent** | iOS 整合了系統與 HTTP TTS 雙模切換 |
| **1.7 點擊動作** | `AppConfig.kt` | `reader_provider.dart`: L115 (setClickAction) | **Matched** | 九宮格區域動作配置完全對標 |

---

## 02. 書架主頁

**模組職責**：書籍展示、分組過濾、批量操作、自動/手動更新、排序管理。
**Legado 檔案**：`BaseBookshelfFragment.kt`, `BookshelfViewModel.kt`, `BookDao.kt`
**Flutter (iOS) 對應檔案**：`bookshelf_page.dart`, `bookshelf_provider.dart`, `book_dao.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **書籍分組**：支援多選分組，底層使用位元運算儲存（對標 Android `group` 欄位）。
- ✅ **多維排序**：支援手動、最後閱讀、更新時間、書名、作者排序。
- ✅ **併發更新**：支援設定線程數進行書籍檢查（對標 Android `threadCount`）。
- ✅ **批量操作**：支援刪除、移動分組、全選/反選。
- ✅ **事件同步**：使用 `AppEventBus` 進行全局書架重新整理。

**不足之處**：
- [ ] **拖拽排序**：Android 支援 UI 上的拖拽重排 Order，iOS 目前主要依賴 `reorderGroups` 但書籍層級尚待完善。
- [ ] **導入功能細節**：Android 支援網址、Json、本地多樣導入，iOS 目前側重於 `file_picker`。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **2.1 分組邏輯** | `Book.kt` (bit mask for group) | `bookshelf_provider.dart`: L86 (bitwise group check) | **Matched** | 兩端均使用位元運算處理多重分組 |
| **2.2 排序邏輯** | `BookshelfFragment.kt`: sort logic | `bookshelf_provider.dart`: L94 (switch sortMode) | **Matched** | 排序維度（手動/時間/書名）完全一致 |
| **2.3 併發更新** | `AppConfig.kt` (threadCount) | `bookshelf_provider.dart`: L263 (Pool with threadCount) | **Matched** | 均支援自定義線程數進行併發請求 |
| **2.4 更新通知** | `EventBus.UP_BOOKSHELF` | `bookshelf_provider.dart`: L51 (AppEventBus upBookshelf) | **Matched** | 事件驅動機制完全對等 |
| **2.5 批量管理** | `BookshelfFragment.kt`: onSelectionMode | `bookshelf_provider.dart`: L130 (toggleBatchMode) | **Matched** | 批量操作與狀態切換邏輯一致 |
