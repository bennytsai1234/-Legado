import 'package:flutter/material.dart';
import '../../../core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 1.0,
    int textIndent = 2,
    double titleTopSpacing = 0.0,
    double titleBottomSpacing = 8.0,
    bool textFullJustify = true,
    double padding = 16.0,
  }) {
    final List<TextPage> pages = [];
    final double visibleWidth = viewSize.width - (padding * 2);
    // 預留上下各 40.0 的邊距空間
    final double visibleHeight = viewSize.height - 80.0;

    if (visibleWidth <= 0 || visibleHeight <= 0) {
      return [
        TextPage(index: 0, lines: [], title: chapter.title, chapterIndex: chapterIndex, pageSize: 1, chapterSize: chapterSize),
      ];
    }

    final double effectiveParaSpacing = (contentStyle.fontSize ?? 18.0) * paragraphSpacing;

    // 大檔案處理... (省略部分重複邏輯以節省空間，核心在下方迭代)
    final paragraphs = content.split('\n');
    List<TextLine> currentLines = [];
    double currentHeight = 0.0;
    int pageIndex = 0;
    int chapterPosition = 0;
    int paragraphNum = 0;

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      String paraText = paragraphs[pIndex];
      paragraphNum++;

      if (paraText.trim().isEmpty) {
        currentHeight += effectiveParaSpacing;
        chapterPosition += paraText.length + 1;
        continue;
      }

      bool isTitle = (pIndex == 0 && paraText == chapter.title);
      TextStyle style = isTitle ? titleStyle : contentStyle;
      
      // 標題間距與縮排處理
      if (isTitle) {
        currentHeight += titleTopSpacing;
      } else {
        // 段落首行縮排
        if (textIndent > 0) {
          paraText = ("　" * textIndent) + paraText;
        }
      }

      int charStartIndex = 0;
      bool isParagraphStart = true;

      while (charStartIndex < paraText.length) {
        int low = charStartIndex + 1;
        int high = paraText.length;
        int bestEnd = low;
        double currentLineWidth = 0;
        double currentLineHeight = 0;

        while (low <= high) {
          int mid = low + (high - low) ~/ 2;
          textPainter.text = TextSpan(text: paraText.substring(charStartIndex, mid), style: style);
          textPainter.layout(maxWidth: double.infinity);

          if (textPainter.width <= visibleWidth) {
            bestEnd = mid;
            currentLineWidth = textPainter.width;
            currentLineHeight = textPainter.height;
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }

        bool isParaEnd = (bestEnd == paraText.length);
        bool shouldJustify = textFullJustify && !isTitle && !isParaEnd;

        if (currentHeight + currentLineHeight > visibleHeight && currentLines.isNotEmpty) {
          pages.add(TextPage(index: pageIndex++, lines: List.from(currentLines), title: chapter.title, chapterIndex: chapterIndex, chapterSize: chapterSize));
          currentLines.clear();
          currentHeight = 0.0;
        }

        currentLines.add(TextLine(
          text: paraText.substring(charStartIndex, bestEnd),
          width: currentLineWidth,
          height: currentLineHeight,
          isTitle: isTitle,
          isParagraphStart: isParagraphStart,
          isParagraphEnd: isParaEnd,
          shouldJustify: shouldJustify,
          chapterPosition: chapterPosition + charStartIndex,
          lineTop: currentHeight,
          lineBottom: currentHeight + currentLineHeight,
          paragraphNum: paragraphNum,
        ));

        currentHeight += currentLineHeight;
        charStartIndex = bestEnd;
        isParagraphStart = false;
      }

      if (isTitle) {
        currentHeight += titleBottomSpacing;
      } else {
        currentHeight += effectiveParaSpacing;
      }
      chapterPosition += paragraphs[pIndex].length + 1;
    }

    if (currentLines.isNotEmpty) {
      pages.add(TextPage(index: pageIndex++, lines: List.from(currentLines), title: chapter.title, chapterIndex: chapterIndex, chapterSize: chapterSize));
    }

    return pages.asMap().entries.map((e) => e.value.copyWith(index: e.key, pageSize: pages.length)).toList();
  }
}
