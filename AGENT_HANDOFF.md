# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-11 00:25  
> **目標**: 將 Android Legado 閱讀器完整移植到 iOS（使用 Flutter）  
> **當前狀態**: R1~R5 大部分完成，整體完成度約 **65%**

---

## 📍 專案位置

| 專案 | 路徑 |
|------|------|
| **iOS Flutter 專案** | `c:\Users\benny\Desktop\Folder\Project\reader\ios\` |
| **Android 原始碼（參考）** | `c:\Users\benny\Desktop\Folder\Project\reader\legado\` |
| Android 核心代碼根目錄 | `legado\app\src\main\java\io\legado\app\` |

---

## 📐 iOS 專案架構

```
ios/lib/
├── main.dart                          ← 入口 (MultiProvider)
├── core/
│   ├── engine/
│   │   ├── analyze_rule.dart          ← 規則總控 (539行) ✅ 已強化
│   │   ├── analyze_url.dart           ← URL 引擎 (335行) ✅ 已強化
│   │   ├── rule_analyzer.dart         ← 規則切割器 (352行)
│   │   ├── js/
│   │   │   ├── js_engine.dart         ← QuickJS 包裝
│   │   │   ├── js_extensions.dart     ← java.* 橋接 (357行, ~35方法) ✅
│   │   │   ├── js_encode_utils.dart   ← 加密工具 (183行) ✅
│   │   │   └── shared_js_scope.dart   ← 跨腳本共用 (88行) ✅ 新增
│   │   └── parsers/                   ← 4 個解析器 (全部完成)
│   ├── models/                        ← 28 個數據模型
│   ├── database/
│   │   ├── app_database.dart          ← SQLite (已擴充表結構)
│   │   └── dao/                       ← 10 個 DAO ✅ (+4 新增)
│   │       ├── book_source_dao.dart   ├── book_dao.dart
│   │       ├── chapter_dao.dart       ├── cookie_dao.dart ✅
│   │       ├── replace_rule_dao.dart   ├── search_history_dao.dart
│   │       ├── bookmark_dao.dart ✅    ├── cache_dao.dart ✅
│   │       ├── book_group_dao.dart ✅  └── read_record_dao.dart ✅
│   └── services/
│       ├── book_source_service.dart    (206行)
│       ├── content_processor.dart ✅    (119行) 新增
│       ├── cookie_store.dart ✅        ├── http_client.dart ✅
│       ├── cache_manager.dart ✅       └── rate_limiter.dart
├── features/
│   ├── reader/
│   │   ├── reader_page.dart           (342行) ✅ 大幅重寫
│   │   ├── reader_provider.dart       (274行) ✅ 大幅重寫
│   │   └── engine/                    ✅ 全新排版引擎
│   │       ├── chapter_provider.dart  (178行) — TextPainter 分頁
│   │       ├── text_page.dart         (65行) — TextPage/TextLine
│   │       └── page_view_widget.dart  (107行) — CustomPaint 繪製
│   ├── bookshelf/ explore/ search/ book_detail/
│   ├── source_manager/ settings/
└── shared/theme/
```

---

## ✅ 已完成清單

### 核心引擎
- [x] RuleAnalyzer — 規則切割 (~80%)
- [x] AnalyzeRule — 規則總控 (539行), 含 `getElement()`, `setChapter()`, `setNextChapterUrl()`, `_splitRegex()`, `_splitSourceRuleCacheString()`, HTML unescape
- [x] AnalyzeUrl — URL 引擎 (335行), 含 Cookie 整合、表單參數、URL 編碼、重定向、`<js>` 標籤
- [x] 4 個子解析器 (CSS/JsonPath/XPath/Regex) — 全部完成

### JS 引擎
- [x] JsEngine — QuickJS 包裝
- [x] JsExtensions — ~35 個 java.* 方法 (ajax/ajaxAll/get/post/getCookie/downloadFile/importScript/cacheFile/htmlFormat/toNumChapter/createSymmetricCrypto 等)
- [x] JsEncodeUtils — AES 變體/HMAC/SHA/digest
- [x] SharedJsScope — LRU 快取 + JSON/URL jsLib 支援 ✅ 新增

### 業務服務
- [x] BookSourceService — 搜尋/發現/詳情/目錄(翻頁)/正文
- [x] ContentProcessor — 去重複標題/重新分段/段首縮排 ✅ 新增
- [x] CookieStore — CRUD + 記憶體快取
- [x] HttpClient — Dio singleton + Cookie 攔截器
- [x] CacheManager — 檔案快取
- [x] RateLimiter — 並發控制

### 資料層 (10 個 DAO)
- [x] BookSourceDao, BookDao, ChapterDao, ReplaceRuleDao, SearchHistoryDao
- [x] CookieDao ✅, BookmarkDao ✅, CacheDao ✅, BookGroupDao ✅, ReadRecordDao ✅

### 閱讀器排版引擎 ✅ 全新
- [x] TextPage / TextLine 數據模型 — 含進度計算
- [x] ChapterProvider — TextPainter 二分搜尋分頁
- [x] PageViewWidget — CustomPaint 繪製 + 頁首/頁尾
- [x] ReaderProvider — 章節載入/預載/替換規則/設定持久化/翻頁
- [x] ReaderPage — 完整 PageView 翻頁 + 控制列 + 設定面板

---

## ❌ 尚未完成的功能

Android 路徑前綴 = `legado\app\src\main\java\io\legado\app\` (簡稱 `A:`)  
iOS 路徑前綴 = `ios\lib\` (簡稱 `I:`)

### 🔴 P0 — 進階書源相容性

#### JS 橋接剩餘 (~48 個方法未實作)

| 功能 | Android (A:`help/JsExtensions.kt`) | 說明 |
|------|-----------------------------------|------|
| WebView 渲染 | `webView(html, url, js)` L163 | 反爬關鍵，用 webview_flutter |
| WebView 取源碼 | `webViewGetSource(...)` L185 | 同上 |
| 字體解析 queryTTF | `queryTTF(data, useCache)` L807 | 需建 `I:core/engine/js/query_ttf.dart`，參考 `A:model/analyzeRule/QueryTTF.java` (39KB) |
| 字體替換 replaceFont | `replaceFont(text, errorTTF, correctTTF)` L861 | 依賴 queryTTF |
| 解壓 ZIP/RAR/7z | `unzipFile()` L614 | `archive` 套件 |
| DES/3DES 加密 | JsEncodeUtils 系列 | 目前是 AES fallback |
| RSA 非對稱加密 | `createAsymmetricCrypto()` L76 | pointycastle |
| 繁簡轉換 t2s/s2t | 目前是 placeholder | 需 opencc 字典 |

### 🟡 P1 — DAO 補全 (剩餘 11 個)

| DAO | Android (A:`data/dao/`) | 優先級 |
|-----|------------------------|--------|
| RssSourceDao | `RssSourceDao.kt` (5KB) | P2 |
| RssArticleDao | `RssArticleDao.kt` (1KB) | P2 |
| RssStarDao | `RssStarDao.kt` (1KB) | P2 |
| SearchBookDao | `SearchBookDao.kt` (3KB) | P2 |
| DictRuleDao | `DictRuleDao.kt` (1KB) | P3 |
| HttpTTSDao | `HttpTTSDao.kt` (1KB) | P3 |
| RuleSubDao | `RuleSubDao.kt` (1KB) | P3 |
| TxtTocRuleDao | `TxtTocRuleDao.kt` (1KB) | P3 |
| KeyboardAssistsDao | `KeyboardAssistsDao.kt` (1KB) | P3 |
| ServerDao | `ServerDao.kt` (1KB) | P3 |

### 🟡 P1 — 閱讀器體驗增強

| 功能 | Android 參考 | 說明 |
|------|-------------|------|
| 仿真翻頁 | `A:ui/book/read/page/delegate/SimulationPageDelegate.kt` | 最複雜的動畫 |
| 滾動閱讀 | `A:ui/book/read/page/delegate/ScrollPageDelegate.kt` | 上下滾動模式 |
| 書籤功能 | BookmarkDao (已有) + UI | 長按添加/管理 |
| 文字選擇 | `A:ui/book/read/TextActionMenu.kt` | 選詞查字典/翻譯 |
| 內容搜尋 | `A:ui/book/read/SearchMenu.kt` | 書內搜尋 |

### 🟢 P2 — 系統服務

| 功能 | Android 參考 | iOS 目標 | 建議套件 |
|------|-------------|---------|---------|
| TTS 朗讀 | `A:service/TTSReadAloudService.kt` | 建 `I:core/services/tts_service.dart` | `flutter_tts` |
| WebDAV | `A:help/AppWebDav.kt` (13KB) | 建 `I:core/services/webdav_service.dart` | `webdav_client` |
| 離線下載 | `A:service/CacheBookService.kt` | 建 `I:core/services/download_service.dart` | Dio + Isolate |
| 書源校驗 | `A:service/CheckSourceService.kt` | 建 `I:core/services/check_source_service.dart` | |
| 閱讀設定 | `A:help/config/ReadBookConfig.kt` + `AppConfig.kt` | 建 `I:core/services/app_config.dart` | shared_preferences |

### ⚪ P3 — 進階功能

| 功能 | Android 參考 |
|------|-------------|
| 本地 EPUB/TXT/PDF | `A:model/localBook/` |
| RSS 模組 | `A:model/rss/` + `A:ui/rss/` |
| 漫畫模式 | `A:ui/book/manga/` |
| 有聲書 | `A:model/AudioPlay.kt` |

---

## 🔧 開發約定

- **修改**: 禁止 `write_file` 覆寫，僅用 `replace`
- **備份**: 修改後 `git add <file> ; git commit -m "backup: ..."`
- **語言**: 對話繁體中文 | 代碼英文 | Commit: Conventional Commits
- **技術**: Provider + Dio + sqflite + flutter_js

## ⚡ 常用指令

```powershell
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; dart analyze lib/
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter test
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter run
```
