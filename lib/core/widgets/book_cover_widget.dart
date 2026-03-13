import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// BookCoverWidget - 統一書籍封面小部件
/// 對標 Android: io.legado.app.ui.widget.image.CoverImageView
/// 當封面圖片為空或載入失敗時，會自動產生帶有書名與作者的文字封面
class BookCoverWidget extends StatelessWidget {
  final String? coverUrl;
  final String bookName;
  final String? author;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BookCoverWidget({
    super.key,
    this.coverUrl,
    required this.bookName,
    this.author,
    this.width = 60,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    // 如果 URL 為空或使用特殊標記，直接顯示預設文字封面
    if (coverUrl == null || coverUrl!.isEmpty || coverUrl == 'use_default_cover') {
      imageWidget = _buildTextCover(context);
    } else if (coverUrl!.startsWith('file://') || coverUrl!.startsWith('/')) {
      // 本地檔案
      final path = coverUrl!.replaceFirst('file://', '');
      imageWidget = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildTextCover(context),
      );
    } else {
      // 網路圖片
      imageWidget = CachedNetworkImage(
        imageUrl: coverUrl!,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (context, url, error) => _buildTextCover(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }

  /// 繪製文字封面 (對標 Android drawBookName 與 drawBookAuthor)
  Widget _buildTextCover(BuildContext context) {
    // 根據書名計算一個穩定的背景顏色
    final hash = bookName.hashCode;
    final hue = (hash % 360).toDouble();
    final bgColor = HSLColor.fromAHSL(1.0, hue, 0.4, 0.8).toColor();
    final textColor = HSLColor.fromAHSL(1.0, hue, 0.8, 0.2).toColor();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bookName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: width / 5, // 根據寬度動態調整字體
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (author != null && author!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: width / 7,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]
        ],
      ),
    );
  }
}
