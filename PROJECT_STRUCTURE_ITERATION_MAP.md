# 🏗️ 結構化迭代地圖 (Project Structure Iteration Map)

本文件以 Android (Legado) 資料夾結構為基準，精確記錄每一個子模組的對位與迭代進度。

---

## 📊 模組迭代狀態總覽

| Android 目錄 | 職責描述 | iOS/Flutter 對位路徑 | 狀態 |
| :--- | :--- | :--- | :--- |
| `ui/main` | 主介面、書架、RSS | `lib/features/bookshelf`, `rss` | 🟢 100% |
| `ui/book/read` | 閱讀器核心與排版 | `lib/features/reader` | 🟢 95% |
| `ui/book/source` | 書源管理、編輯、調試 | `lib/features/source_manager` | 🟢 98% |
| `ui/dict` | 字典管理與查詞 | `lib/features/dict` | 🟢 100% |
| `ui/font` | 字體下載與管理 | `lib/features/settings` | 🟢 100% |
| `ui/replace` | 替換規則與調試 | `lib/features/replace_rule` | 🟢 100% |
| `ui/config` | 備份、還原、WebDAV | `lib/features/settings` | 🟢 95% |
| `ui/browser` | 內置瀏覽器與驗證 | `lib/features/browser` | 🟢 100% |
| `data/dao` | 資料庫持久化 | `lib/core/database/dao` | 🟢 90% |
| `data/entities` | 數據模型 | `lib/core/models` | 🟢 95% |
| `service` | 背景服務 (下載、校驗) | `lib/core/services` | 🟡 80% |
| `help` | 輔助工具類 (Coroutines, Http) | `lib/core/services`, `engine` | 🟡 75% |
| `constant` | 全域常數與 PreferKey | `lib/core/constant` | 🟢 100% |
| `receiver` | 廣播接收器 (系統事件) | (iOS Sandbox 限制) | ❌ Missing |
| `web` | 內置 Web 伺服器 (傳書等) | `lib/core/services/web_service.dart` | 🟡 30% |

---

## 🔍 子資料夾精細化迭代日誌

### 📍 1. UI 模組 (`ui/`)
- [x] `ui/main/bookshelf` -> 實作搜尋、分組、多選、批量移動。
- [x] `ui/book/read` -> 實作九宮格點擊、首行縮排、兩端對齊、主題同步。
- [x] `ui/book/source/debug` -> 實作專業版日誌、JSON 美化、HTTP 詳情。
- [x] `ui/font` -> 實作網路下載、預覽文字自定義。
- [x] `ui/login` -> 實作 UA 同步、HttpOnly Cookie 捕捉。

### 📍 2. 資料與持久化 (`data/`)
- [x] `data/dao/BookSourceDao` -> 補齊重排、分組重新命名與標籤移除。
- [x] `data/dao/ChapterDao` -> 補齊全量內容大小統計與清空功能。
- [x] `data/entities` -> 模型對位 (Book, BookSource, ReplaceRule, DictRule)。

### 📍 3. 背景與核心服務 (`service/` & `help/`)
- [x] `help/config/ReadBookConfig` -> 排版參數完全對齊。
- [x] `service/CheckSourceService` -> 實作並行校驗與事件流日誌。
- [x] `service/WebDavService` -> 實作連通性測試與子目錄設定。
- [x] `help/AppWidget` -> 打通 WidgetKit 數據同步鏈。

---

## 🚀 下一階段目標
1.  **`web/` (內置 Web 服務)**: 復刻 Android 的手機與電腦聯動功能。
2.  **`help/` (進階排版)**: 持續細化 3D 仿真翻頁的視覺效果。
3.  **`service/` (通知欄交互)**: iOS 鎖屏播放與朗讀控制強化。

---
*地圖版本: v1.0 | 建立日期: 2026-03-14 | 由全自動迭代工作流產出*
