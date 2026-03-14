import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'text_page.dart';

/// PageViewWidget - 單頁文字繪製視圖
/// 對應 Android: ui/book/read/page/PageView.kt 與 ContentTextView.kt
class PageViewWidget extends StatelessWidget {
  final TextPage page;
  final TextStyle contentStyle;
  final TextStyle titleStyle;

  const PageViewWidget({
    super.key,
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    // 監聽 Provider 中的自動翻頁進度與排版參數
    final provider = context.watch<ReaderProvider>();

    return Stack(
      children: [
        // 1. 文本與狀態列繪製
        Positioned.fill(
          child: CustomPaint(
            painter: _TextPagePainter(
              page: page,
              contentStyle: contentStyle,
              titleStyle: titleStyle,
              currentTime: DateFormat('HH:mm').format(DateTime.now()),
              batteryLevel: provider.batteryLevel,
              isAutoPaging: provider.isAutoPaging,
              autoPageProgress: provider.autoPageProgress,
              accentColor: Theme.of(context).colorScheme.primary,
              paddingLeft: provider.textPadding,
              paddingTop: 40.0, // 固定頂部空間
            ),
          ),
        ),
        
        // 2. 圖片互動層 (深度還原：支援點擊查看圖片)
        ...page.lines.where((l) => l.image != null).map((line) {
          final img = line.image!;
          return Positioned(
            left: provider.textPadding + img.left,
            top: 40.0 + line.lineTop,
            width: img.width,
            height: img.height,
            child: GestureDetector(
              onTap: () => _showImageDialog(context, img.url),
              child: CachedNetworkImage(
                imageUrl: img.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: url),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("關閉")),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已保存圖片 (模擬)")));
                }, child: const Text("保存")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TextPagePainter extends CustomPainter {
  final TextPage page;
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final String currentTime;
  final int batteryLevel;
  final bool isAutoPaging;
  final double autoPageProgress;
  final Color accentColor;
  final double paddingLeft;
  final double paddingTop;

  _TextPagePainter({
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
    required this.currentTime,
    required this.batteryLevel,
    required this.isAutoPaging,
    required this.autoPageProgress,
    required this.accentColor,
    required this.paddingLeft,
    required this.paddingTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isAutoPaging && autoPageProgress > 0) {
      _drawAutoPageLine(canvas, size);
      canvas.clipRect(Rect.fromLTWH(0, size.height * autoPageProgress, size.width, size.height));
    }

    for (final line in page.lines) {
      final style = line.isTitle ? titleStyle : contentStyle;
      final offset = Offset(paddingLeft, paddingTop + line.lineTop);

      if (line.shouldJustify && line.text.length > 1) {
        // 實作兩端對齊渲染
        final double totalTextWidth = _calculateTextWidth(line.text, style);
        final double spacing = (size.width - (paddingLeft * 2) - totalTextWidth) / (line.text.length - 1);
        
        double currentX = offset.dx;
        for (int i = 0; i < line.text.length; i++) {
          final char = line.text[i];
          final tp = TextPainter(
            text: TextSpan(text: char, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(currentX, offset.dy));
          currentX += tp.width + spacing;
        }
      } else {
        final textSpan = TextSpan(text: line.text, style: style);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, offset);
      }
    }

    _drawHeaderFooter(canvas, size);
  }

  void _drawAutoPageLine(Canvas canvas, Size size) {
    final double y = size.height * autoPageProgress;
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  double _calculateTextWidth(String text, TextStyle style) {
    double totalWidth = 0;
    for (int i = 0; i < text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: text[i], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      totalWidth += tp.width;
    }
    return totalWidth;
  }

  void _drawHeaderFooter(Canvas canvas, Size size) {
    final paintColor = contentStyle.color?.withValues(alpha: 0.5) ?? Colors.grey;
    final textStyle = TextStyle(color: paintColor, fontSize: 12.0);

    if (page.title.isNotEmpty) {
      final titleSpan = TextSpan(text: page.title, style: textStyle);
      final tp = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      tp.layout(maxWidth: size.width - 32);
      tp.paint(canvas, const Offset(16.0, 12.0));
    }

    final timeSpan = TextSpan(text: currentTime, style: textStyle);
    final timeTp = TextPainter(text: timeSpan, textDirection: TextDirection.ltr);
    timeTp.layout();
    timeTp.paint(canvas, Offset(16.0, size.height - 24.0));

    final progressStr = page.readProgress;
    final footerSpan = TextSpan(text: "$progressStr  ", style: textStyle);
    final footerTp = TextPainter(text: footerSpan, textDirection: TextDirection.ltr);
    footerTp.layout();
    
    final footerX = size.width - 16.0 - 25.0 - footerTp.width;
    footerTp.paint(canvas, Offset(footerX, size.height - 24.0));

    _drawBattery(canvas, Offset(size.width - 36.0, size.height - 21.0), paintColor);
  }

  void _drawBattery(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Rect body = Rect.fromLTWH(offset.dx, offset.dy, 20, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), paint);

    final Paint polarPaint = Paint()..color = color..style = PaintingStyle.fill;
    final Rect polar = Rect.fromLTWH(offset.dx + 20, offset.dy + 3, 2, 4);
    canvas.drawRect(polar, polarPaint);

    final double levelWidth = (18 * (batteryLevel / 100)).clamp(0, 18);
    final Rect level = Rect.fromLTWH(offset.dx + 1, offset.dy + 1, levelWidth, 8);
    canvas.drawRect(level, polarPaint);
  }

  @override
  bool shouldRepaint(covariant _TextPagePainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.contentStyle != contentStyle ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.paddingLeft != paddingLeft ||
        oldDelegate.isAutoPaging != isAutoPaging ||
        oldDelegate.autoPageProgress != autoPageProgress;
  }
}
