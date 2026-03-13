# 🔍 審計報告：legado/app/src/main/java/io/legado/app/data/entities (資料實體對位)

本報告針對 Android 端實體類別與 iOS 端模型類別進行深度邏輯比對。

### 📄 檔案對比清單
| Android 檔案 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `Book.kt` | ✅ Matched | `book.dart` 已完整移植，含 `migrateTo` 進度對齊演算法與位元運算擴展。 |
| `BookSource.kt` | ✅ Matched | `book_source.dart` 完整相容 3.0 規則 JSON，內嵌規則類別 (Search/Toc/Content) 已對位。 |
| `BookChapter.kt` | ✅ Matched | 對標 `chapter.dart`，已移植檔名生成與標題淨化邏輯。 |
| `BookGroup.kt` | ✅ Matched | 對標 `book_group.dart`，支援分組位元運算。 |
| `Bookmark.kt` | ✅ Matched | 對標 `bookmark.dart`。 |
| `ReplaceRule.kt` | ✅ Matched | 對標 `replace_rule.dart`，含 JSON 解析與校驗。 |
| `HttpTTS.kt` | ✅ Matched | 對標 `http_tts.dart`。 |
| `RssSource.kt` | ✅ Matched | 對標 `rss_source.dart`。 |
| `SearchBook.kt` | ✅ Matched | 對標 `search_book.dart`。 |
| `TxtTocRule.kt` | ✅ Matched | 對標 `txt_toc_rule.dart`。 |
| `Cookie.kt` | ✅ Matched | 對標 `cookie.dart`。 |
| `BaseBook.kt` | ✅ Matched | 對標 `base_book.dart` 介面。 |
| `BaseSource.kt` | ✅ Matched | 對標 `base_source.dart` 介面。 |
| `Cache.kt` | ✅ Matched | 對標 `cache.dart`。 |
| `BookChapterReview.kt` | ✅ Matched | 對標 `book_chapter_review.dart`。 |
| `BookProgress.kt` | ✅ Matched | 對標 `book_progress.dart` (WebDAV 同步用)。 |
| `DictRule.kt` | ✅ Matched | 對標 `dict_rule.dart`。 |
| `KeyboardAssist.kt` | ✅ Matched | 對標 `keyboard_assist.dart`。 |
| `ReadRecord.kt` | ✅ Matched | 對標 `read_record.dart`。 |
| `RssArticle.kt` | ✅ Matched | 對標 `rss_article.dart`。 |
| `SearchKeyword.kt` | ✅ Matched | 對標 `search_keyword.dart`。 |
| `Server.kt` | ✅ Matched | 對標 `server.dart`。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-ENT-01: 在 `book.dart` 中補齊 `variableMap` 的延遲加載 (Lazy) 實作。 ✅ Done in 2026-03-13
- [x] GAP-ENT-02: 在 `book_source.dart` 中補齊 `getSearchRule()` 等 Getter 的安全初始化邏輯。 ✅ Done in 2026-03-13
- [x] GAP-ENT-03: 實作 `RuleSub.kt` 的對位模型。 ✅ Done in 2026-03-13
- [x] GAP-ENT-04: 實作 `BookSourcePart.kt` 的對位模型。 ✅ Done in 2026-03-13

---

## 遞迴審計進度
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [x] `help`
- [x] `data/entities`

✅ **資料實體對位審計完成**
