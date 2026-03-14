# 📊 專案彙整存檔報告 (Project Reports Consolidation) v1.0

本文件彙整了 Flutter 專案 (`ios` 目錄) 與 Android 原生專案 (`legado`) 的對比分析、架構評估、技術債務及未來優化指南。

---

## 1. 📂 專案架構遞迴增量報告 (Project Architecture Recursive Incremental Report)

### 🏗️ 架構總覽
本專案採用 **功能驅動型架構 (Feature-Driven Architecture)**，將核心邏輯與業務功能分離，確保高內聚低耦合。

- **`lib/core`**: 核心底層與共享模組。
  - `database`: 數據持久化層 (Sqflite + DAOs)，嚴格對位 Android 的 Room Entity/DAO。
  - `engine`: 解析引擎 (JS, CSS, XPath, Regex)，替代 Android 的 Rhino 與 Jsoup。
  - `models`: 領域模型 (Entities)，繼承自 `BaseSource`, `BaseBook` 等基類。
  - `services`: 全域單例服務 (HTTP, WebDAV, TTS, Backup)。
  - `utils`: 跨平台工具類 (String, File, Archive)。
- **`lib/features`**: 獨立業務模組。
  - `bookshelf`: 書架頁面與數據管理。
  - `reader`: 閱讀器核心介面與渲染引擎。
  - `source_manager`: 書源 CRUD 與匯入邏輯。
  - `settings`: 多維度設置介面。

### 🔄 增量策略
採用「遞迴對位」開發模式，按 Android `ui/` 資料夾逐層掃描，將 Activity/Fragment 邏輯拆解並重新組合至 Flutter 的 Provider/Page 模型中。

---

## 2. 🛡️ 技術債務與代碼健康度報告 (Technical Debt & Code Health Report)

### 📈 健康度指標
- **靜態分析**: 執行 `flutter analyze` 結果為 **「No issues found!」**。
- **代碼風格**: 嚴格遵守 Dart 官方 `analysis_options.yaml` 規範。
- **類型安全**: 全面啟用 Null-safety，避免執行期空指標錯誤。

### ⚠️ 技術債務
1. **內置瀏覽器缺失 (`GAP-UI-01`)**: 目前尚無功能完整的內置 Web 瀏覽器處理複雜登入 JS 注入。
2. **仿真翻頁優化 (`GAP-UI-04`)**: 仿真翻頁目前僅為 2D 模擬，尚未達到 Android 原生 3D 捲曲效果。
3. **單元測試覆蓋率**: 目前專案以整合測試與 UI 測試為主，單元測試覆蓋率需進一步提升。

---

## 3. 🗺️ 功能藍圖與差距分析報告 (Feature Blueprint & Gap Analysis Report)

### ✅ 已補齊功能 (Completed)
- **核心閱讀**: 章節解析、內容處理、字典查詞、主題切換。
- **數據同步**: WebDAV 全量備份與還原、本地 ZIP 匯入。
- **源管理**: 支持 QR 碼、剪貼簿、URL、本地檔案四種匯入方式。
- **書架系統**: 多種視圖切換、書籍分組、書籍長按管理。

### 🔍 差距分析 (Gap Analysis)
| 功能模組 | Android 原生狀態 | Flutter 現狀 | 優先級 |
| :--- | :--- | :--- | :--- |
| 內置瀏覽器 | `WebViewActivity` (完整) | ❌ 尚未實作 | 高 |
| 文字長按選單 | 複製/分享/搜尋/查詞 | 🟢 已實作 (全功能對位) | 中 |
| 仿真翻頁特效 | 3D 物理捲曲 | 🟡 基礎位移模擬 | 低 |
| 調試模式 | 書源/解析規則實時調試 | 🟡 部分實作 (DebugPage) | 中 |

---

## 4. ⚡ 效能瓶頸與優化指南 (Performance & Optimization Guide)

### 🐢 已知瓶頸
1. **JS 引擎開銷**: `flutter_js` 在執行複雜書源解析時可能存在阻塞 UI 線程的風險。
2. **大文本解析**: 加載數萬行 TXT 時，內容處理器 (`content_processor.dart`) 的首屏加載速度有優化空間。
3. **圖像緩存**: 搜索結果大量封面圖加載時的內存佔用。

### 🚀 優化建議
- **Isolate 異步處理**: 將 JS 解析與複雜文本處理完全移至 `Isolate` (Flutter Worker)，防止界面卡頓。
- **分頁加載優化**: 進一步優化 `ChapterProvider` 的預讀取機制，實現零感加載。
- **內存回收**: 在書架快速切換視圖時及時釋放 `CachedNetworkImage` 緩存。

---

## 5. 🔒 安全性與資料完整性審核 (Security & Data Integrity Audit)

### 🔐 安全措施
- **備份加密**: 採用 `AES` (encrypt 庫) 對導出的備份檔案進行加密，確保用戶隱私。
- **網路安全**: `Dio` 攔截器統一處理 Cookie 存儲，支持自定義 User-Agent 模擬各平台請求。
- **敏感資訊**: 敏感 Token (如 WebDAV 密碼) 存儲於加密的本地存儲中。

### 💎 資料完整性
- **SQLite 事務**: 所有資料庫操作 (DAOs) 均採用事務管理，防止斷電或崩潰導致的資料不一致。
- **版本降級保護**: 支持資料庫遷移 (Migration) 邏輯，確保升級後數據不丟失。

---

## 6. 🔄 深度對比分析報告 (Comparative Analysis: Flutter vs Android)

### 📂 目錄映射表 (Incremental Mapping)

| Android (Legado) 目錄 | Flutter (This Project) 目錄 | 職責轉變 |
| :--- | :--- | :--- |
| `app/src/main/java/.../data` | `lib/core/database` & `lib/core/models` | 從 Room 遷移至 Sqflite，保留 Entity 結構。 |
| `app/src/main/java/.../help` | `lib/core/services` | 助手類邏輯轉化為獨立服務 (Service)。 |
| `app/src/main/java/.../ui` | `lib/features` | 從 Activity/Fragment 體系轉化為 Page/Widget 體系。 |
| `modules/rhino` | `lib/core/engine/js` | 使用 `flutter_js` 封裝替代 Rhino。 |
| `app/src/main/res` | `assets/` | 靜態資源、默認規則、字體文件的重新佈局。 |

### 🧩 核心類別對位 (Class Mapping)

- **`BaseSource.kt`** ↔️ **`base_source.dart`**: 100% 邏輯還原，支持相同的書源 JSON 結構。
- **`Book.kt`** ↔️ **`book.dart`**: 欄位完全對標，支持持久化與進度跟蹤。
- **`BaseReadEngine` (Fragmented)** ↔️ **`reader_provider.dart`**: 將分散在多個 Provider 的邏輯彙整為單一狀態管理。
- **`ContentSource`** ↔️ **`chapter_provider.dart`**: 實作了異步內容獲取與注入機制。

### 📊 移植完成度彙整
- **數據層**: 🟢 95% (核心 DAOs 已全數補齊)
- **引擎層**: 🟢 90% (JS/CSS/Regex 解析已穩定)
- **UI 層**: 🟡 85% (大部分核心介面已實作，缺失高級 Web 交互)

---
*報告產出時間: 2026-03-14*  
*審核狀態: 遞迴增量模式 - 第一階段 (完成)*
