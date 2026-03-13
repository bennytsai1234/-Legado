import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_js/flutter_js.dart';
import '../../core/local_book/epub_parser.dart';
import '../../core/local_book/txt_parser.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';

class LocalBookProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final JavascriptRuntime _jsRuntime = getJavascriptRuntime();
  bool _isImporting = false;

  bool get isImporting => _isImporting;

  /// 深度還原：利用 JS 解析檔名獲取書名與作者
  Future<Map<String, String>> _parseFileName(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsCode = prefs.getString('book_import_file_name_js') ?? '';
    
    if (jsCode.isEmpty) {
      return {'name': p.basenameWithoutExtension(fileName), 'author': ''};
    }

    try {
      final String fullJs = """
        var src = "$fileName";
        var name = "";
        var author = "";
        $jsCode
        JSON.stringify({name: name, author: author});
      """;
      final result = _jsRuntime.evaluate(fullJs);
      final map = Map<String, dynamic>.from(jsonDecode(result.stringResult));
      return {
        'name': map['name']?.toString() ?? p.basenameWithoutExtension(fileName),
        'author': map['author']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('JS 檔名解析失敗: $e');
      return {'name': p.basenameWithoutExtension(fileName), 'author': ''};
    }
  }

  Future<bool> importFile(String path) async {
    _isImporting = true;
    notifyListeners();

    final file = File(path);
    final ext = p.extension(path).toLowerCase();
    
    final info = await _parseFileName(p.basename(path));

    try {
      if (ext == '.txt') {
        final parser = TxtParser(file);
        await parser.load();
        final chaptersData = await parser.splitChapters();
        await _importTxt(file, info['name']!, info['author']!, chaptersData);
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

  Future<void> _importTxt(File file, String name, String author, List<Map<String, String>> chaptersData) async {
    final book = Book(
      bookUrl: 'local://${file.path}',
      name: name,
      author: author,
      origin: 'local',
      originName: '本地',
      isInBookshelf: true,
    );

    await _bookDao.insertOrUpdate(book);

    final List<BookChapter> chapters = [];
    final List<Map<String, dynamic>> contents = [];
    
    // 深度還原：分批寫入資料庫，防止大量匯入導致的 UI 凍結或 OOM
    const int batchSize = 100;
    
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
      
      if (chapters.length >= batchSize) {
        await _chapterDao.insertChapters(List.from(chapters));
        await _chapterDao.insertContents(List.from(contents));
        chapters.clear();
        contents.clear();
      }
    }
    
    if (chapters.isNotEmpty) {
      await _chapterDao.insertChapters(chapters);
      await _chapterDao.insertContents(contents);
    }
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
    const int batchSize = 100;

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

      if (chapters.length >= batchSize) {
        await _chapterDao.insertChapters(List.from(chapters));
        await _chapterDao.insertContents(List.from(contents));
        chapters.clear();
        contents.clear();
      }
    }
    
    if (chapters.isNotEmpty) {
      await _chapterDao.insertChapters(chapters);
      await _chapterDao.insertContents(contents);
    }
  }
}
