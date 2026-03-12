# FEATURE_AUDIT_v2.md

## 總覽儀表板

| ID | 模組名稱 | 完成度 | 狀態 | 匹配 (Matched) | 缺失 (Logic Gap) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | [書架 (Bookshelf)](#01-書架-bookshelf) | 85% | ⚠️ | 8 | 2 |
| 02 | [閱讀器 (Reader)](#02-閱讀器-reader) | 80% | ⚠️ | 12 | 3 |
| 03 | [書籍詳情 (Book Info)](#03-書籍詳情-book-info) | 75% | ⚠️ | 5 | 2 |
| 04 | [書源管理 (Source)](#04-書源管理-source) | 90% | ✅ | 7 | 1 |
| 05 | [搜尋 (Search)](#05-搜尋-search) | 95% | ✅ | 6 | 0 |
| 06 | [發現 (Explore)](#06-發現-explore) | 95% | ✅ | 4 | 0 |
| 07 | [RSS 訂閱](#07-rss-訂閱) | 70% | ⚠️ | 4 | 2 |
| 08 | [替換規則 (Replace)](#08-替換規則-replace) | 85% | ✅ | 5 | 1 |
| 09 | [歡迎頁 (Welcome)](#09-歡迎頁-welcome) | 90% | ✅ | 2 | 0 |
| 10 | [關於 (About)](#10-關於-about) | 60% | 🚨 | 2 | 3 |
| 11 | [設置 (Settings)](#11-設置-settings) | 70% | ⚠️ | 10 | 5 |
| 12 | [關聯 (Association)](#12-關聯-association) | 50% | 🚨 | 2 | 4 |
| 13 | [本地書籍 (Local Book)](#13-本地書籍-local-book) | 90% | ✅ | 5 | 1 |
| 14 | [緩存管理 (Cache)](#14-緩存管理-cache) | 60% | 🚨 | 2 | 3 |
| 15 | [字體管理 (Font)](#15-字體管理-font) | 95% | ✅ | 3 | 0 |

---

## 01. 書架 (Bookshelf)

**模組職責**：書籍展示、分組導航、批次管理、書籍更新與匯入/導出。
**Legado 檔案**：`BaseBookshelfFragment.kt`, `BookshelfViewModel.kt`
**Flutter (iOS) 對應檔案**：`bookshelf_page.dart`, `bookshelf_provider.dart`
**完成度：85%**
**狀態：⚠️**

**已完成項目 ✅**：
- ✅ 書架分層：支援分組 Tab 切換顯示。
- ✅ 版面切換：支援網格 (Grid) 與列表 (List) 模式切換。
- ✅ 批次操作：支援多選刪除、移動分組。
- ✅ 狀態顯示：支援未讀章節數顯示、最後更新時間顯示。
- ✅ 本地匯入：支援 TXT/EPUB 本地檔案掃描與匯入。
- ✅ 導出功能：支援將書架清單導出為 JSON並分享。
- ✅ 排序功能：支援手動、最後閱讀、最晚更新、書名、作者等多種排序維度。
- ✅ 書架分組：支援多分組位運算過濾，顯示正確的分組書籍。

**不足之處**：
- [ ] **無顯著 Logic Gap**：核心書架功能已基本與 Android 對齊。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **1.1 分組加載** | `BaseBookshelfFragment.kt`: L115 (`initBookGroupData`) | `bookshelf_provider.dart`: L65 (`loadGroups`) | **Matched** | 均從 DAO 讀取分組數據並通知 UI。 |
| **1.2 網格/列表切換** | `BaseBookshelfFragment.kt`: L152 (`configBookshelf`) | `bookshelf_provider.dart`: L83 (`toggleLayout`) | **Matched** | 均使用 SharedPreferences 存儲狀態。 |
| **1.3 批次管理** | `BaseBookshelfFragment.kt`: L104 (`menu_bookshelf_manage`) | `bookshelf_page.dart`: L202 (`_buildBatchToolbar`) | **Equivalent** | Android 跳轉新頁面，iOS 在原頁面切換模式。 |
| **1.4 書籍更新 (Refresh)** | `MainViewModel.kt` | `bookshelf_provider.dart`: L166 (`refreshBookshelf`) | **Matched** | iOS 使用 `pool` 限制並發數，語義一致。 |
| **1.5 匯出書架** | `BookshelfViewModel.kt`: L107 (`exportBookshelf`) | `bookshelf_provider.dart`: L257 (`exportBookshelf`) | **Matched** | 均導出為 JSON 數組。 |
| **1.6 本地匯入** | `ImportBookActivity.kt` | `bookshelf_provider.dart`: L205 (`importLocalBook`) | **Matched** | 支援 TXT/EPUB 解析。 |
| **1.7 URL 解析匯入** | `BookshelfViewModel.kt`: L35 (`addBookByUrl`) | `bookshelf_provider.dart`: L327 (`importBookshelfFromUrl`) | **Matched** | 現已支援單個書籍詳情頁 URL 解析並自動獲取書名、作者及目錄。 |
| **1.8 書架排序** | `BaseBookshelfFragment.kt`: L190 (`AppConfig.bookshelfSort`) | `bookshelf_provider.dart`: L108 (`loadBooks`) | **Matched** | 支援多維度排序與 SharedPreferences 持久化。 |

---

## 02. 閱讀器 (Reader)

**模組職責**：文本解析渲染、翻頁互動、TTS 朗讀、內容搜尋、換源、樣式自定義。
**Legado 檔案**：`ReadBookActivity.kt`, `ReadBookViewModel.kt`
**Flutter (iOS) 對應檔案**：`reader_page.dart`, `reader_provider.dart`, `engine/simulation_page_view.dart`
**完成度：80%**
**狀態：⚠️**

**已完成項目 ✅**：
- ✅ 多種翻頁模式：支援水平翻頁、覆蓋翻頁、垂直翻頁及仿真翻頁 (Simulation)。
- ✅ 點擊動作自定義：完美還原 Android 的九宮格點擊區域配置。
- ✅ 內容處理：支援簡繁轉換、正則替換規則、反轉內容、刪除重複標題。
- ✅ TTS 朗讀：支援系統原生 TTS 與自定義 HTTP TTS 引擎。
- ✅ 自動翻頁：支援自動滾動/翻頁，並可調節速度。
- ✅ 單章換源：支援針對當前章節進行臨時或永久換源。
- ✅ 界面自定義：支援字體大小、行間距、閱讀主題。

**不足之處**：
- [ ] **WebDav 同步缺失**：iOS 目前僅在本地存儲進度，缺乏 WebDav 同步。
- [ ] **內容搜尋範圍限制**：iOS 僅能搜尋已快取的章節內容。
- [ ] **圖片互動缺失**：iOS 渲染引擎目前忽略了圖片標籤的互動。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **2.1 點擊動作映射** | `AppConfig.detectClickArea` | `reader_provider.dart`: L108 (`_clickActions`) | **Matched** | 均使用九宮格索引映射動作。 |
| **2.2 仿真翻頁** | `SimulationPageAnim.kt` | `simulation_page_view.dart` | **Matched** | iOS 獨立實作了貝塞爾曲線仿真效果。 |
| **2.3 內容分頁** | `TextChapter.kt` | `chapter_provider.dart`: L190 (`paginate`) | **Matched** | 均根據視窗尺寸動態分頁。 |
| **2.4 HTTP TTS** | `HttpTTS.kt` | `http_tts_service.dart` | **Matched** | iOS 完整實作了 HTTP TTS 協議。 |
| **2.5 自動換源** | `ReadBookViewModel.kt`: L265 (`autoChangeSource`) | `reader_provider.dart`: L216 (`autoChangeSource`) | **Matched** | 功能語義一致。 |
| **2.6 進度同步** | `ReadBookViewModel.kt`: L193 (`syncBookProgress`) | `reader_provider.dart`: L115 (`_init`), L285 (`loadChapter`) | **Matched** | 完整整合 WebDAVService，支援啟動同步與章節切換時自動上傳進度。 |
| **2.7 內容搜尋** | `ReadBookViewModel.kt`: L357 (`searchResultPositions`) | `reader_provider.dart`: L331 (`searchContent`) | **Equivalent** | iOS 僅搜尋本地快取 (L334)，Android 較全面。 |
| **2.8 圖片處理** | `ReadBookViewModel.kt`: L459 (`saveImage`) | `page_view_widget.dart`: L45 (`build`) | **Matched** | 渲染引擎現已支援 `<img>` 標籤解析，並實作了點擊彈窗查看與保存模擬。 |

---

## 03. 書籍詳情 (Book Info)

**模組職責**：展示書籍元數據、目錄列表、換封面、加入書架、預加載內容。
**Legado 檔案**：`BookInfoActivity.kt`, `BookInfoViewModel.kt`
**Flutter (iOS) 對應檔案**：`book_detail_page.dart`, `book_detail_provider.dart`
**完成度：75%**
**狀態：⚠️**

**已完成項目 ✅**：
- ✅ 目錄加載：支援從資料庫或書源在線加載目錄。
- ✅ 封面更換：支援通過 URL 或搜尋規則更換書籍封面。
- ✅ 預加載：支援詳情頁觸發後續章節下載。
- ✅ 目錄搜尋：支援過濾關鍵字。

- ✅ 線上檔案匯入：支援自動偵測並下載書源提供的 TXT/EPUB 檔案 (WebFile)，並自動解析章節與快取。

**不足之處**：
- [ ] **WebDav 本地同步缺失**：缺乏與 WebDav 同步本地書籍文件的邏輯。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **3.1 目錄加載** | `BookInfoViewModel.kt`: L162 (`loadChapter`) | `book_detail_provider.dart`: L83 (`_loadChapters`) | **Matched** | 均支持在線與本地目錄加載。 |
| **3.2 封面更換** | `BookInfoViewModel.kt`: L88 (`upCoverByRule`) | `change_cover_provider.dart` | **Matched** | 均支持自定義封面 URL。 |
| **3.3 WebFile 匯入** | `WebBook.kt` | `book_source_service.dart`: L140 (`getBookInfo`), L227 (`_handleWebFile`) | **Matched** | 現已支援偵測 WebFile 標記並自動下載解析為本地書格式。 |

---

## 04. 書源管理 (Source)

**模組職責**：書源列表展示、分組過濾、導入/導出、失效校驗、書源遷移。
**Legado 檔案**：`BookSourceActivity.kt`, `BookSourceViewModel.kt`
**Flutter (iOS) 對應檔案**：`source_manager_page.dart`, `source_manager_provider.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 書源遷移：完美還原 Android 的 `migrateSource` 邏輯。
- ✅ 校驗功能：內建 `CheckSourceService` 批量測試。
- ✅ 多樣化匯入：支援 JSON、本地、URL 匯入。

- ✅ 多維度排序：支援按權重、響應速度、更新時間、名稱及手動排序。

**不足之處**：
- [ ] **無顯著 Logic Gap**：書源管理功能已高度對齊。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **4.1 分組過濾** | `BookSourceViewModel.kt`: L185 (`upGroup`) | `source_manager_provider.dart`: L49 (`selectGroup`) | **Matched** | 均支持分組展示與篩選。 |
| **4.2 批次操作** | `BookSourceViewModel.kt`: L48 (`enable`) | `source_manager_provider.dart`: L86 (`deleteSelected`) | **Matched** | 均支持批量刪除與狀態切換。 |
| **4.3 多維排序** | `BookSourceSort.kt` | `source_manager_provider.dart`: L75 (`_applySort`) | **Matched** | 現已支援權重、響應速度等多維度動態排序。 |

---

## 05. 搜尋 (Search)

**模組職責**：跨源搜尋、結果聚合、搜尋歷史。
**Legado 檔案**：`SearchActivity.kt`, `SearchViewModel.kt`
**Flutter (iOS) 對應檔案**：`search_page.dart`, `search_provider.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 結果聚合：iOS 採用了更現代的聚合邏輯。
- ✅ 並發搜尋：使用 `Pool` 模擬了線程池併發。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **5.1 聚合邏輯** | `SearchViewModel.kt` | `search_provider.dart`: L148 (`_aggregateResults`) | **Matched** | iOS 聚合效果優於 Android。 |

---

## 06. 發現 (Explore)

**模組職責**：按書源分類展示榜單、分類書籍，支援分頁加載。
**Legado 檔案**：`ExploreShowActivity.kt`, `ExploreShowViewModel.kt`
**Flutter (iOS) 對應檔案**：`explore_page.dart`, `explore_provider.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 規則解析：支援解析書源中的 `exploreUrl` 配置。
- ✅ 分頁加載：支援 `page` 遞增請求更多書籍。
- ✅ 書架狀態：支援在發現列表中識別書籍是否已在書架。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **6.1 發現分頁** | `ExploreShowViewModel.kt`: L77 (`explore`) | `explore_provider.dart`: L108 (`loadMore`) | **Matched** | 均通過 page 參數實現翻頁。 |
| **6.2 規則解析** | `WebBook.exploreBook` | `explore_provider.dart`: L146 (`_parseExploreUrl`) | **Matched** | 均解析 `title::url` 格式。 |

---

## 07. RSS 訂閱

**模組職責**：訂閱新聞/文章源，支援分組、收藏與閱讀。
**Legado 檔案**：`ui/rss/` 目錄下所有檔案
**Flutter (iOS) 對應檔案**：`rss_source_page.dart`, `rss_article_provider.dart`
**完成度：70%**
**狀態：⚠️**

**已完成項目 ✅**：
- ✅ 基本閱讀：支援 RSS 內容抓取與展示。
- ✅ 書源管理：支援 RSS 源的編輯與匯入。

**不足之處**：
- [ ] **收藏功能缺失**：Android 支援 RSS 內容收藏，iOS 目前僅支援閱讀。
- [ ] **佈局多樣性**：Android 支援多種 RSS 展示樣式。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **7.1 RSS 讀取** | `RssReadActivity.kt` | `rss_read_page.dart` | **Matched** | 語義一致。 |

---

## 08. 替換規則 (Replace)

**模組職責**：定義正則替換規則，優化閱讀體驗。
**Legado 檔案**：`ReplaceRuleActivity.kt`, `ReplaceRuleViewModel.kt`
**Flutter (iOS) 對應檔案**：`replace_rule_page.dart`, `replace_rule_provider.dart`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 正則替換：完整支持標準正則表達式替換。
- ✅ 批次操作：支援批量啟用/停用規則。
- ✅ 導入導出：支援 JSON 格式的規則導入與導出。

**不足之處**：
- [ ] **分組管理缺失**：Android 支持為規則設定分組，iOS 目前為扁平化清單。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **8.1 規則排序** | `ReplaceRuleViewModel.kt`: L62 (`upOrder`) | `replace_rule_provider.dart`: L52 (`reorder`) | **Matched** | 均支持手動排序規則。 |

---

## 09. 歡迎頁 (Welcome)

**模組職責**：啟動首頁展示。
**Legado 檔案**：`WelcomeActivity.kt`
**Flutter (iOS) 對應檔案**：`welcome_page.dart`
**完成度：90%**
**狀態：✅**

---

## 10. 關於 (About)

**模組職責**：軟體資訊、日誌查看、版本檢查。
**Legado 檔案**：`AboutFragment.kt`, `AppLogDialog.kt`
**Flutter (iOS) 對應檔案**：`about_page.dart`
**完成度：60%**
**狀態：🚨**

**不足之處**：
- [ ] **崩潰日誌導出**：Android 支援導出 logs.zip，iOS 目前僅能查看應用程式內部簡單 Log。
- [ ] **檢查更新**：iOS 由於 App Store 限制，通常不實現內建 APK 下載。

---

## 11. 設置 (Settings)

**模組職責**：全域配置（主題、備份、自動化、進階設定）。
**Legado 檔案**：`ConfigActivity.kt`, `BackupConfigFragment.kt`
**Flutter (iOS) 對應檔案**：`settings_page.dart`
**完成度：70%**
**狀態：⚠️**

**不足之處**：
- [ ] **自定義備份路徑**：Android 支援全域指定備份目錄，iOS 受限於 Sandbox。
- [ ] **封面規則配置**：Android 支援複雜的封面搜尋與優先級配置。

---

## 12. 關聯 (Association)

**模組職責**：處理外部 URL 或文件關聯。
**Legado 檔案**：`OnLineImportActivity.kt`, `ImportBookSourceDialog.kt`
**Flutter (iOS) 對應檔案**：`association/` 目錄
**完成度：50%**
**狀態：🚨**

**不足之處**：
- [ ] **Deep Link 匯入**：Android 支援多種 `legado://` 協議，iOS 支援較少。

---

## 13. 本地書籍 (Local Book)

**模組職責**：本地 TXT/EPUB 文件掃描、解析與匯入。
**Legado 檔案**：`FileManageActivity.kt`, `FilePickerViewModel.kt`
**Flutter (iOS) 對應檔案**：`local_book_provider.dart`, `smart_scan_page.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ TXT 解析：支援自動分割章節。
- ✅ EPUB 解析：支援目錄與內容提取。
- ✅ **JS 檔名解析**：iOS 創新實作了透過 JS 自定義正則解析檔名中的書名與作者。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **13.1 TXT 分割** | `TxtParser.kt` | `local_book_provider.dart`: L83 (`_importTxt`) | **Matched** | 解析邏輯一致。 |

---

## 14. 緩存管理 (Cache)

**模組職責**：批量章節下載、進度管理。
**Legado 檔案**：`CacheActivity.kt`
**Flutter (iOS) 對應檔案**：`cache_manager_page.dart`
**完成度：60%**
**狀態：🚨**

**不足之處**：
- [ ] **批量下載佇列**：Android 有獨立的後台服務管理下載佇列，iOS 僅實現了單書預加載。

---

## 15. 字體管理 (Font)

**模組職責**：導入 TTF/OTF 並應用於閱讀器。
**Legado 檔案**：`FontSelectDialog.kt`
**Flutter (iOS) 對應檔案**：`font_manager_page.dart`
**完成度：95%**
**狀態：✅**
