import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/services/book_source_service.dart';
import '../../core/local_book/epub_parser.dart';
import '../../core/local_book/txt_parser.dart';

class BookshelfProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<Book> _books = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  BookshelfProvider() {
    loadBooks();
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();

    _books = await _bookDao.getBookshelf();

    _isLoading = false;
    notifyListeners();
  }

  /// 檢查更新
  Future<void> refreshBookshelf() async {
    if (_books.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    final sources = await _sourceDao.getAll();
    final List<Future<void>> tasks = [];

    for (final book in _books) {
      final source = sources.cast<BookSource?>().firstWhere(
        (s) => s?.bookSourceUrl == book.origin,
        orElse: () => null,
      );
      if (source != null) {
        tasks.add(_refreshSingleBook(source, book));
      }
    }

    await Future.wait(tasks);
    _books = await _bookDao.getBookshelf();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshSingleBook(BookSource source, Book book) async {
    try {
      final oldLastChapter = book.latestChapterTitle;
      final updatedBook = await _service.getBookInfo(source, book);

      if (updatedBook.latestChapterTitle != oldLastChapter) {
        // 有新章節
        updatedBook.lastCheckCount = (updatedBook.lastCheckCount) + 1;
        await _bookDao.insertOrUpdate(updatedBook);
      }
    } catch (e) {
      debugPrint('刷新書籍 ${book.name} 失敗: $e');
    }
  }

  Future<void> removeBook(Book book) async {
    await _bookDao.updateInBookshelf(book.bookUrl, false);
    await loadBooks();
  }

  /// 匯入本地書籍
  Future<void> importLocalBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub'],
      );

      if (result != null && result.files.single.path != null) {
        _isLoading = true;
        notifyListeners();

        final file = File(result.files.single.path!);
        final ext = result.files.single.extension?.toLowerCase() ?? '';

        final bookUrl = "local://\${file.path}";

        // 檢查是否已匯入
        final existingBook = await _bookDao.getByUrl(bookUrl);
        if (existingBook != null && existingBook.isInBookshelf) {
          _isLoading = false;
          notifyListeners();
          return;
        }

        late Book book;
        final List<BookChapter> bookChapters = [];
        final ChapterDao chapterDao = ChapterDao();

        if (ext == 'epub') {
          final parser = EpubParser(file);
          await parser.load();

          book = Book(
            bookUrl: bookUrl,
            name: parser.title,
            author: parser.author,
            origin: "local",
            originName: "本地書籍",
            isInBookshelf: true,
            coverUrl: file.path, // 特殊標記以利後續讀取封面
          );

          final chapters = parser.getChapters();
          for (int i = 0; i < chapters.length; i++) {
            bookChapters.add(
              BookChapter(
                url: chapters[i]['href'] ?? "",
                title: chapters[i]['title'] ?? "Unnamed Chapter",
                bookUrl: bookUrl,
                index: i,
              ),
            );
            final content = parser.getChapterContent(chapters[i]['href'] ?? "");
            await chapterDao.saveContent(bookUrl, i, content);
          }
          book.totalChapterNum = chapters.length;
        } else if (ext == 'txt') {
          final parser = TxtParser(file);
          await parser.load();

          book = Book(
            bookUrl: bookUrl,
            name: file.uri.pathSegments.last
                .replaceAll('.txt', '')
                .replaceAll('.TXT', ''),
            author: "Unknown Author",
            origin: "local",
            originName: "本地書籍",
            isInBookshelf: true,
          );

          final chapters = parser.splitChapters();
          for (int i = 0; i < chapters.length; i++) {
            bookChapters.add(
              BookChapter(
                url: "local_index_\$i",
                title: chapters[i]['title'] ?? "Unnamed Chapter",
                bookUrl: bookUrl,
                index: i,
              ),
            );
            await chapterDao.saveContent(
              bookUrl,
              i,
              chapters[i]['content'] ?? "",
            );
          }
          book.totalChapterNum = chapters.length;
        } else {
          _isLoading = false;
          notifyListeners();
          return;
        }

        await _bookDao.insertOrUpdate(book);
        await chapterDao.insertChapters(bookChapters);

        await loadBooks();
      }
    } catch (e) {
      debugPrint("Import Error: \$e");
      _isLoading = false;
      notifyListeners();
    }
  }

  // TODO: 分組管理
}
