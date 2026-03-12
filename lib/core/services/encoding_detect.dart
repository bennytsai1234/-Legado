import 'dart:convert';
import 'dart:typed_data';

/// EncodingDetect - 簡易編碼偵測工具
/// 針對中文書源優化，支援 UTF-8 (含 BOM) 與 GBK 識別
class EncodingDetect {
  /// 偵測位元組陣列的編碼
  static String getEncode(Uint8List bytes) {
    if (bytes.isEmpty) return "UTF-8";

    // 1. 檢查 UTF-8 BOM (EF BB BF)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return "UTF-8";
    }

    // 2. 嘗試 UTF-8 解碼
    try {
      utf8.decode(bytes);
      return "UTF-8";
    } catch (_) {
      // 3. 若解碼失敗，初步判定為 GBK (中文環境常用回退)
      return "GBK";
    }
  }
}
