# 🔍 Legado 功能對齊審計報告 (Feature Parity Audit) v2

本報告基於 Android 原生代碼與 iOS Flutter 實作的深度語義比對，識別邏輯缺口 (Logic Gaps) 與占位符 (Placeholders)。

---

## 📈 真實完成度概覽 (Real Parity Score)

| 核心模組 | 預計對標點 | 已達成 (Matched) | 缺口/占位符 | 真實完成度 |
| :--- | :---: | :---: | :---: | :---: |
| **解析引擎 (Engine)** | 12 | 8 | 4 | 66.7% |
| **內容處理 (Processor)** | 8 | 6 | 2 | 75.0% |
| **資料持久化 (DAO)** | 22 | 21 | 1 | 95.4% |
| **業務助手 (Services)** | 10 | 6 | 4 | 60.0% |
| **總計** | **52** | **41** | **11** | **78.8%** |

> **計算公式**: `Matched / (Matched + Logic Gap + Placeholder)`
> *註：Placeholder 與 Logic Gap 均不計入分子。*

---

## 🚨 關鍵邏輯缺口明細 (Critical Logic Gaps)

### 1. 解析引擎 (Analyze Engine)
| 邏輯點 / Method | Android 證據 | iOS 證據 | 診斷描述 |
| :--- | :--- | :--- | :--- |
| `java.ajax()` | `AnalyzeRule.kt`: L652 | ❌ 缺失 | JS 規則調用 `java.ajax` 將崩潰，導致部分動態載入書源失效。 |
| `Redirect Management` | `AnalyzeRule.kt`: L111 | ❌ 缺失 | 缺少重定向 URL 維護，相對路徑拼接在重定向後會出錯。 |
| `JS Context: Cookie` | `AnalyzeRule.kt`: L623 | ❌ 缺失 | JS 環境未注入 CookieStore，無法在 JS 中直接操作 Cookie。 |

### 2. 內容處理 (Content Processor)
| 邏輯點 / Method | Android 證據 | iOS 證據 | 診斷描述 |
| :--- | :--- | :--- | :--- |
| `Regex Timeout` | `ContentProcessor.kt`: L132 | 🚨 基礎實作 | 缺少正則執行超時控制，易受 ReDoS 攻擊導致 UI 卡死。 |
| `Bi-Chinese Convert` | `ContentProcessor.kt`: L119 | 🚨 僅簡轉繁 | 缺少「簡轉繁」支援，對港台用戶支援不完全。 |
| `Dynamic Indent` | `ContentProcessor.kt`: L166 | 🚨 固定值 | 縮排固定為雙空格，無法自定義。 |

### 3. UI 與 系統整合
| 邏輯點 / Method | Android 證據 | iOS 證據 | 診斷描述 |
| :--- | :--- | :--- | :--- |
| `Background Sync` | `WebDavService` | 🚨 Placeholder | 部分同步邏輯標註為 `TODO` 或僅在前景觸發。 |
| `Audio Preload` | `ExoPlayerHelper` | ❌ 缺失 | 缺少音頻書籍的預加載與進階緩存控制。 |

---

## 🛠️ 下一步修復建議 (Alignment Strategy)

1.  **優先修復解析引擎**：在 `analyze_rule.dart` 中實作 `ajax` 與 `redirectUrl` 維護，這是書源相容性的生命線。
2.  **增強 JS 環境**：補全 `cookie` 與 `cache` 的注入。
3.  **安全加固**：為 `content_processor.dart` 的正則替換加入超時中斷機制。

---

## 🏗️ 職責映射鐵律驗證
- [x] **占位符搜查**：已掃描 `TODO`, `_showComingSoon` 並記錄。
- [x] **API 完整性矩陣**：已對標 `AnalyzeRule` 與 `ContentProcessor` 的 Public Methods。
- [x] **Git 備份**：執行 `git add FEATURE_AUDIT_v2.md ; git commit`
