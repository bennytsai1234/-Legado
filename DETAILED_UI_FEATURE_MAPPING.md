# iOS (Flutter) vs Android (Legado) 細部 UI 功能對照與分析報告

本報告針對 `legado/app/src/main/java/io/legado/app/ui/` 下的各個細部模組進行掃描，與 iOS 版本進行對比，並記錄完成度與改進方案。

---

## 📂 模組：`ui/qrcode` (QR碼掃描與生成)
**功能描述**: 提供書源、替換規則的 QR Code 掃描與生成功能。
| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **QR掃描** | `features/source_manager/qr_scan_page.dart` | 100% | 已補齊從相簿選擇圖片並解析 QR Code 的功能，結合了 `file_picker` 與 `mobile_scanner` 的 `analyzeImage`。 | 已完成。 |

## 📂 模組：`ui/browser` (內建瀏覽器)
**功能描述**: 應用內建的 Web 瀏覽器，用於登入、驗證碼處理或簡單的網頁檢視。
| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **內建瀏覽器** | `shared/widgets/browser_page.dart` | 100% | 已新增 `shared/widgets/browser_page.dart` 作為通用的內建瀏覽器，並支援 Cookie 擷取與自訂標題。 | 已完成。 |

## 📂 模組：`ui/replace` (替換規則管理)
**功能描述**: 替換規則的列表顯示、編輯與測試。
| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **替換規則管理** | `features/replace_rule/replace_rule_page.dart` | 100% | 已實作 `features/replace_rule/replace_rule_edit_page.dart`，提供正則、替換內容、作用範圍等詳細編輯表單，並在列表頁整合。 | 已完成。 |

## 📂 模組：`ui/book/bookmark` (書籤與筆記)
**功能描述**: 閱讀時加入的書籤與筆記列表管理。
| 功能點 | iOS 對應位置 | 完成度 | 不足之處 | 改進方案 |
| :--- | :--- | :--- | :--- | :--- |
| **書籤列表** | `features/bookshelf/bookmark_list_page.dart` | 100% | 已建立 `BookmarkListPage`，查詢 `BookmarkDao` 並顯示列表，支援滑動刪除與點擊跳轉至閱讀器對應位置。 | 已完成。 |

---
