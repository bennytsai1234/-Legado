import 'package:characters/characters.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:legado_reader/core/services/chinese_utils.dart';
import 'package:legado_reader/core/constant/app_pattern.dart';

/// ContentProcessor - 閱讀器正文處理引擎
/// 負責：去重、重新分段、簡繁轉換、規則淨化
/// 對位 Android: help/book/ContentProcessor.kt & ContentHelp.kt
class ContentProcessor {
  
  static const String markSentencesEnd = "。！？?!.";
  static const String markQuotationRight = "”\"’";

  /// 處理並返回淨化後的正文
  static String process({
    required Book book,
    required BookChapter chapter,
    required String rawContent,
    required List<ReplaceRule> rules,
    int chineseConvertType = 0, // 0: None, 1: T2S, 2: S2T
    bool reSegmentEnabled = true,
    bool removeSameTitle = true,
  }) {
    if (rawContent.isEmpty) return "";

    String mContent = rawContent;

    // 1. 去除重複標題 (高度還原 Android 正則偵測)
    if (removeSameTitle) {
      mContent = _removeSameTitle(mContent, chapter.title, book.name);
    }

    // 2. 重新分段 (解決部分來源斷行混亂問題)
    if (reSegmentEnabled) {
      mContent = _reSegment(mContent, chapter.title);
    }

    // 3. 簡繁轉換
    if (chineseConvertType == 1) {
      mContent = ChineseUtils.t2s(mContent);
    } else if (chineseConvertType == 2) {
      mContent = ChineseUtils.s2t(mContent);
    }

    // 4. 執行替換規則 (含超時保護)
    mContent = _applyRules(mContent, book, rules);

    return mContent.trim();
  }

  static String _removeSameTitle(String content, String title, String bookName) {
    try {
      final titleStr = RegExp.escape(title).replaceAll(AppPattern.spaceRegex, r'\s*');
      final nameStr = RegExp.escape(bookName);
      final pattern = RegExp('^(\\s|\\p{P}|$nameStr)*$titleStr(\\s)*', unicode: true);
      
      final match = pattern.firstMatch(content);
      if (match != null) {
        return content.substring(match.end);
      }
    } catch (_) {}
    return content;
  }

  static String _reSegment(String content, String chapterName) {
    // 實作精簡版 reSegment (對標 Android ContentHelp.reSegment)
    var lines = content.split(RegExp(r'\n(\s*)'));
    final buffer = StringBuffer();

    for (var line in lines) {
      final cleanLine = line.trim().replaceAll(RegExp(r'[\u3000\s]+'), "");
      if (cleanLine.isEmpty) continue;

      if (buffer.isNotEmpty) {
        final lastChar = buffer.toString().characters.last;
        if (markSentencesEnd.contains(lastChar) || markQuotationRight.contains(lastChar)) {
          buffer.write("\n");
        }
      }
      buffer.write(cleanLine);
    }
    return buffer.toString();
  }

  static String _applyRules(String content, Book book, List<ReplaceRule> rules) {
    String result = content;
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 3);

    for (final rule in rules) {
      if (!rule.isEnabled || !rule.scopeContent) continue;
      if (stopwatch.elapsed > timeout) break;

      // 檢查作用範圍
      if (rule.scope?.isNotEmpty == true) {
        if (!rule.scope!.contains(book.name) && !rule.scope!.contains(book.origin)) continue;
      }

      try {
        if (rule.isRegex) {
          final reg = RegExp(rule.pattern, multiLine: true, dotAll: true);
          result = result.replaceAllMapped(reg, (match) {
            return rule.replacement.replaceAllMapped(RegExp(r'\\\$|\$(\d+)'), (m) {
              final hit = m.group(0)!;
              if (hit == r'\$') return r'$';
              final idx = int.tryParse(m.group(1)!) ?? 0;
              return (idx > 0 && idx <= match.groupCount) ? (match.group(idx) ?? '') : hit;
            });
          });
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (_) {}
    }
    return result;
  }
}
