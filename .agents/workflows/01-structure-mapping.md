---
description: "[1/4] 建立 Android Legado ↔ iOS Reader 的純職責映射地圖 (Pure Map)"
---

# 📐 [1/4] 結構職責映射工作流 (Structure Mapping) v4

本工作流專注於**建立兩端專案的邏輯關聯**，不涉及實作進度或狀態追蹤。

---

## 🎯 核心目標
建立「Android 檔案 ↔ 業務職責 ↔ iOS 檔案」的強關聯地圖，作為後續審計與遷移的基礎導航。

---

## 🏗️ 職責映射鐵律 (Pure Mapping Mandate)

> [!IMPORTANT]
> **1. 拒絕開發狀態**：禁止在此階段標註 ✅/❌ 或填寫「已完成」等狀態資訊。
> **2. 1-to-N 職責鏈**：Android 的一個大型類別（如 `ReadBookConfig.kt`）在 iOS 可能對應多個檔案，必須全部列出。
> **3. 邏輯對標而非檔名對標**：關注檔案在系統中的「角色」（如：分頁算法、資料庫遷移邏輯），而非單純尋找相似檔名。

---

## 執行步驟

### Step 1：環境掃描
- 列出目標 Android 模組路徑下的所有原始碼檔案。
- 讀取這些檔案的開頭註解或核心 Method 名稱以判斷其「業務職責」。

### Step 2：建立對應關係
- 在 iOS `lib/` 目錄下搜尋負責相同業務邏輯的對等檔案。
- **欄位規範**：
  - `Android 檔案`：原始路徑/檔名。
  - `核心職責`：該檔案在 Legado 體系中的核心邏輯（例如：正文渲染、JS 引擎封裝）。
  - `iOS 對應位置`：對應的 Dart 檔案路徑（可多個）。
  - `關鍵依賴項`：Android 關鍵庫 ↔ iOS 關鍵庫。

### Step 3：更新 COMPREHENSIVE_FEATURE_MAPPING.md
- 格式如下：

```markdown
### [模組名稱]
| Android 檔案 | 核心職責 | iOS 對應檔案 | 關鍵依賴對標 |
|:---|:---|:---|:---|
| `BookDao.kt` | 書籍庫存取 | `book_dao.dart` | Room ↔ sqflite |
```

---

## Git 備份
`git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "docs: overhaul structure map (pure mapping)"`

---

## 完成判定
- ✅ **COMPREHENSIVE_FEATURE_MAPPING.md** 已更新，僅包含準確的職責映射與依賴對標，無任何開發狀態描述。
