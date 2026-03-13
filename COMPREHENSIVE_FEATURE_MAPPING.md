# COMPREHENSIVE_FEATURE_MAPPING.md

| ID | 模組名稱 | Android 責任區 (`io.legado.app`) | iOS 預期對應位置 (`lib/`) | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | `ui/book/read/` (ReadBookActivity, ViewModel) | `features/reader/` (reader_page, provider) | ✅ | iOS 目錄(TOC)在 Drawer 中 |
| **02** | **書架主頁** | `ui/main/bookshelf/` (BaseBookshelfFragment, ViewModel) | `features/bookshelf/` (bookshelf_page, provider) | ✅ | |
| **03** | **書籍詳情** | `ui/book/info/` (BookInfoActivity, ViewModel) | `features/book_detail/` (book_detail_page, provider) | ✅ | |
| **04** | **書源管理** | `ui/book/source/` (manage/, edit/) | `features/source_manager/` (source_manager_page, provider) | ✅ | |
| **05** | **搜尋功能** | `ui/book/search/` | `features/search/` | ✅ | |
| **06** | **發現/探索** | `ui/book/explore/` | `features/explore/` | ✅ | |
| **07** | **目錄與書籤** | `ui/book/toc/` | `features/reader/` (Drawer & Bookmark list) | ⚠️ | 結構不同，iOS 整合在閱讀器內 |
| **08** | **備份與還原** | `help/storage/` | `features/settings/backup_settings_page.dart` | ✅ | |
| **09** | **替換規則** | `ui/replace/` | `features/replace_rule/` | ✅ | |
| **10** | **RSS 訂閱** | `ui/rss/` | `features/rss/` | ✅ | |
| **11** | **數據模型** | `data/entities/` | `core/models/` | ✅ | |
| **12** | **資料存取 (DAO)** | `data/dao/` | `core/database/dao/` | ✅ | |
| **13** | **核心服務** | `help/` (BookHelp, SourceHelp, etc.) | `core/services/` | ✅ | |
| **14** | **關於介面** | `ui/about/` | `features/about/` | ✅ | |
| **15** | **啟動歡迎頁** | `ui/welcome/` | `features/welcome/` | ✅ | |
| **16** | **書源關聯** | `ui/association/` | `features/association/` | ✅ | |
| **17** | **本地書籍掃描** | `ui/file/` | `features/local_book/` | ✅ | |

## 掃描摘要
- **掃描日期**: 2026-03-13
- **Android 根路徑**: `legado/app/src/main/java/io/legado/app/`
- **iOS 根路徑**: `reader/ios/lib/`
- **主要差異**:
  - Android 使用多 Activity/Fragment 結構。
  - iOS (Flutter) 使用單 Activity + Navigator 結構，模組劃分更傾向於 `features/` 模式。
  - 核心邏輯 (Services/Models) 在 iOS 中被整合在 `core/` 下。
