import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'bookshelf_provider_base.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/local_book/txt_parser.dart';
import 'package:legado_reader/core/local_book/epub_parser.dart';

/// BookshelfProvider 的本地書籍匯入邏輯擴展
mixin BookshelfImportMixin on BookshelfProviderBase {
  Future<void> importLocalBookPath(String path) async {
    final file = File(path);
    final ext = path.split('.').last.toLowerCase();
    final bookUrl = "local://${file.path}";

    final existingBook = await bookDao.getByUrl(bookUrl);
    if (existingBook != null && existingBook.isInBookshelf) return;

    isLoading = true; notifyListeners();

    try {
      if (ext == 'txt') {
        final parser = TxtParser(file); await parser.load();
        final chaptersData = await parser.splitChapters();
        final book = Book(bookUrl: bookUrl, name: p.basenameWithoutExtension(path), author: '本地', origin: 'local', originName: '本地', isInBookshelf: true, type: 0);
        await bookDao.insertOrUpdate(book);
        
        const int batchSize = 10;
        final List<BookChapter> bookChapters = [];
        final List<Map<String, dynamic>> bookContents = [];
        
        for (int i = 0; i < chaptersData.length; i++) {
          bookChapters.add(BookChapter(url: "$bookUrl#$i", title: chaptersData[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
          bookContents.add({'bookUrl': bookUrl, 'chapterIndex': i, 'content': chaptersData[i]['content'] ?? ""});
          if (bookChapters.length >= batchSize) {
            await chapterDao.insertChapters(List.from(bookChapters));
            await chapterDao.insertContents(List.from(bookContents));
            bookChapters.clear(); bookContents.clear();
            await Future.delayed(Duration.zero);
          }
        }
        if (bookChapters.isNotEmpty) {
          await chapterDao.insertChapters(bookChapters); await chapterDao.insertContents(bookContents);
        }
      } else if (ext == 'epub') {
        final parser = EpubParser(file); await parser.load();
        final book = Book(bookUrl: bookUrl, name: parser.title, author: parser.author, origin: "local", originName: "本地", isInBookshelf: true, type: 1);
        await bookDao.insertOrUpdate(book);
        final chapters = parser.getChapters();
        final List<BookChapter> bookChapters = [];
        for (int i = 0; i < chapters.length; i++) {
          bookChapters.add(BookChapter(url: chapters[i]['href'] ?? "", title: chapters[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
        }
        await chapterDao.insertChapters(bookChapters);
      }
      (this as dynamic).loadBooks();
    } catch (e) { debugPrint('匯入本地書籍失敗: $e'); } 
    finally { isLoading = false; notifyListeners(); }
  }
}
