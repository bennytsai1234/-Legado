# COMPREHENSIVE_FEATURE_MAPPING.md

| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **01** | **書架 (Bookshelf)** | `ui/main/bookshelf/` (`BaseBookshelfFragment.kt`, `BookshelfViewModel.kt`) | `features/bookshelf/` (`bookshelf_page.dart`, `bookshelf_provider.dart`) | ✅ |
| **02** | **閱讀器 (Reader)** | `ui/book/read/` (`ReadBookActivity.kt`, `ReadBookViewModel.kt`) | `features/reader/` (`reader_page.dart`, `reader_provider.dart`) | ✅ |
| **03** | **書籍詳情 (Book Info)** | `ui/book/info/` (`BookInfoActivity.kt`, `BookInfoViewModel.kt`) | `features/book_detail/` (`book_detail_page.dart`, `book_detail_provider.dart`) | ✅ |
| **04** | **書源管理 (Source)** | `ui/book/source/` (`BookSourceActivity.kt`, `BookSourceViewModel.kt`) | `features/source_manager/` (`source_manager_page.dart`, `source_provider.dart`) | ✅ |
| **05** | **搜尋 (Search)** | `ui/book/search/` (`SearchActivity.kt`, `SearchViewModel.kt`) | `features/search/` (`search_page.dart`, `search_provider.dart`) | ✅ |
| **06** | **發現 (Explore)** | `ui/book/explore/` (`ExploreActivity.kt`, `ExploreViewModel.kt`) | `features/explore/` (`explore_page.dart`, `explore_provider.dart`) | ✅ |
| **07** | **RSS 訂閱** | `ui/rss/` (`RssActivity.kt`, `RssViewModel.kt`) | `features/rss/` (`rss_page.dart`, `rss_provider.dart`) | ✅ |
| **08** | **替換規則 (Replace)** | `ui/replace/` (`ReplaceRuleActivity.kt`, `ReplaceRuleViewModel.kt`) | `features/replace_rule/` (`replace_rule_page.dart`, `replace_rule_provider.dart`) | ✅ |
| **09** | **歡迎頁 (Welcome)** | `ui/welcome/` (`WelcomeActivity.kt`) | `features/welcome/` (`welcome_page.dart`) | ✅ |
| **10** | **關於 (About)** | `ui/about/` (`AboutActivity.kt`) | `features/about/` (`about_page.dart`) | ✅ |
| **11** | **設置 (Settings)** | `ui/config/` (`ConfigActivity.kt`) | `features/settings/` (`settings_page.dart`) | ✅ |
| **12** | **關聯 (Association)** | `ui/association/` (`AssociationActivity.kt`) | `features/association/` (`association_page.dart`) | ✅ |
| **13** | **本地書籍 (Local Book)** | `ui/file/` (`FileActivity.kt`) | `features/local_book/` (`local_book_page.dart`) | ✅ |
| **14** | **緩存管理 (Cache)** | `ui/book/cache/` (`CacheActivity.kt`) | `features/cache_manager/` (`cache_manager_page.dart`) | ✅ |
| **15** | **字體管理 (Font)** | `ui/font/` (`FontActivity.kt`) | `features/settings/` (?) | ⚠️ |

---
*狀態說明：✅ 已對應 / ⚠️ 部分對應 / 🚨 嚴重缺失 / ❌ 完全缺失*
