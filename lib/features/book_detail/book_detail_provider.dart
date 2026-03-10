import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/search_book.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';

class BookDetailProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  late Book _book;
  BookSource? _currentSource;
  List<BookChapter> _chapters = [];
  bool _isLoading = false;
  bool _isInBookshelf = false;

  Book get book => _book;
  List<BookChapter> get chapters => _chapters;
  bool get isLoading => _isLoading;
  bool get isInBookshelf => _isInBookshelf;
  BookSource? get currentSource => _currentSource;

  BookDetailProvider(SearchBook searchBook) {
    _book = Book(
      bookUrl: searchBook.bookUrl,
      name: searchBook.name,
      author: searchBook.author,
      coverUrl: searchBook.coverUrl,
      intro: searchBook.intro,
      origin: searchBook.origin,
      originName: searchBook.originName,
    );
    _checkBookshelf();
    _loadInitialData();
  }

  Future<void> _checkBookshelf() async {
    final existing = await _bookDao.getByUrl(_book.bookUrl);
    _isInBookshelf = existing?.isInBookshelf ?? false;
    if (existing != null) {
      _book = existing;
    }
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sources = await _sourceDao.getAll();
      _currentSource = sources.firstWhere(
        (s) => s.bookSourceUrl == _book.origin,
      );

      if (_currentSource != null) {
        // 獲取最新詳情
        _book = await _service.getBookInfo(_currentSource!, _book);
        // 獲取目錄
        _chapters = await _service.getChapterList(_currentSource!, _book);
      }
    } catch (e) {
      debugPrint('加載書籍詳情失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleBookshelf() async {
    _isInBookshelf = !_isInBookshelf;
    _book.isInBookshelf = _isInBookshelf;

    if (_isInBookshelf) {
      await _bookDao.insertOrUpdate(_book);
      if (_chapters.isNotEmpty) {
        await _chapterDao.insertChapters(_chapters);
      }
    } else {
      await _bookDao.updateInBookshelf(_book.bookUrl, false);
    }

    notifyListeners();
  }

  // TODO: 來源切換邏輯
}
