import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// TxtParser - 解析 TXT 格式書籍
/// 對應 Android: model/localBook/TextFile.kt
class TxtParser {
  final File file;
  String? content;
  String _charset = 'UTF-8';

  // 預設切章正則，相容《第X章》等各種常見格式
  static final RegExp defaultChapterPattern = RegExp(
    r'^.{0,10}[第][0-9零一二两三四五六七八九十百千万万]+[章回节卷集幕计][ \t]*.*',
    multiLine: true,
  );

  TxtParser(this.file);

  /// 載入並解析內容，自動偵測編碼 (簡單判斷 UTF-8/GBK)
  Future<void> load() async {
    try {
      final bytes = await file.readAsBytes();

      // 簡單的編碼偵測 heuristics
      bool isUtf8 = _isUtf8(bytes);

      if (isUtf8) {
        _charset = 'UTF-8';
        content = utf8.decode(bytes, allowMalformed: true);
      } else {
        _charset = 'GBK';
        try {
          content = gbk.decode(bytes);
        } catch (_) {
          // 萬一遇到未知編碼或解碼失敗，直接使用 utf8 容錯模式，避免完全無法讀取
          _charset = 'UTF-8 (Malformed)';
          content = utf8.decode(bytes, allowMalformed: true);
        }
      }
    } catch (e) {
      debugPrint("TxtParser load error: \$e");
      throw Exception("Failed to load TXT file: \$e");
    }
  }

  /// 取得編碼
  String get charset => _charset;

  /// 取得全文本內容
  String get fullContent => content ?? "";

  /// 透過正則切出章節列表
  /// 回傳 List<{ title, content }>
  List<Map<String, String>> splitChapters({RegExp? customPattern}) {
    if (content == null || content!.isEmpty) return [];

    final pattern = customPattern ?? defaultChapterPattern;
    final chapters = <Map<String, String>>[];

    final matches = pattern.allMatches(content!);

    if (matches.isEmpty) {
      // 沒切出章節，整本當作一章
      chapters.add({'title': '正文', 'content': content!});
      return chapters;
    }

    int lastStart = 0;
    String lastTitle = "前言";

    // 如果第一個 Match 不是從 0 開始，前面的內容當作前言
    if (matches.first.start > 0) {
      chapters.add({
        'title': lastTitle,
        'content': content!.substring(0, matches.first.start).trim(),
      });
    }

    Match? previousMatch;
    for (final match in matches) {
      if (previousMatch != null) {
        chapters.add({
          'title': lastTitle,
          'content': content!.substring(previousMatch.end, match.start).trim(),
        });
      }

      lastTitle = match.group(0)?.trim() ?? "Unnamed Chapter";
      previousMatch = match;
      lastStart = match.end;
    }

    // 最後一個章節
    if (previousMatch != null) {
      chapters.add({
        'title': lastTitle,
        'content': content!.substring(lastStart).trim(),
      });
    }

    return chapters;
  }

  bool _isUtf8(List<int> bytes) {
    int i = 0;
    while (i < bytes.length) {
      int byte = bytes[i];
      if ((byte & 0x80) == 0) {
        i += 1;
      } else if ((byte & 0xE0) == 0xC0) {
        if (i + 1 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80) return false;
        i += 2;
      } else if ((byte & 0xF0) == 0xE0) {
        if (i + 2 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80) {
          return false;
        }
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
        if (i + 3 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80 ||
            (bytes[i + 2] & 0xC0) != 0x80 ||
            (bytes[i + 3] & 0xC0) != 0x80) {
          return false;
        }
        i += 4;
      } else {
        return false;
      }
    }
    return true;
  }
}
