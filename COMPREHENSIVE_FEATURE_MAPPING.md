# 📐 全球功能映射報告 (COMPREHENSIVE_FEATURE_MAPPING)

## 📂 資料夾路徑：`legado/app/src/main/java/io/legado/app/model/analyzeRule`

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AnalyzeByJSonPath.kt` | JSONPath 解析 | `parsers/analyze_by_json_path.dart` | ✅ Matched |
| `AnalyzeByJSoup.kt` | CSS/JSoup 解析 | `parsers/analyze_by_css.dart` | ✅ Matched |
| `AnalyzeByRegex.kt` | 正則表達式解析 | `parsers/analyze_by_regex.dart` | ✅ Matched |
| `AnalyzeByXPath.kt` | XPath 解析 | `parsers/analyze_by_xpath.dart` | ✅ Matched |
| `AnalyzeRule.kt` | 規則解析總控 | `analyze_rule.dart` (及其子模組) | ✅ Matched |
| `AnalyzeUrl.kt` | URL 構建與請求 | `analyze_url.dart` (及其子模組) | ✅ Matched |
| `CustomUrl.kt` | 自定義 URL 封裝 | - | ❌ Missing |
| `RuleAnalyzer.kt` | 規則語法分析器 | `rule_analyzer.dart` | ✅ Matched |
| `RuleData.kt` | 規則數據封裝 | `models/rule_data_interface.dart` (部分) | ⚠️ Partial |
| `RuleDataInterface.kt` | 規則數據介面 | `models/rule_data_interface.dart` | ✅ Matched |

## 📂 資料夾路徑：`legado/app/src/main/java/io/legado/app/data/entities`

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `BaseBook.kt` | 書籍基礎介面 | `models/base_book.dart` | ✅ Matched |
| `BaseSource.kt` | 書源基礎介面 | `models/base_source.dart` | ✅ Matched |
| `Book.kt` | 書籍實體 | `models/book.dart` | ✅ Matched |
| `BookChapter.kt` | 章節實體 | `models/chapter.dart` | ✅ Matched |
| `BookGroup.kt` | 分組實體 | `models/book_group.dart` | ✅ Matched |
| `Bookmark.kt` | 書籤實體 | `models/bookmark.dart` | ✅ Matched |
| `BookSource.kt` | 書源實體 | `models/book_source.dart` | ✅ Matched |
| `ReplaceRule.kt` | 淨化規則實體 | `models/replace_rule.dart` | ✅ Matched |
| `RssSource.kt` | RSS 源實體 | `models/rss_source.dart` | ✅ Matched |
| `SearchBook.kt` | 搜尋結果實體 | `models/search_book.dart` | ✅ Matched |
| `ReadRecordShow.kt` | 閱讀記錄展示 | - | ❌ Missing |

## Git 備份
`git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "docs: recursive map update for io.legado.app.model.analyzeRule"`
