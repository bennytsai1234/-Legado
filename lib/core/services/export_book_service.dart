import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/services/webdav_service.dart';

class ExportBookService {
  final ChapterDao _chapterDao = ChapterDao();

  /// 匯出全書為 TXT 檔案
  Future<void> exportToTxt(Book book, {Function(double progress)? onProgress}) async {
    final chapters = await _chapterDao.getChapters(book.bookUrl);
    if (chapters.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln(book.name);
    buffer.writeln('作者：${book.author}');
    buffer.writeln('---');

    for (int i = 0; i < chapters.length; i++) {
      final content = await _chapterDao.getContent(book.bookUrl, i);
      if (content != null) {
        buffer.writeln('\n${chapters[i].title}\n');
        buffer.writeln(content);
      }
      if (onProgress != null) onProgress((i + 1) / chapters.length);
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = '${book.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    try {
      await WebDAVService().uploadFile(file.path, fileName);
    } catch (_) {}

    // 使用 SharePlus 的最新靜態語法
    await SharePlus.instance.shareXFiles([XFile(file.path)], subject: '匯出書籍: ${book.name}');
  }
}
