# 🔍 審計報告：legado/app/src/main/java/io/legado/app/ui (UI 功能對位)

本報告針對 Android 端 Activity/Fragment 體系與 iOS 端 Page/Widget 體系進行深度邏輯比對。

### 📄 功能模組對比清單
| Android 模組 | 職責描述 | iOS/Flutter 對位 | 狀態 |
|:---|:---|:---|:---|
| `ui/main` | 主導航、書架、發現、我的 | `lib/features/bookshelf` 等 | ✅ Matched |
| `ui/book/read` | 閱讀器核心 (分頁、手勢、菜單) | `lib/features/reader` | ✅ Matched |
| `ui/book/info` | 書籍詳情、換源、緩存管理 | `lib/features/book_detail` | ✅ Matched |
| `ui/book/source` | 書源列表、編輯、匯入 | `lib/features/source_manager` | ✅ Matched |
| `ui/config` | 全域配置中心 | `lib/features/settings` | ✅ Matched |
| `ui/replace` | 替換規則管理 | `lib/features/replace_rule` | ✅ Matched |
| `ui/rss` | RSS 列表與文章閱讀 | `lib/features/rss` | ✅ Matched |
| `ui/about` | 關於、日誌、更新檢查 | `lib/features/about` | ✅ Matched |
| `ui/dict` | 閱讀查詞、字典規則管理 | - | ❌ Missing |
| `ui/font` | 字體管理、下載、預覽 | - | ⚠️ Partial |
| `ui/browser` | 內置瀏覽器與 Web 規則調試 | - | ❌ Missing |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-UI-01: 補齊 `search_page.dart` 的書源分組篩選功能。 ✅ Done in 2026-03-13
- [ ] GAP-UI-02: 實作閱讀器文字長按彈窗中的「查字典」功能 (對標 ui/dict)。
- [ ] GAP-UI-03: 完善 `settings_page.dart` 中的字體預覽與管理。
- [x] GAP-UI-04: 加入「匯入書源」介面的二維碼掃描與檔案匯入整合。 ✅ Done in 2026-03-13

---

## 遞迴審計進度
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [x] `help`
- [x] `data/entities`
- [x] `model`
- [x] `ui`

✅ **UI 層級對位審計完成**
