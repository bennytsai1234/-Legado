---
description: "[1/4] 建立 Android Legado ↔ iOS Reader 的資料夾/檔案結構對應地圖"
---

# 📐 [1/4] 結構地圖建立工作流 (Structure Mapping) v1

本工作流為遷移管線的**第一步**。負責掃描兩端專案目錄，建立物理層級的檔案對應關係。
**不做任何邏輯分析**，僅記錄「A 對應 B」。

> **執行順序**：`01-structure-mapping` → `02-feature-parity` → `03-incremental-alignment` → `04-debug`

---

## 核心產物

- **`COMPREHENSIVE_FEATURE_MAPPING.md`**

---

## 前置條件

- 無（本工作流為管線起點）

---

## 執行模式判定

> [!IMPORTANT]
> **自動判定邏輯**：檢查 `COMPREHENSIVE_FEATURE_MAPPING.md` 是否存在。
> - **不存在** → 預設為 **全量掃描**（自動掃描所有 Android 子目錄）
> - **已存在** → 預設為 **增量掃描**（等待使用者指定目標子目錄）

### 模式 A：全量掃描（預設：檔案不存在時）
掃描 Android `app/src/main/java/io/legado/app/` 下所有子目錄，從零建立完整地圖。

### 模式 B：增量掃描（預設：檔案已存在時）
使用者指定一個 Android 子目錄（如 `ui/book/read/`），僅掃描該範圍並追加至現有地圖。

---

## 執行步驟

### Step 1：判定模式
// turbo
- 檢查 `COMPREHENSIVE_FEATURE_MAPPING.md` 是否存在
- 不存在 → 全量掃描，建立新檔案
- 已存在 → 增量掃描，詢問使用者目標子目錄

### Step 2：Android 端目錄掃描
// turbo
- 列出目標 Android 目錄下所有檔案
- 分類識別每個檔案的角色：
  - `Activity` / `Fragment` → UI 層
  - `ViewModel` → 業務邏輯層
  - `Help` / `Utils` → 工具層
  - `Data` / `DAO` / `Entity` → 資料層
  - `Service` → 背景服務層
  - `Adapter` → UI 呈現層
  - `Dialog` / `Config` → 配置 UI 層

### Step 3：iOS 端對應搜尋
// turbo
- 依據 Android 檔案的功能語義，在 iOS `lib/` 下搜尋對應檔案
- 搜尋策略：
  1. **名稱匹配**：`BookSourceActivity` → `source_manager_page.dart`
  2. **語義匹配**：`ViewModel` → `Provider`，`Help` → `Service/Utils`
  3. **功能匹配**：若命名完全不同，根據功能描述搜尋

### Step 4：寫入地圖檔案
- 追加或建立 `COMPREHENSIVE_FEATURE_MAPPING.md`
- 格式：

```markdown
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 |
|:---|:---|:---|:---|:---|
| **XX** | **模組名** | `ui/xxx/` (檔案列表) | `features/xxx/` (檔案列表) | ✅/⚠️/🚨/❌ |
```

- 狀態定義：
  - ✅ **已對應**：iOS 端有明確對應檔案
  - ⚠️ **部分對應**：iOS 端有功能但結構不同
  - 🚨 **嚴重缺失**：iOS 端僅有骨架或不完整
  - ❌ **完全缺失**：iOS 端完全不存在

### Step 5：Git 備份
```powershell
git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "backup: update COMPREHENSIVE_FEATURE_MAPPING.md"
```

---

## 完成判定

- 所有目標子目錄已掃描完畢
- `COMPREHENSIVE_FEATURE_MAPPING.md` 已更新
- Git 已備份
- 回報使用者掃描結果摘要

---

## 下一步

→ 執行 **`/02-feature-parity`** 進行功能分析
