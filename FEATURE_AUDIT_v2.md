# 🔍 審計報告：legado/app/src/main/java/io/legado/app/model (業務邏輯對位)

本報告針對 Android 端業務邏輯核心 (Model) 及其子目錄進行深度對比。

### 📄 檔案對比清單
| Android 檔案 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `AudioPlay.kt` | ✅ Matched | `audio_play_service.dart` 已實作，包含定時睡眠與播放模式切換。 |
| `CacheBook.kt` | ✅ Matched | `download_service.dart` 實作了多執行緒書籍快取與持久化。 |
| `CheckSource.kt` | ✅ Matched | `check_source_service.dart` 完整對位。 |
| `Download.kt` | ✅ Matched | `download_service.dart` 完整對位。 |
| `ReadAloud.kt` | ✅ Matched | `tts_service.dart` 已支援語音朗讀。 |
| `ReadBook.kt` | ✅ Matched | 閱讀器核心狀態管理已整合至 `reader_provider.dart`，功能完整。 |
| `SharedJsScope.kt` | ✅ Matched | `shared_js_scope.dart` 提供 JS 引擎共用變數支援。 |
| `BookCover.kt` | ⚠️ Partial | **診斷**：Flutter 的 `image_loader.dart` 缺乏 Android 端對預設純文字封面的生成邏輯 (Canvas 繪製文字圖片)。 |
| `Debug.kt` | ⚠️ Partial | **診斷**：缺乏完整的書源解析日誌收集與 WebSocket 輸出邏輯。 |
| `ReadManga.kt` | ⚠️ Partial | **診斷**：漫畫閱讀器 `manga_reader_page.dart` 尚未實作 Android 端完整的頁面預載入與手勢縮放機制。 |

### 📂 子資料夾審計：analyzeRule (解析引擎)
| Android 檔案 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `AnalyzeRule.kt` 等 | ✅ Matched | 支援 JSONPath, CSS, XPath, Regex 解析，且 `RuleAnalyzer` 已高度還原，功能完善。 |

### 📂 子資料夾審計：localBook (本地書籍)
| Android 檔案 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `EpubFile.kt` | ✅ Matched | 使用 `epubx` 套件支援。 |
| `TextFile.kt` | ✅ Matched | 支援 TXT 檔案分章。 |
| `UmdFile.kt` | ✅ Matched | 支援 UMD 格式解析。 |
| `MobiFile.kt` | ❌ Missing | **移植規格**：尚未找到合適的 Dart Mobi 解析庫，建議標記為未來特性或利用 C/Rust 庫透過 FFI 解析。 |
| `PdfFile.kt` | ❌ Missing | **移植規格**：缺乏本地 PDF 解析與提取文字的實作。 |

### 📂 子資料夾審計：rss & webBook (網路解析)
| Android 檔案 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `rss/*` | ✅ Matched | RSS 訂閱解析 `rss_parser.dart` 實作完整。 |
| `webBook/*` | ✅ Matched | `book_source_engine.dart` 與相關模型已完成網路書源的目錄/詳情解析。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-MOD-01: 補齊 `BookCover.kt` 的預設文字封面生成邏輯 (BookCoverWidget)。 ✅ Done in 2026-03-13
- [x] GAP-MOD-02: 完善 `Debug.kt` 邏輯，已透過 `DebugPage` 與事件總線整合完成。 ✅ Done in 2026-03-13
- [x] GAP-MOD-03: `ReadManga.kt` 漫畫閱讀模式優化 (手勢雙擊縮放與水平方向反轉)。 ✅ Done in 2026-03-13
- [x] GAP-MOD-04: 針對 `Mobi` 與 `Pdf` 支援進行可行性評估，建立解析器佔位符。 ✅ Done in 2026-03-13

---

## 遞迴審計進度
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [x] `help`
- [x] `data/entities`
- [x] `model`

✅ **業務邏輯對位審計完成**
