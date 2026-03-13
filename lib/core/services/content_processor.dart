import 'package:flutter/foundation.dart';
import 'package:characters/characters.dart';
import '../models/chapter.dart';
import '../models/book.dart';
import '../models/replace_rule.dart';
import '../constant/app_pattern.dart';
import 'chinese_utils.dart';

/// ContentProcessor - 內容處理器
/// 負責過濾標題、繁簡轉換、文字排版整理等
/// 對應 Android: help/book/ContentProcessor.kt & ContentHelp.kt
class ContentProcessor {
  ContentProcessor();

  static const String markSentencesEnd = "。！？?!.";
  static const String markQuotationRight = "”\"’";
  static const String markQuotationLeft = "“\"‘";

  /// 段落縮排 (對標 Android: ReadBookConfig.paragraphIndent)
  static String paragraphIndent = "　　";

  /// 基礎處理方法 (供 ExportBookService 使用)
  String process(String content, {bool toTraditional = false}) {
    if (content == "null" || content.isEmpty) return content;
    String result = toTraditional ? ChineseUtils.s2t(content) : ChineseUtils.t2s(content);
    result = reSegment(result, "");
    
    final lines = result.split('\n');
    final processedLines = lines.map((line) {
      final paragraph = line.trimLeft().replaceAll(RegExp(r'^[\s　]+'), '');
      return paragraph.isNotEmpty ? "$paragraphIndent$paragraph" : "";
    }).where((line) => line.isNotEmpty);
    
    return processedLines.join('\n');
  }

  /// 處理正文內容 (深度對標 Android ContentProcessor.getContent)
  static String processContent(
    Book book,
    BookChapter chapter,
    String content, {
    bool includeTitle = true,
    bool useReplace = true,
    int chineseConvertType = 0, // 0: None, 1: T2S, 2: S2T
    bool reSegmentEnabled = true,
    List<ReplaceRule>? rules,
  }) {
    if (content == "null" || content.isEmpty) return content;

    String mContent = content;

    // 1. 去除重複標題 (對標 Android: 支援原始標題與淨化後標題匹配)
    try {
      final nameStr = _escapeRegex(book.name);
      final titleStr = _escapeRegex(chapter.title).replaceAll(AppPattern.spaceRegex, r'\s*');
      final pattern = RegExp('^(\\s|\\p{P}|$nameStr)*$titleStr(\\s)*', unicode: true);

      final match = pattern.firstMatch(mContent);
      if (match != null) {
        mContent = mContent.substring(match.end);
      } else if (useReplace && book.getUseReplaceRule()) {
        // 二次回退匹配 (使用可能已被淨化過的標題)
        // 此處簡化實作，僅執行基礎正則
      }
    } catch (_) {}

    // 2. 重新分段 (核心演算法)
    if (reSegmentEnabled && book.getReSegment()) {
      mContent = reSegment(mContent, chapter.title);
    }

    // 3. 簡繁轉換
    if (chineseConvertType == 1) {
      mContent = ChineseUtils.t2s(mContent);
    } else if (chineseConvertType == 2) {
      mContent = ChineseUtils.s2t(mContent);
    }

    // 4. 執行取代規則 (對標 Android: 支援 scope 與正則替換)
    if (useReplace && book.getUseReplaceRule()) {
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
      final paragraph = str.trimLeft().replaceAll(RegExp(r'^[\s　]+'), '');
      if (paragraph.isNotEmpty) {
        if (contents.isEmpty && includeTitle) {
          contents.add(paragraph);
        } else {
          contents.add("$paragraphIndent$paragraph");
        }
      }
    }

    return contents.join('\n');
  }

  /// 重新分段核心演算法 (高度還原 Android ContentHelp.reSegment)
  static String reSegment(String content, String chapterName) {
    if (content.isEmpty) return content;

    // 1. 預處理標點與基礎切分
    var p = content
        .replaceAll("&quot;", "“")
        .replaceAll(RegExp(r'[:：]["''‘”“]+'), "：“")
        .replaceAll(RegExp(r'["”“]+\s*["”“][\s"”“]*'), "”\n“")
        .split(RegExp(r'\n(\s*)'));

    final buffer = StringBuffer();
    buffer.write("  "); // Android 初始冗餘縮排

    if (p.isNotEmpty && chapterName.trim() != p[0].trim()) {
      // 去除首段內部空格
      buffer.write(p[0].replaceAll(RegExp(r'[\u3000\s]+'), ""));
    }

    // 2. 段落黏合邏輯 (解決錯誤斷行)
    for (int i = 1; i < p.length; i++) {
      final currentLine = p[i].replaceAll(RegExp(r'[\u3000\s]+'), "");
      if (currentLine.isEmpty) continue;

      final lastChar = buffer.toString().isNotEmpty ? buffer.toString().characters.last : "";
      
      // 判斷是否應該換行 (對標 Android match 邏輯)
      bool shouldBreak = false;
      if (markSentencesEnd.contains(lastChar)) {
        shouldBreak = true;
      } else if (markQuotationRight.contains(lastChar)) {
        final bStr = buffer.toString();
        if (bStr.length > 1 && markSentencesEnd.contains(bStr.characters.elementAt(bStr.characters.length - 2))) {
          shouldBreak = true;
        }
      }

      if (shouldBreak) {
        buffer.write("\n");
      }
      buffer.write(currentLine);
    }

    // 3. 預分段細化處理 (對話與語氣助詞引發的斷行)
    String intermediate = buffer.toString()
        .replaceAll(RegExp(r'["”“]+\s*["”“]+'), "”\n“")
        .replaceAllMapped(RegExp(r'["”“]+([？。！\?!\~])["”“]+'), (m) => "”${m[1]}\n“")
        .replaceAllMapped(RegExp(r'["”“]+([？。！\?!\~])([^"”“])'), (m) => "”${m[1]}\n${m[2]}")
        .replaceAllMapped(RegExp(r'([問說喊唱叫罵道著答])[\.。]'), (m) => "${m[1]}。\n");

    // 4. 最終清理與格式統一
    return intermediate
        .replaceFirst(RegExp(r'^\s+'), "")
        .replaceAll(RegExp(r'\s*["”“]+\s*["”“][\s"”“]*'), "”\n“")
        .replaceAllMapped(RegExp(r'[:：][”“\"\s]+'), (m) => "：“")
        .replaceAllMapped(RegExp(r'\n["“”]([^\n\"“”]+)([,:，：]["”“])([^\n\"“”]+)'), (m) => "\n${m[1]}：“${m[3]}")
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .trim();
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
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 3); // 總體處理超時

    for (final rule in rules) {
      if (!rule.isEnabled) continue;
      
      // 超時檢查 (對標 Android RegexTimeoutException)
      if (stopwatch.elapsed > timeout) {
        debugPrint("Replace rules processing timeout for $bookName");
        break;
      }

      if (rule.scope != null && rule.scope!.isNotEmpty) {
        if (!rule.scope!.contains(bookName) && !rule.scope!.contains(bookOrigin)) continue;
      }
      if (rule.excludeScope != null && rule.excludeScope!.isNotEmpty) {
        if (rule.excludeScope!.contains(bookName) || rule.excludeScope!.contains(bookOrigin)) continue;
      }

      if (!rule.scopeContent) continue;

      try {
        if (rule.isRegex) {
          final pattern = RegExp(rule.pattern, multiLine: true, dotAll: true);
          result = result.replaceAllMapped(pattern, (match) {
            // 用正則匹配 replacement 中的 $1, $2... 或 \$
            return rule.replacement.replaceAllMapped(RegExp(r'\\\$|\$(\d+)'), (m) {
              final hit = m.group(0)!;
              if (hit == r'\$') {
                return r'$'; // \$ -> $
              } else {
                final groupIndex = int.tryParse(m.group(1)!) ?? 0;
                if (groupIndex > 0 && groupIndex <= match.groupCount) {
                  return match.group(groupIndex) ?? '';
                }
                return hit; // 如果群組索引無效，保留原狀
              }
            });
          });
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (_) {
        // Skip invalid regex
      }
    }
    stopwatch.stop();
    return result;
  }
}
