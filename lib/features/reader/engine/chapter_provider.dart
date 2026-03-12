import 'package:flutter/material.dart';
import '../../../core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  static const double paddingTop = 40.0;
  static const double paddingBottom = 40.0;
  static const double paddingLeft = 16.0;
  static const double paddingRight = 16.0;

  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 16.0,
  }) {
    final List<TextPage> pages = [];
    final double visibleWidth = viewSize.width - paddingLeft - paddingRight;
    final double visibleHeight = viewSize.height - paddingTop - paddingBottom;

    if (visibleWidth <= 0 || visibleHeight <= 0) {
      return [
        TextPage(
          index: 0,
          lines: [],
          title: chapter.title,
          chapterIndex: chapterIndex,
          pageSize: 1,
          chapterSize: chapterSize,
        ),
      ];
    }

    // 深度還原：大檔案預處理分割邏輯 (對標 Android TextFile.analyze)
    // 若單章超過 50,000 字，為了排版效能，我們在這裡進行物理切塊
    const int splitThreshold = 50000;
    if (content.length > splitThreshold) {
      final List<TextPage> allSubPages = [];
      int start = 0;
      int subChapterIdx = 1;
      while (start < content.length) {
        int end = start + splitThreshold;
        if (end > content.length) {
          end = content.length;
        } else {
          // 確保在換行符處分割，保持語義完整
          final nextNewline = content.indexOf('\n', end);
          if (nextNewline != -1 && nextNewline < end + 5000) {
            end = nextNewline;
          }
        }
        
        final subContent = content.substring(start, end);
        final subPages = paginate(
          content: subContent,
          chapter: chapter.copyWith(title: '${chapter.title} ($subChapterIdx)'),
          chapterIndex: chapterIndex,
          chapterSize: chapterSize,
          viewSize: viewSize,
          titleStyle: titleStyle,
          contentStyle: contentStyle,
          paragraphSpacing: paragraphSpacing,
        );
        allSubPages.addAll(subPages);
        start = end;
        subChapterIdx++;
      }
      // 重新修正頁碼與頁數
      return allSubPages.asMap().entries.map((e) => e.value.copyWith(
        index: e.key,
        pageSize: allSubPages.length,
      )).toList();
    }

    final paragraphs = content.split('\n');
    List<TextLine> currentLines = [];
    double currentHeight = 0.0;
    int pageIndex = 0;
    int chapterPosition = 0;
    int paragraphNum = 0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      String paraText = paragraphs[pIndex];
      paragraphNum++;

      if (paraText.trim().isEmpty) {
        currentHeight += paragraphSpacing;
        chapterPosition += paraText.length + 1;
        continue;
      }

      bool isTitle = (pIndex == 0 && paraText == chapter.title);
      TextStyle style = isTitle ? titleStyle : contentStyle;

      int charStartIndex = 0;
      while (charStartIndex < paraText.length) {
        int low = charStartIndex + 1;
        int high = paraText.length;
        int bestEnd = low;
        double currentLineWidth = 0;
        double currentLineHeight = 0;

        // Binary search for the maximum substring that fits in visibleWidth
        while (low <= high) {
          int mid = low + (high - low) ~/ 2;
          textPainter.text = TextSpan(
            text: paraText.substring(charStartIndex, mid),
            style: style,
          );
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

        // Failsafe: if a single character is wider than view (rare), advance by 1
        if (bestEnd == charStartIndex) {
          bestEnd = charStartIndex + 1;
          textPainter.text = TextSpan(
            text: paraText.substring(charStartIndex, bestEnd),
            style: style,
          );
          textPainter.layout();
          currentLineWidth = textPainter.width;
          currentLineHeight = textPainter.height;
        }

        bool isParaEnd = (bestEnd == paraText.length);

        if (currentHeight + currentLineHeight > visibleHeight &&
            currentLines.isNotEmpty) {
          pages.add(
            TextPage(
              index: pageIndex++,
              lines: List.from(currentLines),
              title: chapter.title,
              chapterIndex: chapterIndex,
              chapterSize: chapterSize,
            ),
          );
          currentLines.clear();
          currentHeight = 0.0;
        }

        currentLines.add(
          TextLine(
            text: paraText.substring(charStartIndex, bestEnd),
            width: currentLineWidth,
            height: currentLineHeight,
            isTitle: isTitle,
            isParagraphEnd: isParaEnd,
            chapterPosition: chapterPosition + charStartIndex,
            lineTop: currentHeight,
            lineBottom: currentHeight + currentLineHeight,
            paragraphNum: paragraphNum,
          ),
        );

        currentHeight += currentLineHeight;
        charStartIndex = bestEnd;
      }

      currentHeight += paragraphSpacing;
      chapterPosition += paraText.length + 1;
    }

    if (currentLines.isNotEmpty) {
      pages.add(
        TextPage(
          index: pageIndex++,
          lines: List.from(currentLines),
          title: chapter.title,
          chapterIndex: chapterIndex,
          chapterSize: chapterSize,
        ),
      );
    }

    if (pages.isEmpty) {
      return [
        TextPage(
          index: 0,
          lines: [],
          title: chapter.title,
          chapterIndex: chapterIndex,
          pageSize: 1,
          chapterSize: chapterSize,
        ),
      ];
    }

    return pages
        .map(
          (p) => TextPage(
            index: p.index,
            lines: p.lines,
            title: p.title,
            chapterIndex: p.chapterIndex,
            chapterSize: p.chapterSize,
            pageSize: pages.length,
          ),
        )
        .toList();
  }
}
