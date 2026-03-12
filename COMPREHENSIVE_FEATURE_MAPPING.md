# 📐 Legado Android ↔ iOS Reader 結構地圖 (Structure Mapping)

本文件建立 Android 原生 Legado 與 iOS Flutter Reader 之間的檔案與路徑對應關係。

---

## 1. 核心資料實體 (Core Data Models)
**Android 責任區**: `data/entities/`
**iOS 預期對應位置**: `core/models/`

| ID | 實體名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 1.1 | Book | `Book.kt` | `book.dart` | ✅ |
| 1.2 | BookSource | `BookSource.kt` | `book_source.dart` | ✅ |
| 1.3 | Chapter | `BookChapter.kt` | `chapter.dart` | ✅ |
| 1.4 | Bookmark | `Bookmark.kt` | `bookmark.dart` | ✅ |
| 1.5 | ReplaceRule | `ReplaceRule.kt` | `replace_rule.dart` | ✅ |
| 1.6 | SearchBook | `SearchBook.kt` | `search_book.dart` | ✅ |
| 1.7 | RssSource | `RssSource.kt` | `rss_source.dart` | ✅ |
| 1.8 | RssArticle | `RssArticle.kt` | `rss_article.dart` | ✅ |

---

## 2. 主介面與書架 (Main & Bookshelf)
**Android 責任區**: `ui/main/`
**iOS 預期對應位置**: `features/bookshelf/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 2.1 | Bookshelf Page | `bookshelf/` | `bookshelf_page.dart` | ✅ |
| 2.2 | Bookshelf Logic | `MainViewModel.kt` | `bookshelf_provider.dart` | ✅ |
| 2.3 | Group Management| `ui/book/group/` | `group_manage_page.dart` | ✅ |

---

## 3. 核心閱讀器 (Core Reader)
**Android 責任區**: `ui/book/read/`
**iOS 預期對應位置**: `features/reader/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 3.1 | Reader Page | `ReadBookActivity.kt` | `reader_page.dart` | ✅ |
| 3.2 | Reader Logic | `ReadBookViewModel.kt` | `reader_provider.dart` | ✅ |
| 3.3 | Text Rendering | `help/book/ContentProcessor.kt` | `engine/content_processor.dart` | ⚠️ |
| 3.4 | Manga Reader | `ui/book/manga/` | `manga_reader_page.dart` | ✅ |
| 3.5 | Audio Player | `ui/book/audio/` | `audio_player_page.dart` | ✅ |
| 3.6 | Config / Styles | `ui/book/read/config/` | `engine/reader_config_provider.dart` | ⚠️ |

---

## 4. 書源管理 (Source Management)
**Android 責任區**: `ui/book/source/`
**iOS 預期對應位置**: `features/source_manager/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 4.1 | Source List | `BookSourceActivity.kt` | `source_manager_page.dart` | ✅ |
| 4.2 | Source Edit | `BookSourceEditActivity.kt` | `source_edit_page.dart` | ✅ |
| 4.3 | Source Logic | `BookSourceViewModel.kt` | `source_manager_provider.dart` | ✅ |

---

## 5. 搜尋功能 (Search)
**Android 責任區**: `ui/book/search/`
**iOS 預期對應位置**: `features/search/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 5.1 | Search Page | `SearchActivity.kt` | `search_page.dart` | ✅ |
| 5.2 | Search Logic | `SearchViewModel.kt` | `search_provider.dart` | ✅ |

---

## 6. RSS 訂閱 (RSS)
**Android 責任區**: `ui/rss/`
**iOS 預期對應位置**: `features/rss/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 6.1 | RSS List | `RssActivity.kt` | `rss_list_page.dart` | ✅ |
| 6.2 | RSS Logic | `RssViewModel.kt` | `rss_provider.dart` | ✅ |

---

## 7. 替換規則 (Replace Rules)
**Android 責任區**: `ui/replace/`
**iOS 預期對應位置**: `features/replace_rule/`

| ID | 功能名稱 | Android 檔案 | iOS 對應檔案 | 狀態 |
|:---|:---|:---|:---|:---|
| 7.1 | Replace List | `ReplaceRuleActivity.kt` | `replace_rule_page.dart` | ✅ |
| 7.2 | Replace Logic | `ReplaceRuleViewModel.kt` | `replace_rule_provider.dart` | ✅ |

---

## 狀態定義
- ✅ **已對應**: iOS 端有明確對應檔案
- ⚠️ **部分對應**: iOS 端有功能但結構不同或正在重構
- 🚨 **嚴重缺失**: iOS 端僅有骨架或不完整
- ❌ **完全缺失**: iOS 端完全不存在
