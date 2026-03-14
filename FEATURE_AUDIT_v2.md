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
- [ ] GAP-ANALYZE-01: 實作 `CustomUrl` 類別，支援 URL 屬性解析與 `toString()` 序列化。
- [ ] GAP-ANALYZE-02: 實作 `RuleData` 類別，補全 `RuleDataInterface` 的具體業務邏輯。
<!-- AUDIT_FOLDER_END -->
