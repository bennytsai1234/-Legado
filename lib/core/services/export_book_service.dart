import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book.dart';
import '../database/dao/chapter_dao.dart';

class ExportBookService {
  final ChapterDao _chapterDao = ChapterDao();

  /// 匯出全書為 TXT 檔案
  Future<void> exportToTxt(Book book) async {
    final chapters = await _chapterDao.getChapters(book.bookUrl);
    if (chapters.isEmpty) {
      throw Exception("書籍目錄為空");
    }

    final buffer = StringBuffer();
    buffer.writeln(book.name);
    buffer.writeln("作者：${book.author.isEmpty ? '未知' : book.author}");
    buffer.writeln("-" * 20);
    buffer.writeln();

    for (final chapter in chapters) {
      final content = await _chapterDao.getContent(book.bookUrl, chapter.index);
      buffer.writeln(chapter.title);
      buffer.writeln();
      if (content != null && content.isNotEmpty) {
        buffer.writeln(content);
      } else {
        buffer.writeln("(章節未快取)");
      }
      buffer.writeln();
      buffer.writeln("-" * 10);
      buffer.writeln();
    }

    final tempDir = await getTemporaryDirectory();
    // 清理檔名非法字元
    final safeName = book.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${tempDir.path}/$safeName.txt');
    await file.writeAsString(buffer.toString());

    // 調用分享
    await Share.shareXFiles([XFile(file.path)], text: '匯出書籍: ${book.name}');
  }
}
