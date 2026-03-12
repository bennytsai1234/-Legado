import 'dart:io';
import 'dart:convert';
import 'package:fast_gbk/fast_gbk.dart';

/// TxtParser - 高性能 TXT 解析器
/// 深度還原 Android model/localBook/TextFile.kt 的物理分割邏輯
class TxtParser {
  final File file;
  String _charset = 'UTF-8';
  
  // 深度還原：單個虛擬章節的最大字元數 (約 100KB)
  static const int maxChapterChars = 50000;

  static final RegExp defaultChapterPattern = RegExp(
    r'^.{0,10}[第][0-9零一二两三四五六七八九十百千万万]+[章回节卷集幕计][ \t]*.*',
    multiLine: true,
  );

  TxtParser(this.file);

  /// 自動偵測編碼並執行初步掃描
  Future<void> load() async {
    final bytes = await file.openRead(0, 4096).first; // 只讀取開頭 4KB 偵測編碼
    if (_isUtf8(bytes)) {
      _charset = 'UTF-8';
    } else {
      _charset = 'GBK';
    }
  }

  /// 深度還原：支援物理分割的章節切割邏輯
  Future<List<Map<String, String>>> splitChapters({RegExp? customPattern}) async {
    final pattern = customPattern ?? defaultChapterPattern;
    final String content = await _readFullFile(); // 暫時維持全量讀取以進行正則匹配，但輸出改為分割塊
    
    final List<Map<String, String>> result = [];
    final matches = pattern.allMatches(content).toList();

    if (matches.isEmpty) {
      return _splitLargeContent("正文", content);
    }

    // 處理前言
    if (matches.first.start > 0) {
      result.addAll(_splitLargeContent("前言", content.substring(0, matches.first.start)));
    }

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final title = matches[i].group(0)?.trim() ?? "第 ${i + 1} 章";
      final chapterContent = content.substring(start, end).trim();
      
      // 深度還原：物理分割邏輯
      result.addAll(_splitLargeContent(title, chapterContent));
    }

    return result;
  }

  /// 深度還原：將單個超大內容區塊物理分割為多個虛擬章節
  List<Map<String, String>> _splitLargeContent(String title, String content) {
    if (content.length <= maxChapterChars) {
      return [{'title': title, 'content': content}];
    }

    final List<Map<String, String>> chunks = [];
    int count = 1;
    for (int i = 0; i < content.length; i += maxChapterChars) {
      int end = (i + maxChapterChars < content.length) ? i + maxChapterChars : content.length;
      chunks.add({
        'title': '$title (${count++})',
        'content': content.substring(i, end),
      });
    }
    return chunks;
  }

  Future<String> _readFullFile() async {
    final bytes = await file.readAsBytes();
    if (_charset == 'UTF-8') {
      return utf8.decode(bytes, allowMalformed: true);
    } else {
      return gbk.decode(bytes);
    }
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
        if ((bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80) return false;
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
        if (i + 3 >= bytes.length) return false;
        if ((bytes[i + 1] & 0xC0) != 0x80 || (bytes[i + 2] & 0xC0) != 0x80 || (bytes[i + 3] & 0xC0) != 0x80) return false;
        i += 4;
      } else {
        return false;
      }
    }
    return true;
  }
}
