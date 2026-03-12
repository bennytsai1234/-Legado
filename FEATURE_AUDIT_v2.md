# Legado → Flutter (iOS) 全功能審計報告 v2

**建立日期**：2026-03-12  
**審計範圍**：`legado/app/src/main/java/io/legado/app/ui/` 下所有子目錄  
**對應 iOS**：`ios/lib/` 所有功能模組  
**報告用途**：此文件同時作為「完成度追蹤器」與「B 工作流任務清單」，每次實作完畢後更新對應狀態。

---

## 📊 總覽儀表板

| 模組 | 完成度 | 狀態 | 優先級 |
|------|--------|------|--------|
| [01. 主框架 (Main)](#01-主框架-main) | 90% | ✅ 高度還原 | P3 |
| [02. 關於 (About)](#02-關於-about) | 65% | ⚠️ ReadRecordPage 已實作，日誌/更新待補 | P2 |
| [03. 外部檔案關聯 (Association)](#03-外部檔案關聯-association) | 10% | 🚨 需要新增 | P2 |
| [04. 有聲書 (Audio)](#04-有聲書-audio) | 40% | ⚠️ 深度不足 | P2 |
| [05. 全域書籤 (Bookmark)](#05-全域書籤-bookmark) | 70% | ⚠️ 需要補強 | P2 |
| [06. 快取下載 (Cache)](#06-快取下載-cache) | 65% | ⚠️ 需要補強 | P2 |
| [07. 換封面 (ChangeCover)](#07-換封面-changecover) | 60% | ⚠️ 需要補強 | P3 |
| [08. 換源 (ChangeSource)](#08-換源-changesource) | 75% | ⚠️ 缺單章換源 | P2 |
| [09. 發現探索 (Explore)](#09-發現探索-explore) | 75% | ⚠️ 進階功能缺失 | P3 |
| [10. 書架分組管理 (Group/Manage)](#10-書架分組管理-groupmanage) | 45% | ⚠️ 大量功能缺失 | P1 |
| [11. 書籍詳情 (BookInfo)](#11-書籍詳情-bookinfo) | 90% | ✅ 高度還原 | P3 |
| [12. 本地/遠端匯入 (Import)](#12-本地遠端匯入-import) | 70% | ⚠️ 遠端書庫缺失 | P2 |
| [13. 漫畫閱讀 (Manga)](#13-漫畫閱讀-manga) | 35% | 🚨 深度嚴重不足 | P1 |
| [14. 核心閱讀器 (Read)](#14-核心閱讀器-read) | 85% | ✅ 高度還原 | P2 |
| [15. 全書搜尋 (Search)](#15-全書搜尋-search) | 90% | ✅ 高度還原 | P3 |
| [16. 內文搜尋 (SearchContent)](#16-內文搜尋-searchcontent) | 50% | ⚠️ 僅基礎實作 | P2 |
| [17. 書源管理 (BookSource)](#17-書源管理-booksource) | 90% | ✅ 高度還原 | P3 |
| [18. 目錄與書籤 (TOC)](#18-目錄與書籤-toc) | 80% | ✅ 架構差異但能用 | P3 |
| [19. 內建瀏覽器 (Browser)](#19-內建瀏覽器-browser) | 60% | ⚠️ 通用性不足 | P2 |
| [20. 設定與備份 (Config)](#20-設定與備份-config) | 80% | ✅ 大致完善 | P3 |
| [21. 字典 (Dict)](#21-字典-dict) | 0% | 🚨 需要新增 | P2 |
| [22. 自訂字典規則 (DictRule)](#22-自訂字典規則-dictrule) | 0% | 🚨 需要新增 | P3 |
| [23. 自訂檔案總管 (File)](#23-自訂檔案總管-file) | 20% | 🚨 系統接管但缺功能 | P3 |
| [24. 字體管理 (Font)](#24-字體管理-font) | 95% | ✅ 高度還原 | P3 |
| [25. 書源登入 (Login)](#25-書源登入-login) | 85% | ✅ 高度還原 | P3 |
| [26. QR Code 掃描 (QrCode)](#26-qr-code-掃描-qrcode) | 90% | ✅ 高度還原 | P3 |
| [27. 替換規則 (Replace)](#27-替換規則-replace) | 90% | ✅ 高度還原 | P3 |
| [28. RSS 訂閱 (RSS)](#28-rss-訂閱-rss) | 75% | ⚠️ 收藏/訂閱功能缺失 | P2 |
| [29. 歡迎頁 (Welcome)](#29-歡迎頁-welcome) | 30% | 🚨 僅有骨架 | P2 |
| [30. 自訂 UI 元件 (Widget)](#30-自訂-ui-元件-widget) | 85% | ✅ 架構自然轉移 | P3 |

---

## 優先級定義
- **P0（緊急）**：核心功能完全不存在，嚴重影響基本使用
- **P1（高優先）**：完成度 < 50%，使用體驗明顯缺失
- **P2（中優先）**：完成度 50~80%，進階功能缺失但基本可用
- **P3（低優先）**：完成度 > 80%，僅需細節補全

---

## 01. 主框架 (Main)

**模組職責**：App 的入口框架，包含底部 Tab 導覽（書架、發現、RSS、我的），以及主 ViewModel 的全局初始化邏輯。

**Legado 檔案**：
- `ui/main/MainActivity.kt`
- `ui/main/MainViewModel.kt`
- `ui/main/MainFragmentInterface.kt`
- `ui/main/bookshelf/BaseBookshelfFragment.kt`, `BookshelfViewModel.kt`
- `ui/main/explore/ExploreFragment.kt`, `ExploreAdapter.kt`, `ExploreViewModel.kt`
- `ui/main/my/MyFragment.kt`
- `ui/main/rss/RssFragment.kt`, `RssAdapter.kt`, `RssViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/main.dart`（包含 `MainPage` 的 `BottomNavigationBar`）
- `lib/features/bookshelf/bookshelf_page.dart`
- `lib/features/explore/explore_page.dart`
- `lib/features/rss/rss_article_page.dart`
- `lib/features/settings/settings_page.dart`（對應 MyFragment）

**完成度：90%**

**狀態：✅ 高度還原**

**不足之處**：
- `MainViewModel` 在 Android 端負責後台更新書架書籍，iOS 端目前書架更新在 `bookshelf_provider` 內以手動觸發為主，缺少啟動 App 時自動靜默更新所有書籍的邏輯。
- 底部 Tab 的 badge（未讀 RSS 數量、書源錯誤警告）目前 iOS 尚未實作。

---

## 02. 關於 (About)

**模組職責**：顯示 App 版本、開源協議、GitHub 連結、應用日誌查看、崩潰日誌查看、自動更新检查、閱讀時間統計。

**Legado 檔案**：
- `ui/about/AboutActivity.kt`
- `ui/about/AboutFragment.kt`
- `ui/about/AppLogDialog.kt`
- `ui/about/CrashLogsDialog.kt`
- `ui/about/ReadRecordActivity.kt`
- `ui/about/UpdateDialog.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/about/about_page.dart`（僅骨架）

**完成度：65%** *(2026-03-12 更新：ReadRecordPage 已完整實作)*

**狀態：⚠️ 部分完成，日誌與更新待補**

**已完成項目 ✅**：
- ✅ `ReadRecordPage`：完整實作，支援搜尋、三種排序（書名/閱讀時長/最後閱讀）、刪除單筆、清除全部記錄，接入 `ReadRecordDao`，顯示累計閱讀時長。
- ✅ `AboutPage`：UI 已美化，包含版本號、GitHub 連結、閱讀統計入口。

**仍需完成**：
- [ ] `about_page.dart` 僅有基礎骨架，需補上版本號顯示（`package_info_plus` 套件）、GitHub 連結按鈕、開源協議查看。
- [ ] 缺少 `AppLogPage`：讀取並顯示本機產生的 debug 日誌。
- [ ] 缺少 `CrashLogPage`：顯示 Flutter 的 crash 記錄（需搭配 `lib/core/services/` 中的日誌服務）。
- [ ] 缺少 `ReadRecordPage`：結合 `ReadRecordDao` 展示使用者閱讀時長、書籍閱讀統計（需查閱 `lib/core/models/read_record.dart`）。
- [ ] 缺少版本更新檢查功能（可透過 GitHub Releases API 實作）。

**B 工作流任務**：
> **實作 `ReadRecordPage`** → 查閱 `legado/ui/about/ReadRecordActivity.kt` 的邏輯，對應 `ios/lib/core/models/read_record.dart` 現有模型，建立頁面展示閱讀統計。

---

## 03. 外部檔案關聯 (Association)

**模組職責**：處理系統層級的外部 Intent，包含：從外部 App 或瀏覽器打開 `.json`/`.txt`/`.epub` 檔案時自動解析匯入、透過 `legado://` 協議 Deep Link 喚醒 App、驗證碼 (Captcha) 攔截、以及匯入各類規則（書源、替換規則、主題、RSS源、TXT 目錄規則等）。

**Legado 檔案**：
- `ui/association/FileAssociationActivity.kt` + `ViewModel`
- `ui/association/OnLineImportActivity.kt` + `ViewModel`
- `ui/association/ImportBookSourceDialog.kt` + `ViewModel`
- `ui/association/ImportReplaceRuleDialog.kt` + `ViewModel`
- `ui/association/ImportThemeDialog.kt` + `ViewModel`
- `ui/association/ImportRssSourceDialog.kt` + `ViewModel`
- `ui/association/ImportDictRuleDialog.kt` + `ViewModel`（含字典規則匯入）
- `ui/association/ImportHttpTtsDialog.kt` + `ViewModel`（含 TTS 引擎匯入）
- `ui/association/ImportTxtTocRuleDialog.kt` + `ViewModel`
- `ui/association/AddToBookshelfDialog.kt`
- `ui/association/OpenUrlConfirmActivity.kt` / `Dialog`
- `ui/association/VerificationCodeActivity.kt` / `Dialog`

**Flutter (iOS) 對應檔案**：
- ❌ **完全不存在**（僅在各個 Provider 內有散落的匯入函式）

**完成度：10%**

**狀態：🚨 需要新增**

**不足之處與後續改進計劃**：
- [ ] 引入 `app_links` 套件處理 `legado://` Deep Link。
- [ ] 引入 `receive_sharing_intent` 套件接收外部 App 傳入的檔案/文字。
- [ ] 建立 `lib/features/association/` 目錄，實作 `IntentHandlerService` 統一分發各類匯入請求。
- [ ] 建立 `ImportBookSourceDialog`、`ImportReplaceRuleDialog`、`ImportRssSourceDialog` 等 Flutter Dialog Widget。
- [ ] 實作 `AddToBookshelfDialog`（從外部鏈接直接加書）。

**B 工作流任務**：
> 最複雜的新增模組之一，建議分成「**Deep Link**」與「**外部檔案接收**」兩個子任務分開實作。

---

## 04. 有聲書 (Audio)

**模組職責**：有聲書播放頁面，含播放控制欄、播放列表管理、後台音訊服務（MediaSession）綁定、定時睡眠功能。

**Legado 檔案**：
- `ui/book/audio/AudioPlayActivity.kt`
- `ui/book/audio/AudioPlayViewModel.kt`
- `ui/book/audio/TimerSliderPopup.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/reader/audio_player_page.dart`
- `lib/core/services/audio_play_service.dart`

**完成度：40%**

**狀態：⚠️ 有基礎架構，深度不足**

**不足之處與後續改進計劃**：
- [ ] 缺少 `TimerSliderPopup`（定時睡眠）：允許用戶設定 15/30/60 分鐘自動暫停。
- [ ] 缺少後台播放服務綁定：退出 App 後 iOS 端音訊會中斷，需整合 `audio_service` 套件實作 `AudioHandler`。
- [ ] 缺少播放列表管理 UI（可順序播放多個有聲章節）。
- [ ] 缺少播放速度控制（0.5x ~ 2.0x）。

**B 工作流任務**：
> 查閱 `AudioPlayViewModel.kt` 的 `MediaPlayer` 邏輯，對應 `audio_play_service.dart` 補充定時器與後台播放。

---

## 05. 全域書籤 (Bookmark)

**模組職責**：獨立頁面查看、搜索、刪除書籤，支援依書籍分組顯示，點擊可跳轉至書籍對應位置。

**Legado 檔案**：
- `ui/book/bookmark/AllBookmarkActivity.kt`
- `ui/book/bookmark/AllBookmarkViewModel.kt`
- `ui/book/bookmark/BookmarkAdapter.kt`
- `ui/book/bookmark/BookmarkDecoration.kt`
- `ui/book/bookmark/BookmarkDialog.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/bookshelf/bookmark_list_page.dart`

**完成度：70%**

**狀態：⚠️ 基礎功能有，進階功能缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少「依書籍分組」顯示書籤（目前為平列顯示）。
- [ ] 缺少書籤關鍵字搜索功能（對應 Android 的搜索欄）。
- [ ] `BookmarkDialog`（閱讀器內新增書籤時的備注框）需確認 iOS 閱讀器端是否已實作。

---

## 06. 快取下載 (Cache)

**模組職責**：全本預下載管理，顯示每本書的下載進度、已快取章節數量，支援背景常駐下載服務。

**Legado 檔案**：
- `ui/book/cache/CacheActivity.kt`
- `ui/book/cache/CacheAdapter.kt`
- `ui/book/cache/CacheViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/cache_manager/cache_manager_page.dart`
- `lib/features/cache_manager/cache_manager_provider.dart`

**完成度：65%**

**狀態：⚠️ 前景下載可用，背景下載缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少背景常駐下載能力：退出 App 或鎖屏後下載中斷，需研究 iOS 的 `BGAppRefreshTask` 機制。
- [ ] 快取管理介面需補上「清除快取」、「暫停/繼續下載」按鈕。
- [ ] 缺少多書並發下載的優先級管理（Android 用 `DownloadService` 維護下載佇列）。

---

## 07. 換封面 (ChangeCover)

**模組職責**：從網路搜索並更換書籍封面圖，顯示可選的封面候選清單。

**Legado 檔案**：
- `ui/book/changecover/ChangeCoverDialog.kt`
- `ui/book/changecover/ChangeCoverViewModel.kt`
- `ui/book/changecover/CoverAdapter.kt`

**Flutter (iOS) 對應檔案**：
- 整合於 `lib/features/book_detail/book_detail_page.dart`（`_showChangeCoverDialog`）

**完成度：60%**

**狀態：⚠️ 基礎功能存在，但搜索能力有限**

**不足之處與後續改進計劃**：
- [ ] 換封面對話框的候選封面自動搜索邏輯（從書源的封面搜索 URL）需補強。
- [ ] 缺少從本地相簿選取封面的功能（Android 支援從本機相片庫導入）。

---

## 08. 換源 (ChangeSource)

**模組職責**：為整本書搜尋並切換到其他書源；以及為單一章節找到可用的備用內容來源。

**Legado 檔案**：
- `ui/book/changesource/ChangeBookSourceDialog.kt` + `ViewModel` + `Adapter`
- `ui/book/changesource/ChangeChapterSourceDialog.kt` + `ViewModel` + `Adapter`
- `ui/book/changesource/ChangeChapterTocAdapter.kt`

**Flutter (iOS) 對應檔案**：
- `book_detail_page.dart`（`_showChangeSourceDialog`，整本換源）
- `lib/features/reader/reader_provider.dart`（自動換源邏輯）

**完成度：75%**

**狀態：⚠️ 整本換源可用，單章換源缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少 `ChangeChapterSourceDialog`：在閱讀器中讓使用者手動選擇單一章節的備用書源，並比較各源的章節內容，目前僅能自動換源。
- [ ] 換源對話框缺少搜尋進度顯示與搜尋速度排序。

**B 工作流任務**：
> 查閱 `ChangeChapterSourceDialog.kt` 邏輯，在 `reader_page.dart` 的選單中新增「手動換章節源」入口。

---

## 09. 發現探索 (Explore)

**模組職責**：讀取書源的 `exploreUrl` 定義，顯示各書源的排行榜、分類清單，讓使用者探索新書。

**Legado 檔案**：
- `ui/book/explore/ExploreShowActivity.kt`
- `ui/book/explore/ExploreShowAdapter.kt`
- `ui/book/explore/ExploreShowViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/explore/explore_page.dart`
- `lib/features/explore/explore_provider.dart`

**完成度：75%**

**狀態：⚠️ 基礎功能良好，進階顯示模式缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少依據書源 `style` 配置切換「列表/網格」兩種顯示模式（目前固定一種排版）。
- [ ] 分頁無限滾動加載需確認是否穩定（一些書源的下一頁邏輯較特殊）。

---

## 10. 書架分組管理 (Group/Manage)

**模組職責**：書架的批次進階管理（批次換源、批次下載、批次更新封面）；以及書籍分組的增刪改查與排序拖曳。

**Legado 檔案**：
- `ui/book/manage/BookshelfManageActivity.kt`
- `ui/book/manage/BookshelfManageViewModel.kt`
- `ui/book/manage/BookAdapter.kt`
- `ui/book/manage/SourcePickerDialog.kt`
- `ui/book/group/GroupManageDialog.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/bookshelf/bookshelf_provider.dart`（`isBatchMode`，批次刪除/移動）
- `lib/features/bookshelf/group_manage_page.dart`（已有檔案，但功能待確認）

**完成度：45%**

**狀態：⚠️ 基礎批量功能存在，進階管理缺失**

**不足之處與後續改進計劃**：
- [ ] `group_manage_page.dart` 需確認是否實作了分組「重命名」與「刪除」功能。
- [ ] 缺少批次換源功能（`SourcePickerDialog` 邏輯）。
- [ ] 缺少批次預下載功能（呼叫 `cache_manager_provider` 對選中書籍批次加入下載佇列）。
- [ ] 批次操作 UI 缺少「全選/反選」按鈕。
- [ ] 分組 Tab 在 AppBar 的拖曳排序功能缺失。

**B 工作流任務**：
> 這是 P1 高優先任務。查閱 `BookshelfManageViewModel.kt` 與 `GroupManageDialog.kt` 邏輯，補強 `group_manage_page.dart` 並在 `bookshelf_provider.dart` 新增批次換源邏輯。

---

## 11. 書籍詳情 (BookInfo)

**模組職責**：顯示書籍封面、作者、簡介、最新章節，並提供換源、快取、書籍信息編輯入口。

**Legado 檔案**：
- `ui/book/info/BookInfoActivity.kt`
- `ui/book/info/BookInfoViewModel.kt`
- `ui/book/info/edit/BookInfoEditActivity.kt`
- `ui/book/info/edit/BookInfoEditViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/book_detail/book_detail_page.dart`
- `lib/features/book_detail/book_detail_provider.dart`

**完成度：90%**

**狀態：✅ 高度還原**

**不足之處**：
- [ ] 缺少獨立的「書籍信息編輯頁」（BookInfoEdit）：使用者手動修改書名、作者、自訂封面等。

---

## 12. 本地/遠端匯入 (Import)

**模組職責**：從本地檔案系統掃描匯入 TXT/EPUB 書籍；以及透過 WebDAV/局域網路伺服器遠端瀏覽並匯入書籍。

**Legado 檔案**：
- `ui/book/import/local/ImportBookActivity.kt` + `ViewModel` + `Adapter`
- `ui/book/import/remote/RemoteBookActivity.kt` + `ViewModel` + `Adapter`
- `ui/book/import/remote/ServerConfigDialog.kt` + `ViewModel`
- `ui/book/import/remote/ServersDialog.kt` + `ViewModel`

**Flutter (iOS) 對應檔案**：
- `lib/features/local_book/smart_scan_page.dart`（本地匯入）
- `lib/features/local_book/local_book_provider.dart`
- ❌ 遠端書庫（RemoteBook）模組完全不存在

**完成度：70%**

**狀態：⚠️ 本地匯入良好，遠端書庫缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少遠端書庫功能：使用者可設定局域網路 IP 伺服器或 WebDAV，直接在 App 內瀏覽遠端目錄並下載書籍。
- [ ] 本地匯入需支援批次選取多個檔案後同時匯入。

**B 工作流任務**：
> 查閱 `RemoteBookActivity.kt` 與 `ServerConfigDialog.kt` 邏輯，在 `local_book/` 下新增 `remote_book_page.dart`，搭配現有 `lib/core/models/server.dart` 模型。

---

## 13. 漫畫閱讀 (Manga)

**模組職責**：漫畫的連續長圖加載（WebToon 模式）、雙頁顯示、翻頁方向自訂、色彩濾鏡（E-Ink/灰階）、邊距裁切配置。

**Legado 檔案**：
- `ui/book/manga/ReadMangaActivity.kt`
- `ui/book/manga/ReadMangaViewModel.kt`
- `ui/book/manga/config/MangaColorFilterConfig.kt`、`MangaColorFilterDialog.kt`
- `ui/book/manga/config/MangaEpaperDialog.kt`（E-Ink 模式）
- `ui/book/manga/config/MangaFooterConfig.kt`、`MangaFooterSettingDialog.kt`
- `ui/book/manga/entities/`（多種資料模型）
- `ui/book/manga/recyclerview/`（手勢、Adapter、WebtoonRecyclerView 等）

**Flutter (iOS) 對應檔案**：
- `lib/features/reader/manga_reader_page.dart`

**完成度：35%**

**狀態：🚨 僅有骨架，深度嚴重不足**

**不足之處與後續改進計劃**：
- [ ] 缺少 WebToon 模式（連續垂直捲動加載漫畫圖片）。
- [ ] 缺少雙頁並排顯示模式。
- [ ] 缺少漫畫配置面板（翻頁方向、邊距裁切、色彩濾鏡）。
- [ ] 缺少 E-Ink/灰階模式支援。
- [ ] 圖片緩存深度管理（防止記憶體溢出）缺失。
- [ ] 缺少漫畫專屬手勢（長按縮放、雙指縮放）。

**B 工作流任務（P1）**：
> 這是最複雜的 P1 任務。建議先查閱 `WebtoonRecyclerView.kt` 與 `MangaAdapter.kt`，在 `manga_reader_page.dart` 實作 WebToon 垂直捲動模式，再逐步加入配置面板。

---

## 14. 核心閱讀器 (Read)

**模組職責**：文字閱讀核心，含翻頁視圖（捲動/仿真/覆蓋/滑動）、閱讀選單（亮度/字體/段距/排版）、文字選取動作欄、朗讀功能、自動閱讀、內容編輯。

**Legado 檔案**：
- `ui/book/read/ReadBookActivity.kt`（主 Activity）
- `ui/book/read/ReadBookViewModel.kt`
- `ui/book/read/ReadMenu.kt`（閱讀選單）
- `ui/book/read/SearchMenu.kt`（書內搜尋）
- `ui/book/read/TextActionMenu.kt`（文字選取後的動作欄）
- `ui/book/read/MangaMenu.kt`
- `ui/book/read/ContentEditDialog.kt`（內容編輯）
- `ui/book/read/EffectiveReplacesDialog.kt`（當前生效的替換規則）
- `ui/book/read/config/`（10+ 配置 Dialog）
- `ui/book/read/page/PageView.kt`、`ContentTextView.kt`、`ReadView.kt`、`AutoPager.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/reader/reader_page.dart`
- `lib/features/reader/reader_provider.dart`
- `lib/features/reader/engine/chapter_provider.dart`
- `lib/features/reader/engine/page_view_widget.dart`
- `lib/features/reader/engine/text_page.dart`
- `lib/features/reader/click_action_config_page.dart`

**完成度：85%**

**狀態：✅ 高度還原，細節待補**

**不足之處與後續改進計劃**：
- [ ] `ContentEditDialog`：允許使用者直接在閱讀器中編輯當前章節內容（排查書源錯誤時很有用）。
- [ ] `EffectiveReplacesDialog`：顯示當前書籍生效的所有替換規則清單。
- [ ] `AutoReadDialog`（自動閱讀/連續滾動）：確認 `AutoPager.kt` 的自動翻頁邏輯是否已在 iOS 閱讀器中實作。
- [ ] `PaddingConfigDialog`、`TipConfigDialog` 等細部配置 Dialog 是否完整存在。

---

## 15. 全書搜尋 (Search)

**模組職責**：在所有書源中搜索書籍，支援歷史記錄、搜索作用域限制（特定書源/分組）。

**Legado 檔案**：
- `ui/book/search/SearchActivity.kt`
- `ui/book/search/SearchViewModel.kt`
- `ui/book/search/SearchAdapter.kt`
- `ui/book/search/SearchScopeDialog.kt`
- `ui/book/search/HistoryKeyAdapter.kt`∂

**Flutter (iOS) 對應檔案**：
- `lib/features/search/search_page.dart`
- `lib/features/search/search_provider.dart`

**完成度：90%**

**狀態：✅ 高度還原**

**不足之處**：
- [ ] `SearchScopeDialog`（限定搜索範圍到特定書源群組）確認是否在 iOS 已實作。

---

## 16. 內文搜尋 (SearchContent)

**模組職責**：在單本書籍的全部章節中搜尋特定關鍵字，列出包含關鍵字的章節位置，支援跳轉。

**Legado 檔案**：
- `ui/book/searchContent/SearchContentActivity.kt`
- `ui/book/searchContent/SearchContentViewModel.kt`
- `ui/book/searchContent/SearchContentAdapter.kt`
- `ui/book/searchContent/SearchResult.kt`

**Flutter (iOS) 對應檔案**：
- 整合於 `lib/features/reader/reader_page.dart`（基礎文字高亮搜尋）

**完成度：50%**

**狀態：⚠️ 僅基礎實作**

**不足之處與後續改進計劃**：
- [ ] 目前僅能在已加載到記憶體的章節中搜尋，無法跨章節全文搜尋。
- [ ] 缺少獨立的搜尋結果頁面（`SearchContentActivity`），需透過 `ChapterDao` 查詢所有已快取章節的全文。
- [ ] 缺少搜尋結果「跳轉到對應章節行」的精確定位邏輯。

**B 工作流任務**：
> 查閱 `SearchContentViewModel.kt`，實作全庫全文搜尋邏輯，新增 `search_content_page.dart`。

---

## 17. 書源管理 (BookSource)

**模組職責**：書源的匯入、建立、編輯、除錯、分組管理、批次啟用/停用。

**Legado 檔案**：
- `ui/book/source/manage/BookSourceActivity.kt` + `ViewModel` + `Adapter` + `Sort` + `GroupManageDialog`
- `ui/book/source/edit/BookSourceEditActivity.kt` + `ViewModel` + `Adapter`
- `ui/book/source/debug/BookSourceDebugActivity.kt` + `Model` + `Adapter`

**Flutter (iOS) 對應檔案**：
- `lib/features/source_manager/source_manager_page.dart`
- `lib/features/source_manager/source_manager_provider.dart`
- `lib/features/source_manager/source_editor_page.dart`
- `lib/features/source_manager/explore_sources_page.dart`
- `lib/features/source_manager/dynamic_form_builder.dart`
- `lib/features/debug/debug_page.dart`

**完成度：90%**

**狀態：✅ 高度還原**

**不足之處**：
- [ ] 書源管理頁的「排序」功能（依評分/名稱/響應速度）確認是否完整。
- [ ] `GroupManageDialog`（書源分組管理）確認是否已整合至 `source_manager_page.dart`。

---

## 18. 目錄與書籤 (TOC)

**模組職責**：提供書籍章節目錄的獨立瀏覽視圖，以及全本書籤的管理；同時包含 TXT 目錄規則的管理。

**Legado 檔案**：
- `ui/book/toc/TocActivity.kt` + `ViewModel`
- `ui/book/toc/ChapterListFragment.kt` + `Adapter`
- `ui/book/toc/BookmarkFragment.kt` + `Adapter`
- `ui/book/toc/rule/TxtTocRuleActivity.kt` + `ViewModel` + `Adapter` + `Dialog` + `EditDialog`

**Flutter (iOS) 對應檔案**：
- 目錄整合於 `lib/features/book_detail/book_detail_page.dart`
- 閱讀器側邊欄目錄存在於 `reader_page.dart`

**完成度：80%**

**狀態：✅ 架構差異，核心功能滿足**

**不足之處**：
- [ ] 缺少 `TxtTocRuleActivity`：TXT 書籍的目錄解析規則管理（使用者可自訂正則表達式）。
- [ ] 目錄頁缺少「正則修正目錄」功能入口。

---

## 19. 內建瀏覽器 (Browser)

**模組職責**：通用的 WebView 瀏覽器，用於書源登入驗證、驗證碼輸入、或查看原始網頁來源。

**Legado 檔案**：
- `ui/browser/WebViewActivity.kt`
- `ui/browser/WebViewModel.kt`

**Flutter (iOS) 對應檔案**：
- `lib/shared/widgets/browser_page.dart`（通用瀏覽器已存在！）
- `lib/features/source_manager/source_login_page.dart`（書源登入專用）

**完成度：60%**

**狀態：⚠️ 基礎架構存在，通用性與功能有限**

**不足之處與後續改進計劃**：
- [ ] `browser_page.dart` 需確認是否支援 Cookie 注入（用於保持登入狀態）。
- [ ] 缺少瀏覽器的網址列、前進/後退 導覽控制。
- [ ] 缺少 JavaScript 注入介面（Legado 的 WebView 支援 JS 與 Native 互動）。

---

## 20. 設定與備份 (Config)

**模組職責**：主題設定、閱讀設定、備份/還原（本地與 WebDAV）、封面設定、其他雜項設定（廣告過濾等）、歡迎頁配置。

**Legado 檔案**：
- `ui/config/ConfigActivity.kt` + `ViewModel`
- `ui/config/ThemeConfigFragment.kt`
- `ui/config/BackupConfigFragment.kt`
- `ui/config/CoverConfigFragment.kt`
- `ui/config/OtherConfigFragment.kt`
- `ui/config/WelcomeConfigFragment.kt`
- `ui/config/CheckSourceConfig.kt`
- `ui/config/ThemeListDialog.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/settings/settings_page.dart`
- `lib/features/settings/settings_provider.dart`
- `lib/features/settings/theme_settings_page.dart`
- `lib/features/settings/reading_settings_page.dart`
- `lib/features/settings/backup_settings_page.dart`
- `lib/features/settings/other_settings_page.dart`
- `lib/features/settings/aloud_settings_page.dart`
- `lib/features/settings/http_tts_manager_page.dart`

**完成度：80%**

**狀態：✅ 主要功能完善**

**不足之處**：
- [ ] `WelcomeConfigFragment`（啟動頁背景圖與名言設定）確認是否已在 `settings` 中實作。
- [ ] `CoverConfigFragment`（封面來源優先級設定）確認是否缺失。
- [ ] `CheckSourceConfig`（批次檢測書源配置）確認是否缺失。

---

## 21. 字典 (Dict)

**模組職責**：閱讀器中長按選取文字後，可呼叫自訂字典規則進行查詞翻譯，透過 WebView 顯示結果。

**Legado 檔案**：
- `ui/dict/DictDialog.kt`
- `ui/dict/DictViewModel.kt`

**Flutter (iOS) 對應檔案**：
- ❌ **完全不存在**
- （但 `lib/core/models/dict_rule.dart` 資料模型已存在！）

**完成度：0%**

**狀態：🚨 需要新增**

**不足之處與後續改進計劃**：
- [ ] 在閱讀器的 `TextActionMenu`（文字選取後的動作欄）中添加「字典」選項。
- [ ] 實作 `DictDialog`：根據 `DictRule` 中定義的 URL，帶入選取的文字，用 WebView 顯示查詢結果。
- [ ] 基礎的 dict_rule 模型已存在，只需要實作 UI 層。

**B 工作流任務**：
> 查閱 `DictDialog.kt` 邏輯（非常簡單，主要是 WebView 帶入詞彙查詢），優先利用現有 `browser_page.dart` 快速實作。

---

## 22. 自訂字典規則 (DictRule)

**模組職責**：管理（增刪改查）字典查詢規則，每條規則定義一個字典的查詢 URL。

**Legado 檔案**：
- `ui/dict/rule/`（獨立的字典規則管理 Activity）

**Flutter (iOS) 對應檔案**：
- ❌ **完全不存在**
- `lib/core/models/dict_rule.dart` 模型已存在

**完成度：0%**

**狀態：🚨 需要新增**

**後續改進計劃**：
- [ ] 新增 `dict_rule_page.dart` 顯示字典規則清單，支援匯入/刪除。
- [ ] 新增 `dict_rule_edit_page.dart` 允許用戶編輯自訂字典規則。

---

## 23. 自訂檔案總管 (File)

**模組職責**：App 內建的自訂檔案管理器，允許使用者在指定目錄（備份目錄、字體目錄等）中瀏覽、選取、刪除檔案。

**Legado 檔案**：
- `ui/file/FileManageActivity.kt` + `ViewModel`
- `ui/file/FilePickerDialog.kt` + `ViewModel`
- `ui/file/HandleFileActivity.kt` + `Contract` + `ViewModel`

**Flutter (iOS) 對應檔案**：
- 透過系統 `file_picker` 套件處理，無獨立 UI

**完成度：20%**

**狀態：⚠️ 系統套件接管，但缺少 App 內部目錄瀏覽**

**不足之處**：
- [ ] 系統 `file_picker` 無法瀏覽 App 沙盒內部的備份/字體目錄，需要針對 App 內部目錄建立簡單的瀏覽 UI。

---

## 24. 字體管理 (Font)

**模組職責**：從本地或網路匯入自訂字體檔案，並在閱讀器中套用。

**Legado 檔案**：
- `ui/font/FontSelectDialog.kt`
- `ui/font/FontAdapter.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/settings/font_manager_page.dart`

**完成度：95%**

**狀態：✅ 高度還原**

---

## 25. 書源登入 (Login)

**模組職責**：針對需要登入的書源，提供 WebView 登入頁面，並截取登入後的 Cookie 供後續請求使用。

**Legado 檔案**：
- `ui/login/SourceLoginActivity.kt`
- `ui/login/SourceLoginDialog.kt`
- `ui/login/SourceLoginViewModel.kt`
- `ui/login/WebViewLoginFragment.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/source_manager/source_login_page.dart`

**完成度：85%**

**狀態：✅ 高度還原**

**不足之處**：
- [ ] Cookie 擷取後是否正確寫入 `CookieStore` 並讓後續書源請求使用，需做功能性驗證。

---

## 26. QR Code 掃描 (QrCode)

**模組職責**：透過相機掃描 QR Code，解析得到的 URL 或內容，用於快速匯入書源等規則。

**Legado 檔案**：
- `ui/qrcode/QrCodeActivity.kt`
- `ui/qrcode/QrCodeFragment.kt`
- `ui/qrcode/QrCodeResult.kt`
- `ui/qrcode/ScanResultCallback.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/source_manager/qr_scan_page.dart`

**完成度：90%**

**狀態：✅ 高度還原**

---

## 27. 替換規則 (Replace)

**模組職責**：管理（增刪改查）文字替換規則，在書籍內容渲染時自動將符合正則表達式的文字替換為指定內容。

**Legado 檔案**：
- `ui/replace/ReplaceRuleActivity.kt` + `ViewModel` + `Adapter`
- `ui/replace/GroupManageDialog.kt`
- `ui/replace/edit/ReplaceEditActivity.kt` + `ViewModel`

**Flutter (iOS) 對應檔案**：
- `lib/features/replace_rule/replace_rule_page.dart`
- `lib/features/replace_rule/replace_rule_provider.dart`
- `lib/features/replace_rule/replace_rule_edit_page.dart`

**完成度：90%**

**狀態：✅ 高度還原**

**不足之處**：
- [ ] 替換規則的分組管理（`GroupManageDialog`）確認是否實作。

---

## 28. RSS 訂閱 (RSS)

**模組職責**：RSS 源的訂閱管理、文章列表瀏覽（含多種排版）、WebView 文章閱讀、收藏文章管理、訂閱分組（`RuleSubActivity`）。

**Legado 檔案**：
- `ui/rss/article/RssArticlesFragment.kt` + `ViewModel` + 3種 `Adapter`
- `ui/rss/article/RssSortActivity.kt` + `ViewModel`
- `ui/rss/article/ReadRecordDialog.kt`
- `ui/rss/favorites/RssFavoritesActivity.kt` + `ViewModel` + `Adapter` + `Dialog` + `Fragment`
- `ui/rss/read/ReadRssActivity.kt` + `ViewModel` + `RssJsExtensions.kt` + `VisibleWebView.kt`
- `ui/rss/subscription/RuleSubActivity.kt` + `Adapter`

**Flutter (iOS) 對應檔案**：
- `lib/features/rss/rss_article_page.dart` + `rss_article_provider.dart`
- `lib/features/rss/rss_read_page.dart`
- `lib/features/rss/rss_source_page.dart` + `rss_source_provider.dart`
- `lib/features/rss/rss_source_editor_page.dart`

**完成度：75%**

**狀態：⚠️ 核心閱讀功能有，收藏與訂閱分組缺失**

**不足之處與後續改進計劃**：
- [ ] 缺少 `RssFavoritesPage`（收藏的 RSS 文章管理頁面）。
- [ ] 缺少 `RssSubPage`（RSS 訂閱分組規則管理）。
- [ ] `RssArticlesFragment` 的多種排版顯示模式（`RssArticlesAdapter1`/`Adapter2`）確認是否支援。
- [ ] `ReadRecordDialog`（RSS 閱讀記錄）缺失。
- [ ] `RssJsExtensions.kt`（WebView 中的 JS 擴展用於 RSS 頁面互動）需確認是否在 `rss_read_page.dart` 中實作。

**B 工作流任務**：
> 查閱 `RssFavoritesActivity.kt` 邏輯，對應 `lib/core/models/rss_star.dart`（收藏模型已存在！），建立 `rss_favorites_page.dart`。

---

## 29. 歡迎頁 (Welcome)

**模組職責**：App 首次啟動或每次開啟時的啟動畫面，支援使用者自訂背景圖、顯示名言佳句，延遲後自動跳入主頁。

**Legado 檔案**：
- `ui/welcome/WelcomeActivity.kt`

**Flutter (iOS) 對應檔案**：
- `lib/features/welcome/welcome_page.dart`

**完成度：30%**

**狀態：🚨 僅有基礎骨架**

**不足之處與後續改進計劃**：
- [ ] `welcome_page.dart` 目前幾乎只有佔位符，需實作：
  - 自訂背景圖（從 `SettingsProvider` 讀取使用者設定的圖片路徑）。
  - 名言佳句機制（預設資料集 + 允許使用者自訂）。
  - 動畫過渡（淡入/淡出效果跳入主頁）。

---

## 30. 自訂 UI 元件 (Widget)

**模組職責**：存放 App 全局共用的自訂 UI 元件，如電池視圖、閱讀資訊欄、客製化滑動條、各類對話框等。

**Legado 檔案**（共 60+ 個）：
- `ui/widget/BatteryView.kt`、`ReaderInfoBarView.kt`、`DetailSeekBar.kt`
- `ui/widget/dialog/`（CodeDialog、TextDialog 等）
- `ui/widget/image/`、`ui/widget/recycler/`、`ui/widget/seekbar/` 等

**Flutter (iOS) 對應檔案**：
- `lib/shared/widgets/base_scaffold.dart`
- `lib/shared/widgets/browser_page.dart`
- `lib/shared/theme/app_theme.dart`
- 閱讀器電池與時間顯示整合在 `reader_page.dart` 的 Overlay 中

**完成度：85%**

**狀態：✅ 架構自然轉移**

**說明**：Flutter 的聲明式 UI 架構讓大多數自訂 View 不再需要獨立類別，通常透過 Widget 組合即可達成，屬於正常的架構差異。

---

## 🗺️ B 工作流執行路線圖

按照「影響最大、難度適中」的原則排序任務：

### 🔴 第一批（P1 - 立即實作）
1. **`ReadRecordPage`**（About 模組）- 簡單，模型已有
2. **`GroupManagePage` 補強**（書架分組）- 批次換源 + 重命名/刪除
3. **漫畫 WebToon 模式**（Manga）- 核心缺失功能

### 🟠 第二批（P2 - 近期實作）
4. **`RssFavoritesPage`**（RSS 收藏）- 模型已有
5. **字典功能 `DictDialog`**（Dict）- 模型已有
6. **`ChangeChapterSourceDialog`**（單章換源）
7. **`SearchContentPage`**（全文搜尋）
8. **歡迎頁完善**（Welcome）

### 🟡 第三批（P3 - 後期實作）
9. **遠端書庫**（RemoteBook）
10. **外部 Intent 關聯**（Association）- 最複雜
11. **有聲書後台服務**（Audio Service）
12. **快取背景下載**（Cache Background）
13. **自動書架更新**（Main ViewModel）

---

*本文件將隨每次功能實作完成後即時更新狀態。*
