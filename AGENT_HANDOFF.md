# 🤖 Agent 交接文檔 — Legado iOS Reader (v2)

> **最後更新**: 2026-03-11
> **專案狀態**: 86 Dart 檔案 · 80 測試全通過 · 0 靜態分析問題
> **階段**: 核心引擎 100% 完成，剩餘 UI 功能補全

---

## 📍 專案位置

| 項目 | 路徑 |
|------|------|
| **iOS Flutter 專案** | `c:\Users\benny\Desktop\Folder\Project\reader\ios\` |
| **Android 原始碼（參考）** | `c:\Users\benny\Desktop\Folder\Project\reader\legado\` |
| **Flutter SDK** | `C:\flutter_sdk\flutter\bin\flutter.bat` |

---

## 🛠️ 開發環境

- **OS**: Windows · PowerShell 7 (`pwsh.exe`)，指令分隔用 `;` 非 `&&`
- **Flutter**: 3.29.1 stable · Dart 3.7.0
- **Shell 執行**: `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -Command "..."`
- **複雜指令**: 寫入 `.ps1` 暫存檔再用 `-File` 執行
- **Git**: 每完成一個檔案修改後需立即 `git add <file>; git commit -m "backup: ..."`

---

## 📁 專案結構 (86 Dart 檔案)

```
ios/lib/
├── main.dart                          ← 5-tab 入口 (書架/發現/書源/RSS/設定)
│
├── core/
│   ├── models/ (24 files)             ← ✅ 全部完成 (Book, BookSource, Chapter, RssSource, etc.)
│   ├── database/
│   │   ├── app_database.dart          ← ✅ 完整 Schema (6+ 表)
│   │   └── dao/ (13 files)            ← ✅ 全部完成 (Book/Source/Chapter/Bookmark/Cookie/Cache/...)
│   ├── engine/
│   │   ├── analyze_rule.dart          ← ✅ 539 行 · 規則總控
│   │   ├── analyze_url.dart           ← ✅ 364 行 · URL 引擎
│   │   ├── rule_analyzer.dart         ← ✅ 規則切割器
│   │   ├── parsers/ (4 files)         ← ✅ CSS(482行)/JsonPath/XPath/Regex
│   │   └── js/ (5 files)             ← ✅ JsEngine/JsExtensions(526行)/EncodeUtils/QueryTTF/SharedScope
│   ├── services/ (10 files)           ← ✅ BookSource/WebDAV/TTS/Download/RateLimiter/Cookie/Cache/HTTP/WebView/ContentProcessor
│   └── local_book/ (2 files)          ← ✅ EpubParser/TxtParser
│
├── features/
│   ├── bookshelf/                     ← ✅ 書架 + Provider (10KB+)
│   ├── explore/                       ← ✅ 發現 + Provider (6KB+)
│   ├── search/                        ← ✅ 搜尋 + Provider (5KB+)
│   ├── book_detail/                   ← ✅ 書籍詳情 + Provider (7KB+)
│   ├── reader/ + engine/              ← ✅ 閱讀器 + 排版引擎 + PageView (14KB+)
│   ├── source_manager/                ← ✅ 書源管理 + Provider (10KB+)
│   ├── rss/                           ← 🟡 骨架 (2.6KB)
│   └── settings/                      ← ✅ 設定 + Provider (9KB+)
│
└── shared/theme/app_theme.dart        ← ✅ Material 3 + 5 套閱讀主題
```

---

## 🏗️ Android 完整結構 → iOS 對照表

Android 根目錄: `legado/app/src/main/java/io/legado/app/`

### data/ — 資料層

| Android | 檔案數 | iOS 對應 | 狀態 |
|---------|--------|---------|------|
| `data/entities/` (28 files) | `Book.kt`, `BookSource.kt`, `BookChapter.kt`, `BookGroup.kt`, `Bookmark.kt`, `Cache.kt`, `Cookie.kt`, `DictRule.kt`, `HttpTTS.kt`, `KeyboardAssist.kt`, `ReadRecord.kt`, `ReplaceRule.kt`, `RssArticle.kt`, `RssSource.kt`, `RssStar.kt`, `SearchBook.kt`, etc. | `core/models/` (24 files) | ✅ 少 `RuleSub`, `Server`, `TxtTocRule`, `ReadRecordShow` 4 個 |
| `data/entities/rule/` | `SearchRule.kt`, `ExploreRule.kt`, `BookInfoRule.kt`, `TocRule.kt`, `ContentRule.kt` | 合併在 `book_source.dart` | ✅ |
| `data/dao/` (21 files) | BookDao, BookSourceDao, BookGroupDao, BookmarkDao, CacheDao, CookieDao, ReadRecordDao, ReplaceRuleDao, RssArticleDao, RssSourceDao, SearchBookDao, etc. | `core/database/dao/` (13 files) | 🟡 少 `DictRuleDao`, `HttpTTSDao`, `KeyboardAssistsDao`, `RssStarDao`, `RuleSubDao`, `SearchBookDao`, `ServerDao`, `TxtTocRuleDao` |

### model/ — 業務模型層

| Android | 檔案數/大小 | iOS 對應 | 狀態 |
|---------|-----------|---------|------|
| `model/analyzeRule/AnalyzeRule.kt` | 32KB | `core/engine/analyze_rule.dart` (539行) | ✅ |
| `model/analyzeRule/AnalyzeUrl.kt` | 29KB | `core/engine/analyze_url.dart` (364行) | ✅ |
| `model/analyzeRule/RuleAnalyzer.kt` | 15KB | `core/engine/rule_analyzer.dart` | ✅ |
| `model/analyzeRule/AnalyzeByJSoup.kt` | 18KB | `core/engine/parsers/analyze_by_css.dart` (482行) | ✅ |
| `model/analyzeRule/AnalyzeByJSonPath.kt` | 6KB | `core/engine/parsers/analyze_by_json_path.dart` | ✅ |
| `model/analyzeRule/AnalyzeByXPath.kt` | 5KB | `core/engine/parsers/analyze_by_xpath.dart` | ✅ |
| `model/analyzeRule/AnalyzeByRegex.kt` | 2KB | `core/engine/parsers/analyze_by_regex.dart` | ✅ |
| `model/analyzeRule/QueryTTF.java` | 39KB | `core/engine/js/query_ttf.dart` | ✅ |
| `model/analyzeRule/RuleData.kt` | 1KB | `core/models/rule_data_interface.dart` | ✅ |
| `model/webBook/WebBook.kt` | 15KB | `core/services/book_source_service.dart` (290行) | ✅ |
| `model/webBook/BookList.kt` | 13KB | 合併在 book_source_service.dart | ✅ |
| `model/webBook/BookInfo.kt` | 7KB | 合併在 book_source_service.dart | ✅ |
| `model/webBook/BookChapterList.kt` | 13KB | 合併在 book_source_service.dart | ✅ |
| `model/webBook/BookContent.kt` | 9KB | 合併在 book_source_service.dart | ✅ |
| `model/webBook/SearchModel.kt` | 8KB | 整合在 search_provider.dart | ✅ |
| `model/rss/Rss.kt` | 4KB | ❌ 未實作 | ❌ |
| `model/rss/RssParserByRule.kt` | 6KB | ❌ 未實作 | ❌ |
| `model/rss/RssParserDefault.kt` | 7KB | ❌ 未實作 | ❌ |
| `model/localBook/` | EpubFile.kt, TextFile.kt etc. | `core/local_book/epub_parser.dart`, `txt_parser.dart` | ✅ |
| `model/remote/` | RemoteBookWebDav.kt | 整合在 webdav_service.dart | ✅ |

### help/ — 工具/輔助層

| Android | 大小 | iOS 對應 | 狀態 |
|---------|------|---------|------|
| `help/JsExtensions.kt` | 33KB | `core/engine/js/js_extensions.dart` (526行) | ✅ |
| `help/JsEncodeUtils.kt` | 15KB | `core/engine/js/js_encode_utils.dart` | ✅ |
| `help/AppWebDav.kt` | — | `core/services/webdav_service.dart` (231行) | ✅ |
| `help/CacheManager.kt` | — | `core/services/cache_manager.dart` | ✅ |
| `help/ConcurrentRateLimiter.kt` | — | `core/services/rate_limiter.dart` | ✅ |
| `help/TTS.kt` | — | `core/services/tts_service.dart` | ✅ |
| `help/ReplaceAnalyzer.kt` | — | 合併在 content_processor.dart | 🟡 部分 |
| `help/DefaultData.kt` | — | ❌ 預設書源/規則 | ❌ |
| `help/http/CookieStore.kt` | — | `core/services/cookie_store.dart` | ✅ |
| `help/http/HttpHelper.kt` + OkHttp系列 | 13 files | `core/services/http_client.dart` | ✅ (簡化) |
| `help/http/BackstageWebView.kt` | — | `core/services/backstage_webview.dart` | ✅ |
| `help/rhino/` | — | `core/engine/js/shared_js_scope.dart` | ✅ |
| `help/config/` | AppConfig, ReadBookConfig, ThemeConfig | `shared/theme/app_theme.dart` + settings_provider | 🟡 部分 |
| `help/book/` | BookHelp, ContentProcessor | `core/services/content_processor.dart` | ✅ |
| `help/crypto/` | — | 合併在 js_encode_utils.dart | ✅ |
| `help/storage/` | — | 用 SharedPreferences 替代 | ✅ |
| `help/glide/` | 圖片載入 | 用 cached_network_image | ✅ |
| `help/exoplayer/` | 音頻播放器 | ❌ 無 (需 just_audio) | ❌ |

### service/ — 後台服務

| Android | iOS 對應 | 狀態 |
|---------|---------|------|
| `service/TTSReadAloudService.kt` | `core/services/tts_service.dart` | ✅ |
| `service/CacheBookService.kt` | `core/services/download_service.dart` | ✅ |
| `service/CheckSourceService.kt` | ❌ 書源校驗服務 | ❌ |
| `service/AudioPlayService.kt` | ❌ 音頻播放服務 | ❌ |
| `service/DownloadService.kt` | 合併在 download_service.dart | ✅ |
| `service/WebService.kt` | ❌ Web 服務器 (不需要) | ⏭️ 跳過 |
| `service/HttpReadAloudService.kt` | ❌ HTTP TTS | ❌ |
| `service/ExportBookService.kt` | ❌ 書籍匯出 | ❌ |

### ui/ — 介面層 (最龐大)

| Android 模組 | 子模組 | iOS 對應 | 狀態 |
|-------------|--------|---------|------|
| `ui/main/bookshelf/` | 書架 | `features/bookshelf/` | ✅ |
| `ui/main/explore/` | 發現 | `features/explore/` | ✅ |
| `ui/main/` | MainActivity | `main.dart` (5-tab) | ✅ |
| `ui/book/read/` | 閱讀器 (40+ files, ~300KB) | `features/reader/` | ✅ 85% |
| `ui/book/search/` | 搜尋 | `features/search/` | ✅ |
| `ui/book/info/` | 書籍詳情 | `features/book_detail/` | ✅ |
| `ui/book/explore/` | 發現子頁 | 合併在 explore/ | ✅ |
| `ui/book/source/` + `edit/` | 書源管理 + 編輯器 | `features/source_manager/` | 🟡 缺編輯器 |
| `ui/book/import/` | 書源匯入 | 🟡 僅剪貼簿 | 🟡 缺 URL |
| `ui/book/changesource/` | 書源切換 | ❌ | ❌ |
| `ui/book/changecover/` | 換封面 | ❌ | ❌ |
| `ui/book/searchContent/` | 正文搜尋 | ❌ | ❌ |
| `ui/book/cache/` | 快取管理 | ❌ UI | ❌ |
| `ui/book/toc/` | 章節目錄 | 🟡 缺側滑欄 | 🟡 |
| `ui/book/bookmark/` | 書籤管理 | 整合在 reader | ✅ |
| `ui/book/group/` | 書籍分組 | 整合在 bookshelf | ✅ |
| `ui/book/manage/` | 書架管理 | 整合在 bookshelf | ✅ |
| `ui/book/audio/` | 音頻播放 | ❌ | ❌ |
| `ui/book/manga/` | 漫畫閱讀 | ❌ | ❌ |
| `ui/rss/source/` | RSS 來源 | `features/rss/` | 🟡 骨架 |
| `ui/rss/article/` | RSS 文章列表 | ❌ | ❌ |
| `ui/rss/read/` | RSS 閱讀 | ❌ | ❌ |
| `ui/rss/favorites/` | RSS 收藏 | ❌ | ❌ |
| `ui/rss/subscription/` | RSS 訂閱管理 | ❌ | ❌ |
| `ui/replace/edit/` | 替換規則管理 | ❌ | ❌ |
| `ui/config/` | 設定 | `features/settings/` | ✅ |
| `ui/login/` | 書源登入 | ❌ | ❌ |
| `ui/file/` | 本地檔案 | ❌ UI (有解析器) | ❌ |
| `ui/font/` | 字體管理 | ❌ | ❌ |
| `ui/dict/` | 字典 | ❌ | ❌ |
| `ui/qrcode/` | 二維碼 | ❌ | ❌ |
| `ui/about/` | 關於 | 整合在 settings | ✅ |
| `ui/browser/` | 內建瀏覽器 | ❌ (可用 url_launcher) | ⏭️ 低優先 |
| `ui/welcome/` | 歡迎頁 | ❌ (非必須) | ⏭️ 跳過 |
| `ui/association/` | 檔案關聯 | ❌ (iOS 不適用) | ⏭️ 跳過 |
| `ui/widget/` | 自訂元件 | 用 Flutter 內建 | ✅ |

### 其他 Android 模組

| Android | iOS 對應 | 狀態 |
|---------|---------|------|
| `api/` (ReaderProvider, ShortCuts) | 不需要 (Android 特有) | ⏭️ 跳過 |
| `base/` (BaseActivity, BaseViewModel) | Flutter 不需要 | ⏭️ 跳過 |
| `constant/` | 分散在各檔案 | ✅ |
| `exception/` | Dart 異常處理 | ✅ |
| `lib/` (cronet, mobi, dialogs, etc.) | 用 Flutter 套件替代 | ✅ |
| `receiver/` | Android 特有 | ⏭️ 跳過 |

---

## ❌ 尚未完成的功能 (18 項)

### P0 — 核心用戶體驗

| # | 功能 | iOS 缺口 | Android 參考路徑 |
|---|------|---------|-----------------|
| 1 | **閱讀器目錄側滑欄** | `reader_page.dart` L254 TODO | `legado/.../ui/book/read/` |
| 2 | **書源編輯器** | `source_manager_page.dart` L172 TODO | `legado/.../ui/book/source/edit/` |
| 3 | **書源 URL 匯入** | 只有剪貼簿匯入，缺 URL dialog | `legado/.../ui/book/import/` |
| 4 | **替換規則管理 UI** | `content_processor.dart` L113 TODO | `legado/.../ui/replace/edit/` |
| 5 | **書源切換** | `book_detail_provider.dart` L92 TODO | `legado/.../ui/book/changesource/` |

### P1 — 重要增強

| # | 功能 | iOS 缺口 | Android 參考路徑 |
|---|------|---------|-----------------|
| 6 | **繁簡轉換** | `content_processor.dart` L56 TODO, JS t2s/s2t placeholder | `ChineseUtils` |
| 7 | **RSS 完整實作** | 僅骨架 (2.6KB)，缺文章列表/閱讀/解析器 | `legado/.../ui/rss/` (5 子模組) + `model/rss/` (3 檔案) |
| 8 | **換封面** | 無 | `legado/.../ui/book/changecover/` |
| 9 | **正文內搜尋** | 無 | `legado/.../ui/book/searchContent/` |
| 10 | **資料庫遷移** | `app_database.dart` L195 TODO | `AppDatabase.kt` migrations |

### P2 — 進階功能

| # | 功能 | iOS 缺口 | Android 參考路徑 |
|---|------|---------|-----------------|
| 11 | **本地書籍匯入 UI** | 有解析器但缺 UI | `legado/.../ui/file/` |
| 12 | **漫畫閱讀器** | 無 | `legado/.../ui/book/manga/` |
| 13 | **音頻播放器** | 無 | `legado/.../ui/book/audio/` |
| 14 | **快取管理 UI** | 有 service 缺 UI | `legado/.../ui/book/cache/` |
| 15 | **書源登入系統** | 模型有欄位但缺 UI | `legado/.../ui/login/` |
| 16 | **二維碼掃描** | 無 | `legado/.../ui/qrcode/` |
| 17 | **字體管理** | 無 | `legado/.../ui/font/` |
| 18 | **字典查詞** | 無 | `legado/.../ui/dict/` |

---

## 🔧 驗證指令

```powershell
cd 'c:\Users\benny\Desktop\Folder\Project\reader\ios'
& 'C:\flutter_sdk\flutter\bin\flutter.bat' analyze    # 應為 0 issues
& 'C:\flutter_sdk\flutter\bin\flutter.bat' test        # 應為 80+ tests passed
& 'C:\flutter_sdk\flutter\bin\flutter.bat' run         # Android 模擬器
```
