<!-- AUDIT_FOLDER: legado/app/src/main/java/io/legado.app.model.analyzeRule -->
## 🔍 審計報告：`io.legado.app.model.analyzeRule`

### 📄 檔案對比清單
| 檔案名稱 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `AnalyzeByJSonPath.kt` | ✅ Matched | 已精確重構，邏輯對位。 |
| `AnalyzeByJSoup.kt` | ✅ Matched | 已重構為 `analyze_by_css.dart` 及其子模組，結構對位。 |
| `AnalyzeRule.kt` | ✅ Matched | 核心分發與子擴展（Core, Script, Parsers）已完整拆分。 |
| `CustomUrl.kt` | ❌ Missing | **移植規格**：需在 `ios/lib/core/engine/analyze_url/` 新建 `custom_url.dart`，用於封裝帶 JSON 屬性的 URL 字串。 |
| `RuleData.kt` | ⚠️ Partial | **移植規格**：需在 `rule_data_interface.dart` 同目錄實作 `RuleData` 類，補全 `variableMap` 的 JSON 序列化邏輯。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-ANALYZE-01: 實作 `CustomUrl` 類別，支援 URL 屬性解析與 `toString()` 序列化。
- [x] GAP-ANALYZE-02: 實作 `RuleData` 類別，補全 `RuleDataInterface` 的具體業務邏輯。

## 🔍 審計報告：`io.legado.app.data.entities`

### 📄 檔案對比清單
| 檔案名稱 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `Book.kt` | ⚠️ Partial | **移植規格**：需在 `book_extensions.dart` 補全進度百分比計算與 `simulatedTotalChapterNum` 邏輯。 |
| `BookSource.kt` | ⚠️ Partial | **移植規格**：需在 `book_source_logic.dart` 強化分組解析，對齊 `splitNotBlank` 行為。 |
| `SearchBook.kt` | ⚠️ Partial | **移植規格**：需在 `search_book.dart` 實作 `origins` 集合與 `addOrigin` 方法，支持搜尋結果聚合。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [ ] GAP-DATA-01: 在 `BookExtensions` 補全閱讀進度百分比與模擬章節邏輯。
- [ ] GAP-DATA-02: 在 `BookSourceLogic` 強化分組標籤解析。
- [ ] GAP-DATA-03: 在 `SearchBook` 加入多來源聚合邏輯。
<!-- AUDIT_FOLDER_END -->
