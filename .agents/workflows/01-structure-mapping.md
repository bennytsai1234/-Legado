---
description: "[1/4] 建立 Android Legado ↔ iOS Reader 的資料夾/檔案結構對應地圖"
---

# 📐 [1/4] 結構地圖建立工作流 (Structure Mapping) v2

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

## 區段錨點規範（Section Anchor）

> [!IMPORTANT]
> 產物檔案使用 HTML 註解錨點標記每個模組的邊界，確保後續工作流更新時 `replace` 操作不會溢出覆蓋相鄰模組。

### 錨點格式
```markdown
<!-- BEGIN_MAPPING_XX -->
### XX. 模組名稱
（此模組的完整檔案對應子表格）
<!-- END_MAPPING_XX -->
```

### 寫入規則
1. **新增模組**：在上一個模組的 `<!-- END_MAPPING_{N-1} -->` 之後追加新的 `BEGIN/END` 區塊
2. **更新模組**：精確替換 `<!-- BEGIN_MAPPING_N -->` 與 `<!-- END_MAPPING_N -->` 之間的全部內容（含錨點本身一起替換以確保完整性）
3. **禁止跨錨點替換**：一次 `replace` 操作**僅允許觸及一個** `BEGIN/END` 對之內的內容

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
- 列出目標 Android 目錄下**所有** `.kt` / `.java` / `.xml` 檔案
- 分類識別每個檔案的角色：
  - `Activity` / `Fragment` → UI 層
  - `ViewModel` → 業務邏輯層
  - `Help` / `Utils` → 工具層
  - `Data` / `DAO` / `Entity` → 資料層
  - `Service` → 背景服務層
  - `Adapter` → UI 呈現層
  - `Dialog` / `Config` → 配置 UI 層

> [!CAUTION]
> **禁止省略檔案**：必須列出目標目錄下的完整檔案清單，禁止只列 2-3 個「代表性」檔案。
> 每個模組的 Android 端至少應記錄所有 `.kt` 檔案名稱與角色分類。

### Step 3：iOS 端對應搜尋
// turbo
- 依據 Android 檔案的功能語義，在 iOS `lib/` 下搜尋對應檔案
- 搜尋策略：
  1. **名稱匹配**：`BookSourceActivity` → `source_manager_page.dart`
  2. **語義匹配**：`ViewModel` → `Provider`，`Help` → `Service/Utils`
  3. **功能匹配**：若命名完全不同，根據功能描述搜尋
- **對每個 Android 檔案都必須記錄對應結果**（即使是「❌ 無對應」也要記錄）

### Step 4：寫入地圖檔案
- 追加或建立 ios 資料夾下 `COMPREHENSIVE_FEATURE_MAPPING.md`
- 檔案結構為**雙層**：頂部總覽表格 + 每模組獨立子章節

#### 4.1 頂部總覽表格
```markdown
# COMPREHENSIVE_FEATURE_MAPPING.md

## 總覽
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | `ui/book/read/` | `features/reader/` | ✅ | 簡要說明 |
```

#### 4.2 模組子章節（使用區段錨點）

每個模組都必須展開為獨立子章節，列出**完整的檔案級對應表**：

```markdown
<!-- BEGIN_MAPPING_01 -->
### 01. 閱讀主界面

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ReadBookActivity.kt` | UI (Activity) | `reader_page.dart` | ✅ 已對應 |
| 2 | `ReadBookViewModel.kt` | 業務邏輯 (ViewModel) | `reader_provider.dart` | ✅ 已對應 |
| 3 | `ReadBookBaseActivity.kt` | UI (Base) | `reader_page.dart` (合併) | ⚠️ 部分合併 |
| 4 | `BrightnessDialog.kt` | 配置 UI (Dialog) | ❌ 無對應 | ❌ 缺失 |
| ... | ... | ... | ... | ... |
<!-- END_MAPPING_01 -->
```

- 狀態定義：
  - ✅ **已對應**：iOS 端有明確對應檔案
  - ⚠️ **部分對應**：iOS 端有功能但結構不同或被合併到其他檔案
  - 🚨 **嚴重缺失**：iOS 端僅有骨架或不完整
  - ❌ **完全缺失**：iOS 端完全不存在

### Step 5：完整性閘門驗證

> [!IMPORTANT]
> 每寫完一個模組的子章節後，**必須立即執行以下驗證**：

1. **`read_file` 回讀**：讀取 `COMPREHENSIVE_FEATURE_MAPPING.md` 中該模組及其前一個模組的區段，確認：
   - 當前模組的 `BEGIN/END` 錨點正確存在
   - **前一個模組的內容未被覆蓋或損毀**
2. **最低檔案數量檢查**：每個模組的子章節檔案對應表至少包含 **3 筆以上**的 Android 檔案記錄
3. 若驗證失敗，**必須回滾該次替換並重試**，縮小 replace 範圍

### Step 6：Git 備份
```powershell
git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "backup: update COMPREHENSIVE_FEATURE_MAPPING.md"
```

---

## 禁止事項

> [!CAUTION]
> 1. **禁止只寫總覽表格不寫子章節**：每個模組必須有獨立的檔案級對應子表格
> 2. **禁止省略檔案**：Android 端的每個 `.kt` 檔案都必須出現在對應表中
> 3. **禁止跨模組 replace**：一次替換操作只能觸及一個 `BEGIN_MAPPING / END_MAPPING` 對
> 4. **禁止使用佔位符**：不得使用 `(待補充)` / `(略)` / `(同上)` 等佔位文字

---

## 完成判定

- 所有目標子目錄已掃描完畢
- `COMPREHENSIVE_FEATURE_MAPPING.md` 已更新，包含：
  - ✅ 頂部總覽表格
  - ✅ 每個模組的獨立子章節（含 `BEGIN/END` 錨點）
  - ✅ 每個子章節的檔案對應表至少 3 筆記錄
- 完整性閘門驗證通過（前序模組未被覆蓋）
- Git 已備份
- 回報使用者掃描結果摘要：X 個模組、Y 個 Android 檔案、Z 個已對應 / W 個缺失

---

## 下一步

→ 執行 **`/02-feature-parity`** 進行功能分析