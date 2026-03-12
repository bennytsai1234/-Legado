# Legado 模組 01-10 跨平台邏輯審計報告 (證據鏈版)

**審計日期**：2026-03-12  
**審計目標**：針對 1-10 模組進行原子化邏輯比對，確保 Android (Kotlin) 與 iOS (Flutter) 實作一致性。

---

## 📋 深度邏輯比對總表

| 模組 | 極細顆粒度邏輯點 (Logic Fingerprint) | Android 證據鏈 (檔案路徑:行號) | iOS 證據鏈 (檔案路徑:行號) | 狀態標註 | 缺失詳述 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **01. Main** | 1.1 BNV 雙擊回頂部/壓縮邏輯 (300ms) | `MainActivity.kt`: L138-157 | `lib/main.dart`: L415-425 | **Matched** | - |
| | 1.2 動態更新計數 Badge 顯示 | `MainViewModel.kt`: L166 | `lib/main.dart`: L435-460 | **Matched** | - |
| | 1.3 啟動崩潰偵測與彈窗提醒 | `MainActivity.kt`: L104 | `lib/main.dart`: L305, L45-55 | **Matched** | - |
| | 1.4 啟動版本號比對與更新日誌彈窗 | `MainActivity.kt`: L102 | `lib/main.dart`: L249-272 | **Matched** | - |
| | 1.5 啟動 WebDav 修改時間比對與同步提示 | `MainActivity.kt`: L105 | `lib/main.dart`: L327-352 | **Matched** | - |
| **02. About** | 2.1 閱讀時長格式化邏輯 (ms -> HH:mm:ss) | `ReadRecordActivity.kt`: L129 | `about_page.dart`: L236-248 | **Matched** | - |
| | 2.2 三種排序模式 (書名/時長/最後閱讀) | `ReadRecordActivity.kt`: L141-151 | `about_page.dart`: L183-199 | **Matched** | - |
| | 2.3 閱讀記錄連動搜尋邏輯 (findByName) | `ReadRecordActivity.kt`: L183-195 | `about_page.dart`: L465-474 | **Matched** | - |
| | 2.4 全域記憶體日誌管理 (最多 500 條) | `AppLog.kt` | `about_page.dart`: L503-525 | **Matched** | - |
| **03. Assoc** | 3.1 JSON 內容特徵辨識 (bookSourceUrl 等) | `FileAssociationActivity.kt`: L71 | `intent_handler_service.dart`: L114-135 | **Matched** | - |
| | 3.2 書籍導入物理搬移 (LegadoBooks 目錄) | `FileAssociationActivity.kt`: L138 | `intent_handler_service.dart`: L85-105 | **Matched** | - |
| | 3.3 格式不支援時的強制導入機制 | `FileAssociationActivity.kt`: L90 | `intent_handler_service.dart`: L142-161 | **Matched** | - |
| **04. Audio** | 4.1 四種播放模式切換與圖示聯動 | `AudioPlayActivity.kt`: L131, L151 | `audio_play_service.dart`: L41-66 | **Matched** | - |
| | 4.2 定時睡眠倒數計時邏輯 (Timer) | `AudioPlayActivity.kt`: L190 | `audio_play_service.dart`: L101-121 | **Matched** | - |
| | 4.3 跨類型遷移跳轉 (文本 <-> 有聲) | `AudioPlayViewModel.kt`: L85 | `change_chapter_source_sheet.dart`: L286 | **Matched** | - |
| **05. Bookmk** | 5.1 依書籍分組顯示與 ExpansionTile 實作 | `AllBookmarkActivity.kt`: L55 | `bookmark_list_page.dart`: L186-210 | **Matched** | - |
| | 5.2 書籤 JSON 導出功能 | `AllBookmarkViewModel.kt`: L21 | - | **Logic Gap** | iOS 缺失 JSON 格式導出 |
| | 5.3 書籤內容/筆記編輯器 | `BookmarkDialog.kt` | - | **Logic Gap** | iOS 缺失書籤編輯 UI |
| **06. Cache** | 6.1 下載併發與全域暫停控制 (Completer) | `CacheBook.kt`: L128 | `download_service.dart`: L41-57 | **Matched** | - |
| | 6.2 調度互斥鎖 (Mutex) 防止重複啟動 | `CacheBook.kt`: L122 | `download_service.dart`: L136 | **Matched** | - |
| | 6.3 離線書籍匯出 (TXT/EPUB) | `CacheActivity.kt`: L116 | - | **Logic Gap** | iOS 缺失書籍匯出功能 |
| **07. Cover** | 7.1 並發搜尋封面演算法 (mapParallel) | `ChangeCoverViewModel.kt`: L129 | `change_cover_provider.dart`: L67-76 | **Matched** | - |
| | 7.2 搜尋結果資料庫快取優先讀取 | `ChangeCoverViewModel.kt`: L78 | - | **Logic Gap** | iOS 未優先讀取 SearchBookDao |
| | 7.3 精確過濾邏輯 (書名+作者) | `ChangeCoverViewModel.kt`: L151 | `change_cover_provider.dart`: L83-86 | **Matched** | - |
| **08. Source** | 8.1 換源優選排序 (序號/TOC/更新時間) | `ChangeBookSourceViewModel.kt`: L122 | `change_chapter_source_sheet.dart`: L100 | **Matched** | - |
| | 8.2 單章換源與目錄預覽 | `ChangeChapterSourceDialog.kt` | `change_chapter_source_sheet.dart` | **Matched** | - |
| | 8.3 換源搜尋分組過濾 | `ChangeBookSourceViewModel.kt`: L178 | - | **Logic Gap** | iOS 缺失換源時的分組限制 |
| **09. Explore** | 9.1 分組過濾 UI 與兩級解耦設計 | `ExploreFragment.kt`: L123 | `explore_page.dart`: L81-90 | **Matched** | - |
| | 9.2 搜尋框 `group:NAME` 語法連動 | `ExploreFragment.kt`: L155 | `explore_page.dart`: L67-73 | **Matched** | - |
| | 9.3 根據書源配置自動切換 列表/網格 模式 | `ExploreShowActivity.kt` | `explore_page.dart`: L133-141 | **Matched** | - |
| **10. Manage** | 10.1 64 個分組上限檢核 | `GroupManageDialog.kt`: L76 | `bookshelf_provider.dart`: L268-272 | **Matched** | - |
| | 10.2 分組拖拽排序與 Order 更新 | `GroupManageDialog.kt`: L133 | `bookshelf_provider.dart`: L305-315 | **Matched** | - |
| | 10.3 批量換源與併發 Pool 控制 | `BookshelfManageActivity.kt`: L115 | `bookshelf_provider.dart`: L316-352 | **Matched** | - |

---

## 📈 審計進度同步 (Module 1-10)

1. **模組 01 (Main)**: 完成度 95% -> **98%** (補齊證據鏈)
2. **模組 02 (About)**: 完成度 95% -> **100%** (深度對齊)
3. **模組 03 (Assoc)**: 完成度 10% -> **95%** (實質功能已存在，缺細節)
4. **模組 04 (Audio)**: 完成度 40% -> **95%** (背景服務與模式已對齊)
5. **模組 05 (Bookmk)**: 完成度 100% -> **85%** (修正：發現缺失 JSON 導出與編輯器)
6. **模組 06 (Cache)**: 完成度 80% -> **85%** (確認併發邏輯對齊，但缺匯出)
7. **模組 07 (Cover)**: 完成度 100% -> **90%** (修正：缺快取優先讀取)
8. **模組 08 (Source)**: 完成度 75% -> **90%** (單章換源已補齊)
9. **模組 09 (Explore)**: 完成度 75% -> **90%** (網格切換與語法連動已對齊)
10. **模組 10 (Manage)**: 完成度 45% -> **95%** (批量換源與併發 Pool 已對齊)
