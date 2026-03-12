---
description: "[5] 迴圈控制器：指定次數重複執行 03-incremental-alignment 或 04-debug 工作流"
---

# 🔁 [5] 迴圈執行工作流 (Loop Runner) v1

本工作流為**控制器**，用於重複調用 `/03-incremental-alignment` 或 `/04-debug`，自動進行多輪修復。

> **適用場景**：報告中有大量 Logic Gap 需要批量修復，或 `flutter analyze` 有多個問題需要逐輪清除。

---

## 使用方式

使用者指定兩個參數：
1. **目標工作流**：`03`（實作修復）或 `04`（除錯）
2. **執行次數**：重複幾輪（如 `3` 表示跑 3 輪）

範例：
```
/05-loop-runner 04 5
→ 執行 /04-debug 工作流 5 次
```

```
/05-loop-runner 03 3
→ 執行 /03-incremental-alignment 工作流 3 次
```

若未指定次數，**預設執行 3 輪**。

---

## 執行步驟

### Step 0：參數解析
- 解析目標工作流（`03` or `04`）
- 解析執行次數 N（預設 3）
- 回報使用者：「即將執行 /0X 工作流 N 次」

### 迴圈開始（第 i 輪，i = 1 到 N）

---

#### ▶ 第 i 輪

1. **宣告輪次**：回報「=== 第 i / N 輪 ===」
2. **執行目標工作流**：按照 `/03-incremental-alignment` 或 `/04-debug` 的完整步驟執行
3. **輪次結果**：記錄本輪修復了什麼（Logic Gap 或 bug）
4. **提前退出判定**：
   - 若為 `/04-debug`：`flutter analyze` 已經零問題 → 提前結束迴圈
   - 若為 `/03-incremental-alignment`：報告中已無 Logic Gap → 提前結束迴圈
5. **段落提交**：本輪完成後統一 Git commit

> [!NOTE]
> 每一輪之間，Git commit 一次。不是每改一個檔案 commit。

---

### 迴圈結束

- **總結報告**：回報使用者
  - 總共執行了 X 輪（含提前退出說明）
  - 每輪修復的摘要
  - 目前剩餘的 Logic Gap 或 analyze 問題數量
  - 建議是否需要繼續下一批迴圈

---

## 提前退出條件

| 目標工作流 | 退出條件 |
|:---|:---|
| `/04-debug` | `flutter analyze` 輸出 0 issues |
| `/03-incremental-alignment` | `FEATURE_AUDIT_v2.md` 中目標模組無剩餘 Logic Gap |

---

## 注意事項

> [!WARNING]
> **Context 長度風險**：每輪都會消耗 context。建議 N ≤ 5。
> 若需要更多輪次，分多次呼叫此工作流，例如先跑 5 輪，看結果後再跑 5 輪。
