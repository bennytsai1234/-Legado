import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book.dart';
import '../database/dao/chapter_dao.dart';
import 'content_processor.dart';
import 'webdav_service.dart';

class ExportBookService {
  final ChapterDao _chapterDao = ChapterDao();
  final ContentProcessor _processor = ContentProcessor();

  /// 匯出全書為 TXT 檔案 (深度還原：支援規則套用、進度回饋與 WebDAV 同步)
  Future<void> exportToTxt(Book book, {Function(double progress)? onProgress}) async {
    final chapters = await _chapterDao.getChapters(book.bookUrl);
    if (chapters.isEmpty) {
      throw Exception("書籍目錄為空，請先下載目錄");
    }

    final buffer = StringBuffer();
    buffer.writeln(book.name);
    buffer.writeln("作者：${book.author.isEmpty ? '未知' : book.author}");
    buffer.writeln("來源：${book.originName}");
    buffer.writeln("-" * 20);
    buffer.writeln();

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      String? content = await _chapterDao.getContent(book.bookUrl, chapter.index);
      
      buffer.writeln(chapter.title);
      buffer.writeln();
      
      if (content != null && content.isNotEmpty) {
        content = _processor.process(content);
        buffer.writeln(content);
      } else {
        buffer.writeln("(該章節尚未下載快取)");
      }
      
      buffer.writeln();
      buffer.writeln("-" * 10);
      buffer.writeln();

      if (onProgress != null) {
        onProgress((i + 1) / chapters.length);
      }
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = book.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final fileName = '$safeName.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    // 深度還原：同步至 WebDAV (對標 Android exportWebDav)
    try {
      await WebDAVService().uploadFile(file.path, fileName);
    } catch (e) {
      debugPrint("同步匯出檔案至 WebDAV 失敗: $e");
      // 同步失敗不影響本地匯出與分享
    }

    // 調用系統分享分發檔案
    await Share.shareXFiles([XFile(file.path)], text: '匯出書籍: ${book.name}');
  }
}
