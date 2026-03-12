import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../core/local_book/epub_parser.dart';
import '../../core/local_book/txt_parser.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';

class LocalBookProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  bool _isImporting = false;

  bool get isImporting => _isImporting;

  Future<bool> importLocalBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub'],
    );

    if (result == null || result.files.single.path == null) return false;

    return await importFile(result.files.single.path!);
  }

  Future<bool> importFile(String path) async {
    _isImporting = true;
    notifyListeners();

    final file = File(path);
    final ext = p.extension(path).toLowerCase();

    try {
      if (ext == '.txt') {
        await _importTxt(file);
      } else if (ext == '.epub') {
        await _importEpub(file);
      }
      return true;
    } catch (e) {
      debugPrint('匯入本地書籍失敗 ($path): $e');
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> _importTxt(File file) async {
    final parser = TxtParser(file);
    await parser.load();
    final chaptersData = parser.splitChapters();

    final book = Book(
      bookUrl: 'local://${file.path}',
      name: p.basenameWithoutExtension(file.path),
      origin: 'local',
      originName: '本地',
      isInBookshelf: true,
    );

    await _bookDao.insertOrUpdate(book);

    final List<BookChapter> chapters = [];
    final List<Map<String, dynamic>> contents = [];
    for (int i = 0; i < chaptersData.length; i++) {
      final item = chaptersData[i];
      final chapter = BookChapter(
        url: 'local://${file.path}#$i',
        title: item['title'] ?? '第 $i 章',
        index: i,
        bookUrl: book.bookUrl,
      );
      chapters.add(chapter);
      contents.add({
        'bookUrl': book.bookUrl,
        'chapterIndex': i,
        'content': item['content'] ?? "",
      });
    }
    
    // Batch insert metadata first, then contents
    await _chapterDao.insertChapters(chapters);
    await _chapterDao.insertContents(contents);
  }

  Future<void> _importEpub(File file) async {
    final parser = EpubParser(file);
    await parser.load();
    final chaptersData = parser.getChapters();

    final book = Book(
      bookUrl: 'local://${file.path}',
      name: parser.title,
      author: parser.author,
      origin: 'local',
      originName: '本地',
      isInBookshelf: true,
    );

    await _bookDao.insertOrUpdate(book);

    final List<BookChapter> chapters = [];
    final List<Map<String, dynamic>> contents = [];
    for (int i = 0; i < chaptersData.length; i++) {
      final item = chaptersData[i];
      final href = item['href'] ?? "";
      final chapter = BookChapter(
        url: href,
        title: item['title'] ?? '第 $i 章',
        index: i,
        bookUrl: book.bookUrl,
      );
      chapters.add(chapter);
      
      final content = parser.getChapterContent(href);
      contents.add({
        'bookUrl': book.bookUrl,
        'chapterIndex': i,
        'content': content,
      });
    }
    
    await _chapterDao.insertChapters(chapters);
    await _chapterDao.insertContents(contents);
  }
}
