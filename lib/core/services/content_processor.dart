import '../models/chapter.dart';
import '../models/book.dart';
import '../models/replace_rule.dart';
import 'chinese_utils.dart';
// import '../models/rule_data_interface.dart';
// import '../../services/app_config.dart';

/// ContentProcessor - 內容處理器
/// 負責過濾標題、繁簡轉換、文字排版整理等
/// 對應 Android: help/book/ContentProcessor.kt
class ContentProcessor {
  ContentProcessor._();

  static final RegExp _spaceRegex = RegExp(r'\s+');

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
      ).replaceAll(_spaceRegex, r'\s*');
      final pattern = RegExp(
        '^(\\s|\\p{P}|$nameStr)*$titleStr(\\s)*',
        unicode: true,
      );

      final match = pattern.firstMatch(mContent);
      if (match != null) {
        mContent = mContent.substring(match.end);
      }
      // Note: Android also checks against replaced chapter title here
      // This can be expanded when ReplaceRule logic is fully ported
    } catch (e) {
      // Ignore regex error
    }

    // 2. 重新分段
    if (reSegment && (book.getReSegment() ?? true)) {
      mContent = _reSegment(mContent, chapter.title);
    }

    // 3. 簡繁轉換
    if (chineseConvert) {
      mContent = ChineseUtils.t2s(mContent);
    }

    // 4. 執行取代規則
    if (useReplace && (book.getUseReplaceRule() ?? true)) {
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
    return text.replaceAll(RegExp(r'[.*+?^${}()|[\]\\]'), r'\$&');
  }

  static String _applyReplaceRules(
    String content,
    String bookName,
    String bookOrigin,
    List<ReplaceRule> rules,
  ) {
    var result = content;
    for (final rule in rules) {
      if (!rule.isEnabled) continue;
      // Check scope
      if (rule.scope != null && rule.scope!.isNotEmpty) {
        final scopeContent = rule.scopeContent ?? "";
        if (rule.scope == "1") { // Book Name
          if (!scopeContent.contains(bookName)) continue;
        } else if (rule.scope == "2") { // Source URL
          if (!scopeContent.contains(bookOrigin)) continue;
        }
      }

      try {
        if (rule.isRegex) {
          final pattern = RegExp(rule.pattern, multiLine: true, dotAll: true);
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
