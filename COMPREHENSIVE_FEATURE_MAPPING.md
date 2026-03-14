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

## Git 備份
`git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "docs: recursive map update for io.legado.app.model.analyzeRule"`
