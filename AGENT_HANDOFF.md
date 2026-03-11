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
