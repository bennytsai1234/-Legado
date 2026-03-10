# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-10 23:00  
> **目標**: 將 Android Legado 閱讀器完整移植到 iOS（使用 Flutter）  
> **當前狀態**: 核心閱讀路徑已通 + R1 基本完成，整體完成度約 **50%**

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
├── main.dart                    ← 入口 (MultiProvider)
├── core/
│   ├── engine/
│   │   ├── analyze_rule.dart    ← 規則總控 (347行, ~55% of Android)
│   │   ├── analyze_url.dart     ← URL 引擎 (335行, ~40% of Android) ✅ 已強化
│   │   ├── rule_analyzer.dart   ← 規則切割器 (352行, ~80% of Android)
│   │   ├── js/
│   │   │   ├── js_engine.dart         ← QuickJS 包裝 (53行)
│   │   │   ├── js_extensions.dart     ← java.* 橋接 (357行) ✅ 大幅擴充
│   │   │   └── js_encode_utils.dart   ← 加密工具 (183行) ✅ 已擴充
│   │   └── parsers/
│   │       ├── analyze_by_css.dart         (12KB)
│   │       ├── analyze_by_json_path.dart   (4KB)
│   │       ├── analyze_by_xpath.dart       (4KB)
│   │       └── analyze_by_regex.dart       (3KB)
│   ├── models/                  ← 28 個數據模型
│   ├── database/
│   │   ├── app_database.dart    ← SQLite (含 cookies 表)
│   │   └── dao/                 ← 6 個 DAO (+1 CookieDao) ✅ 新增
│   │       ├── book_source_dao.dart
│   │       ├── book_dao.dart
│   │       ├── chapter_dao.dart
│   │       ├── cookie_dao.dart       ✅ 新增
│   │       ├── replace_rule_dao.dart
│   │       └── search_history_dao.dart
│   └── services/
│       ├── book_source_service.dart   (206行)
│       ├── rate_limiter.dart
│       ├── cookie_store.dart          ✅ 新增 (100行)
│       ├── http_client.dart           ✅ 新增 (50行, Dio singleton)
│       └── cache_manager.dart         ✅ 新增 (47行)
├── features/                    ← 7 個頁面 (每個含 page + provider)
└── shared/theme/
```

---

## 🔧 開發約定

- **修改方式**: 禁止 `write_file` 覆寫 Git 追蹤檔案，僅用 `replace`
- **備份**: 修改後立即 `git add <file> ; git commit -m "backup: ..."`
- **對話語言**: 繁體中文 | **代碼**: 英文 | **Commit**: Conventional Commits 英文
- **狀態管理**: Provider + ChangeNotifier
- **網路**: Dio (全域 HttpClient 單例) | **資料庫**: sqflite | **JS 引擎**: flutter_js

---

## ✅ 已完成的 JS 橋接方法 (共 ~35 個)

以下方法已在 `js_extensions.dart` 中實作並注入到 `java.*` 物件：

```
✅ java.ajax(url)                    ✅ java.ajaxAll(urlList)
✅ java.connect(url)                 ✅ java.get(url, headers)
✅ java.post(url, body, headers)     ✅ java.head(url, headers)
✅ java.getCookie(tag, key)          ✅ java.createSymmetricCrypto(...)
✅ java.log(msg)                     ✅ java.toast(msg) / longToast
✅ java.md5Encode(str)               ✅ java.md5Encode16(str)
✅ java.base64Encode(str)            ✅ java.base64Decode(str, charset)
✅ java.encodeURI(str)               ✅ java.hexEncode(str)
✅ java.hexDecode(hex)               ✅ java.randomUUID()
✅ java.timeFormat(time)             ✅ java.htmlFormat(str)
✅ java.t2s(text) [placeholder]      ✅ java.s2t(text) [placeholder]
✅ java.strToBytes(str, charset)     ✅ java.bytesToStr(bytes, charset)
✅ java.readFile(path)               ✅ java.readTxtFile(path, charset)
✅ java.downloadFile(url)            ✅ java.toNumChapter(s)
✅ java.importScript(path)           ✅ java.cacheFile(url, saveTime)
```

**已完成的加密方法** (js_encode_utils.dart)：
```
✅ md5Encode / md5Encode16
✅ base64Encode (含 flags) / base64Decode (含 charset) / base64DecodeToBytes
✅ symmetricCrypto (底層統一方法, 含 AES/模式/填充)
✅ aesEncode / aesDecode / aesDecodeArgsBase64Str
✅ hmacHex / hmacBase64 (HmacMD5, HmacSHA1, HmacSHA256)
✅ digest (SHA-1, SHA-256, MD5, hex/base64 輸出)
```

**已完成的基礎設施**：
```
✅ CookieStore — 完整 Cookie CRUD + 記憶體快取 + 二級域名解析
✅ HttpClient — Dio singleton + Cookie 攔截器 (自動注入/保存)
✅ CacheManager — 檔案快取 (讀/寫/刪)
✅ CookieDao — sqflite CRUD
✅ AnalyzeUrl — 已加入 Cookie 整合、表單參數、URL 編碼、重定向、<js> 標籤支援
```

---

## ❌ 尚未完成的功能 (按優先級排序)

以下每個任務列出：**要做什麼**、**Android 原始碼在哪**、**iOS 要建/改哪個檔案**。

Android 路徑前綴 = `legado\app\src\main\java\io\legado\app\` (簡稱 `A:`)  
iOS 路徑前綴 = `ios\lib\` (簡稱 `I:`)

---

### 🔴 任務群 A：JS 橋接 — 剩餘進階方法

> 基礎的網路/編碼/檔案方法已完成。以下是仍未實作的進階方法。

#### A1. WebView 渲染類 (反爬關鍵)

| 功能 | Android (A:`help/JsExtensions.kt`) | iOS 目標 (I:`core/engine/js/js_extensions.dart`) |
|------|-----------------------------------|-------------------------------------------------|
| WebView 渲染 | `webView(html, url, js)` L163 | `java.webView` — 用 webview_flutter 離屏載入 |
| WebView 取源碼 | `webViewGetSource(...)` L185 | `java.webViewGetSource` |
| WebView 取跳轉 | `webViewGetOverrideUrl(...)` L204 | `java.webViewGetOverrideUrl` |
| 開啟瀏覽器 | `startBrowser(url, title)` L228 | `java.startBrowser` |
| 等待瀏覽器結果 | `startBrowserAwait(...)` L238 | `java.startBrowserAwait` |
| 驗證碼 | `getVerificationCode(imageUrl)` L253 | `java.getVerificationCode` |

#### A2. 字體反爬 (進階，單獨大任務)

| 功能 | Android | iOS 目標 |
|------|---------|---------|
| TTF 字體解析 | `A:model/analyzeRule/QueryTTF.java` (39KB) | 建 `I:core/engine/js/query_ttf.dart` |
| 解析 Base64 TTF | `queryBase64TTF(data)` L795 | `java.queryBase64TTF` |
| 解析 TTF | `queryTTF(data, useCache)` L807 | `java.queryTTF` |
| 字體替換 | `replaceFont(text, errorTTF, correctTTF)` L861 | `java.replaceFont` |

#### A3. 壓縮檔處理

| 功能 | Android 方法 | iOS 建議 |
|------|-------------|---------|
| 解壓 ZIP | `unzipFile(zipPath)` L614 | `archive` 套件 |
| 解壓 7z | `un7zFile(zipPath)` L623 | 可延後 |
| 解壓 RAR | `unrarFile(zipPath)` L632 | 可延後 |
| 讀 ZIP 內容 | `getZipStringContent(url, path)` L677 | `archive` 套件 |

#### A4. 繁簡轉換 (目前是 placeholder)

| 功能 | Android | iOS 建議 |
|------|---------|---------|
| 繁→簡 `t2s` | `ChineseUtils.t2s()` | 考慮用 opencc 字典或查表法 |
| 簡→繁 `s2t` | `ChineseUtils.s2t()` | 同上 |

#### A5. JsEncodeUtils 剩餘方法

| 功能 | Android (A:`help/JsEncodeUtils.kt`) | 說明 |
|------|-------------------------------------|------|
| DES 系列 | `desDecodeToString(...)` 等 | 目前 DES 走了 AES fallback |
| 3DES 系列 | `tripleDesDecodeToString(...)` 等 | 同上 |
| RSA 非對稱 | `createAsymmetricCrypto(transformation)` L76 | 需 pointycastle |
| 簽名 | `createSign(algorithm)` L83 | 需 pointycastle |

---

### 🔴 任務群 B：核心引擎強化

#### B1. AnalyzeRule 強化 (目前 347行 vs Android 908行)

| 缺失功能 | Android 位置 (A:`model/analyzeRule/AnalyzeRule.kt`) | 說明 |
|---------|--------------------------------------------------|------|
| `@put:{}` 解析 | `splitPutRule()` L405-431 | 存取變數到 RuleData |
| HTML 反轉義 | `StringEscapeUtils.unescapeHtml4()` | 用 `html_unescape` 套件 |
| JS 編譯快取 | `compileScriptCache()` L806-810 | 避免重複解析 JS |
| Regex 編譯快取 | `compileRegexCache()` L462-470 | `RegExp` 物件重用 |
| 單元素獲取 | `getElement()` L329-361 | 返回單一物件而非列表 |
| Chapter 上下文 | `setChapter()` L843-845 | 目錄翻頁需要 |
| SourceRule.splitRegex | `splitRegex()` L624-654 | `$1` `$2` 正則組引用 |

#### B2. SharedJsScope (跨腳本變數共用)

| Android | iOS 目標 |
|---------|---------|
| `A:model/SharedJsScope.kt` (87行) | 建 `I:core/engine/js/shared_js_scope.dart` |

LRU 快取已執行的 JS 作用域，用 jsLib 的 MD5 作 key。支援 URL 或 JSON 格式的 jsLib。

---

### 🟡 任務群 C：BookSourceService 增強

| 缺失功能 | Android 位置 | iOS 位置 | 說明 |
|---------|-------------|---------|------|
| 正文翻頁 | `A:model/webBook/BookContent.kt` L34 nextContentUrl | 改 `I:core/services/book_source_service.dart` | 正文也需 nextUrl 翻頁 |
| 精確搜尋 | `A:model/webBook/WebBook.kt` `preciseSearch()` L358 | 新增方法 | 按書名+作者匹配 |
| 內容處理器 | `A:help/book/ContentProcessor.kt` (207行) | 建 `I:core/services/content_processor.dart` | 替換規則+繁簡+去重複標題 |
| 書源登入 | `A:help/source/SourceVerificationHelp.kt` (4KB) | 建 `I:core/services/source_login.dart` | loginUrl/loginUi 流程 |

---

### 🟡 任務群 D：DAO 補全

| DAO | Android (A:`data/dao/`) | iOS 目標 (I:`core/database/dao/`) | 優先級 |
|-----|------------------------|-------------------------------|--------|
| BookmarkDao | `BookmarkDao.kt` (2KB) | 建 `bookmark_dao.dart` | P0 |
| CacheDao | `CacheDao.kt` (1KB) | 建 `cache_dao.dart` | P0 |
| ReadRecordDao | `ReadRecordDao.kt` (2KB) | 建 `read_record_dao.dart` | P1 |
| BookGroupDao | `BookGroupDao.kt` (3KB) | 建 `book_group_dao.dart` | P1 |
| RssSourceDao | `RssSourceDao.kt` (5KB) | 建 `rss_source_dao.dart` | P2 |
| RssArticleDao | `RssArticleDao.kt` (1KB) | 建 `rss_article_dao.dart` | P2 |
| 其他 9 個 | DictRuleDao, HttpTTSDao, etc. | 各建對應檔案 | P3 |

---

### 🟡 任務群 E：閱讀器排版引擎

| 功能 | Android 參考 | iOS 目標 |
|------|-------------|---------|
| 文字測量+分頁 | `A:ui/book/read/page/provider/ChapterProvider.kt` | 建 `I:features/reader/engine/chapter_provider.dart` |
| 頁面數據模型 | `A:ui/book/read/page/entities/TextPage.kt` + `TextLine.kt` | 建 `I:features/reader/engine/text_page.dart` |
| 翻頁容器 | `A:ui/book/read/page/PageView.kt` (17KB) | 建 `I:features/reader/engine/page_view_widget.dart` |
| 翻頁動畫 | `A:ui/book/read/page/delegate/` (7 種) | 建 `I:features/reader/engine/delegates/` |
| 閱讀狀態 | `A:model/ReadBook.kt` (1055行, 37KB) | 大幅改進 `I:features/reader/reader_provider.dart` |

---

### 🟢 任務群 F：系統服務整合

| 功能 | Android 參考 | iOS 目標 | 建議套件 |
|------|-------------|---------|---------|
| TTS 朗讀 | `A:service/TTSReadAloudService.kt` (9KB) | 建 `I:core/services/tts_service.dart` | `flutter_tts` |
| WebDAV | `A:help/AppWebDav.kt` (13KB) | 建 `I:core/services/webdav_service.dart` | `webdav_client` |
| 離線下載 | `A:service/CacheBookService.kt` + `A:model/CacheBook.kt` | 建 `I:core/services/download_service.dart` | Dio + Isolate |
| 書源校驗 | `A:service/CheckSourceService.kt` (10KB) | 建 `I:core/services/check_source_service.dart` | |
| 備份還原 | `A:help/storage/Backup.kt` + `Restore.kt` | 建 `I:core/services/backup_service.dart` | |
| 閱讀設定 | `A:help/config/ReadBookConfig.kt` + `AppConfig.kt` | 建 `I:core/services/app_config.dart` | shared_preferences |

---

### ⚪ 任務群 G：進階功能 (低優先)

| 功能 | Android 參考 | iOS 目標 | 建議套件 |
|------|-------------|---------|---------|
| 本地 EPUB | `A:model/localBook/EpubFile.kt` (17KB) | 建 `I:core/local_book/epub_parser.dart` | `epubx` |
| 本地 TXT | `A:model/localBook/TextFile.kt` (21KB) | 建 `I:core/local_book/txt_parser.dart` | 自建 |
| RSS 模組 | `A:model/rss/` + `A:ui/rss/` (30 檔) | 建 `I:features/rss/` | |
| 漫畫模式 | `A:ui/book/manga/` (21 檔) | 建 `I:features/manga/` | |
| 有聲書 | `A:model/AudioPlay.kt` + `A:service/AudioPlayService.kt` | 建 `I:features/audio/` | `just_audio` |

---

## ⚠️ 已知技術風險

1. **flutter_js (QuickJS) 相容性**: 所有 `java.*` 呼叫必須透過橋接模擬
2. **GBK 編碼**: Dart 原生不支援，需 `gbk_codec` 或 `charset_converter`
3. **iOS 背景執行**: TTS/下載需在 `Info.plist` 宣告 `UIBackgroundModes`
4. **QueryTTF**: Android 39KB Java，移植工作量大但重要
5. **t2s/s2t**: 目前是 placeholder，需要繁簡轉換字典
6. **DES/3DES**: 目前走 AES fallback，需要正確實作

---

## ⚡ 常用指令

```powershell
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; dart analyze lib/
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter test
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter run
```
