import 'package:characters/characters.dart';
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

  /// 重新分段幫助方法 (對標 Android ContentHelp.reSegment)
  /// 負責修復斷行、黏合錯誤分段，並優化對話排版。
  static String _reSegment(String content, String title) {
    if (content.isEmpty) return content;

    // 1. 基礎標點修復
    String processed = content
        .replaceAll("&quot;", "“")
        .replaceAll(RegExp(r'[:：]["''‘”“]+'), "：“")
        .replaceAll(RegExp(r'["”“]+\s*["”“][\s"”“]*'), "”\n“");

    // 2. 段落黏合與初步分理
    final lines = processed.split(RegExp(r'\n(\s*)'));
    final buffer = StringBuffer();
    
    if (lines.isNotEmpty && lines[0].trim() != title.trim()) {
      // 去除段落內空格 (unicode 3000 是中全形空格)
      buffer.write(lines[0].replaceAll(RegExp(r'[\u3000\s]+'), ""));
    }

    for (int i = 1; i < lines.length; i++) {
      final currentLine = lines[i].replaceAll(RegExp(r'[\u3000\s]+'), "");
      if (currentLine.isEmpty) continue;

      final lastChar = buffer.toString().isNotEmpty ? buffer.toString().characters.last : "";
      
      // 判斷是否需要換行 (標點符號判斷)
      final sentenceEnd = RegExp(r'[。！？\?!\.]');
      final quoteEnd = RegExp(r'[”"’]');
      
      if (sentenceEnd.hasMatch(lastChar) || 
          (quoteEnd.hasMatch(lastChar) && buffer.length > 1 && sentenceEnd.hasMatch(buffer.toString()[buffer.length - 2]))) {
        buffer.write("\n");
      }
      buffer.write(currentLine);
    }

    // 3. 預分段處理 (對話與引用優化)
    String finalResult = buffer.toString()
        .replaceAll(RegExp(r'["”“]+\s*["”“]+'), "”\n“")
        .replaceAllMapped(RegExp(r'["”“]+([？。！\?!\~])["”“]+'), (m) => "”${m[1]}\n“")
        .replaceAllMapped(RegExp(r'([問說喊唱叫罵道著答])[\.。]'), (m) => "${m[1]}。\n");

    // 4. 清理頭尾空格與格式化
    return finalResult.trim()
        .replaceAll(RegExp(r'\n+'), '\n')
        .replaceAll(RegExp(r'\n\s+'), '\n');
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
      
      // 精確的範圍判斷
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
          // 修復 Android 特有的反斜槓取代行為
          final replacement = rule.replacement.replaceAll(r'$', r'\$');
          final pattern = RegExp(rule.pattern, multiLine: true, dotAll: true);
          result = result.replaceAll(pattern, replacement);
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (e) {
        // Skip invalid regex or timeout simulated by catches
      }
    }
    return result;
  }
}
