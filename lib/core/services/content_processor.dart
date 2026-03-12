import '../models/chapter.dart';
import '../models/book.dart';
import '../models/replace_rule.dart';
import '../constant/app_pattern.dart';
import 'chinese_utils.dart';

/// ContentProcessor - 內容處理器
/// 負責過濾標題、繁簡轉換、文字排版整理等
/// 對應 Android: help/book/ContentProcessor.kt
class ContentProcessor {
  ContentProcessor();

  /// 基礎處理方法 (供 ExportBookService 使用)
  String process(String content) {
    if (content == "null" || content.isEmpty) return content;
    
    // 執行基本清洗：簡繁轉換與重新分段
    String result = ChineseUtils.t2s(content);
    result = _reSegment(result, "");
    
    // 基本排版：去除多餘空格並加上縮排
    final lines = result.split('\n');
    final processedLines = lines.map((line) {
      final trimmed = line.trimLeft().replaceAll(RegExp(r'^[\s　]+'), '');
      return trimmed.isNotEmpty ? "　　$trimmed" : "";
    }).where((line) => line.isNotEmpty);
    
    return processedLines.join('\n');
  }

  /// 處理正文內容
  static String processContent(
    Book book,
    BookChapter chapter,
    String content, {
    bool includeTitle = true,
    bool useReplace = true,
    bool chineseConvert = true,
    bool reSegment = true,
    List<ReplaceRule>? rules,
  }) {
    if (content == "null" || content.isEmpty) return content;

    String mContent = content;

    // 1. 去除重複標題
    try {
      final nameStr = _escapeRegex(book.name);
      final titleStr = _escapeRegex(
        chapter.title,
      ).replaceAll(AppPattern.spaceRegex, r'\s*');
      final pattern = RegExp(
        '^(\\s|\\p{P}|$nameStr)*$titleStr(\\s)*',
        unicode: true,
      );

      final match = pattern.firstMatch(mContent);
      if (match != null) {
        mContent = mContent.substring(match.end);
      }
    } catch (e) {
      // Ignore regex error
    }

    // 2. 重新分段
    if (reSegment) {
      mContent = _reSegment(mContent, chapter.title);
    }

    // 3. 簡繁轉換
    if (chineseConvert) {
      mContent = ChineseUtils.t2s(mContent);
    }

    // 4. 執行取代規則
    if (useReplace) {
      mContent = mContent.split('\n').map((e) => e.trim()).join('\n');
      if (rules != null && rules.isNotEmpty) {
        mContent = _applyReplaceRules(mContent, book.name, book.origin, rules);
      }
    }

    // 5. 重新加上標題
    if (includeTitle) {
      mContent = '${chapter.title}\n$mContent';
    }

    // 6. 排版整理 (段首縮排)
    final contents = <String>[];
    for (final str in mContent.split('\n')) {
      // 類似 Java Character.isWhitespace
      final paragraph = str.trimLeft().replaceAll(RegExp(r'^[\s　]+'), '');
      if (paragraph.isNotEmpty) {
        if (contents.isEmpty && includeTitle) {
          contents.add(paragraph);
        } else {
          // 預設全形雙空格縮排
          contents.add("　　$paragraph");
        }
      }
    }

    return contents.join('\n');
  }

  /// 重新分段幫助方法
  static String _reSegment(String content, String title) {
    if (content.contains(RegExp(r'<br[^>]*>', caseSensitive: false))) {
      return content.replaceAll(
        RegExp(r'<br[^>]*>', caseSensitive: false),
        '\n',
      );
    }
    // Basic re-segmentation based on spaces if no newlines
    if (!content.contains('\n') && content.length > 50) {
      return content.replaceAll(RegExp(r'[ \t　]{2,}'), '\n');
    }
    return content;
  }

  static String _escapeRegex(String text) {
    return text.replaceAll(AppPattern.regexCharRegex, r'\$&');
  }

  static String _applyReplaceRules(
    String content,
    String bookName,
    String bookOrigin,
    List<ReplaceRule> rules,
  ) {
    String result = content;
    for (final rule in rules) {
      if (!rule.isEnabled) continue;
      // 簡單的範圍判斷 (原版包含正則匹配書名、書源)
      if (rule.scope != null && rule.scope!.isNotEmpty) {
        if (!rule.scope!.contains(bookName) && !rule.scope!.contains(bookOrigin)) {
          continue;
        }
      }
      if (rule.excludeScope != null && rule.excludeScope!.isNotEmpty) {
        if (rule.excludeScope!.contains(bookName) || rule.excludeScope!.contains(bookOrigin)) {
          continue;
        }
      }

      if (!rule.scopeContent) continue;

      try {
        if (rule.isRegex) {
          final pattern = RegExp(rule.pattern, caseSensitive: false);
          result = result.replaceAll(pattern, rule.replacement);
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (e) {
        // Skip invalid regex
      }
    }
    return result;
  }
}
