# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping)
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/constant

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConst.kt` | 全域常數、支援格式、超時設定 | - | ❌ Missing |
| `AppLog.kt` | 紀錄層級、日誌相關標記 | - | ❌ Missing |
| `AppPattern.kt` | 正規表達式模式定義 (日期、URL 等) | `lib/core/constant/app_pattern.dart` | ✅ Matched |
| `BookSourceType.kt` | 書源類型列舉 (文字、音訊等) | - | ❌ Missing |
| `BookType.kt` | 書籍類型 (本地、網路等) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `EventBus.kt` | 事件總線標記 (雖然 Flutter 多用 Stream) | - | ❌ Missing |
| `IntentAction.kt` | Android Intent 動作定義 | - | ❌ Missing |
| `NotificationId.kt` | 通知 ID 定義 | - | ❌ Missing |
| `PageAnim.kt` | 翻頁動畫類型 | - | ❌ Missing |
| `PreferKey.kt` | SharedPreferences 鍵名定義 | `lib/core/constant/prefer_key.dart` | ✅ Matched |
| `SourceType.kt` | 來源類型 (書源、RSS) | - | ❌ Missing |
| `Status.kt` | 下載或同步狀態 | - | ❌ Missing |
| `Theme.kt` | 主題相關常數 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/exception

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ConcurrentException.kt` | 併發衝突異常 | - | ❌ Missing |
| `ContentEmptyException.kt` | 內容為空異常 | - | ❌ Missing |
| `EmptyFileException.kt` | 檔案為空異常 | - | ❌ Missing |
| `InvalidBooksDirException.kt` | 書籍目錄無效異常 | - | ❌ Missing |
| `NoBooksDirException.kt` | 書籍目錄不存在異常 | - | ❌ Missing |
| `NoStackTraceException.kt` | 無堆疊軌跡異常基類 | - | ❌ Missing |
| `RegexTimeoutException.kt` | 正則匹配超時異常 | - | ❌ Missing |
| `TocEmptyException.kt` | 目錄為空異常 | - | ❌ Missing |

---

## 遞迴進度回報
- [x] `constant`
- [x] `exception`
- [ ] `utils`
- [ ] `help`
- [ ] `model`
- [ ] `data`
- [ ] `service`
- [ ] `ui`
