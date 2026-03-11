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
      _currentSource = sources.cast<BookSource?>().firstWhere(
            (s) => s?.bookSourceUrl == _book.origin,
            orElse: () => null,
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

  /// 更新書籍封面
  Future<void> updateCover(String newCoverUrl) async {
    _book.coverUrl = newCoverUrl;
    if (_isInBookshelf) {
      await _bookDao.insertOrUpdate(_book);
    }
    notifyListeners();
  }

  // --- 來源切換邏輯 ---

  /// 搜尋所有可用書源中的同名書籍
  Future<List<SearchBook>> searchAlternativeSources() async {
    final sources = await _sourceDao.getEnabled();
    return await _service.preciseSearch(sources, _book.name, _book.author ?? "");
  }

  /// 切換到選定的書源
  Future<void> switchSource(SearchBook newSource) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sources = await _sourceDao.getAll();
      final source = sources.cast<BookSource?>().firstWhere(
            (s) => s?.bookSourceUrl == newSource.origin,
            orElse: () => null,
          );
      
      if (source == null) return;

      // 如果在書架中，需要更新資料庫
      if (_isInBookshelf) {
        final oldUrl = _book.bookUrl;
        _book.bookUrl = newSource.bookUrl;
        _book.origin = newSource.origin;
        _book.originName = newSource.originName;
        
        await _bookDao.delete(oldUrl); // 刪除舊紀錄
        await _bookDao.insertOrUpdate(_book); // 插入新紀錄
      } else {
        _book.bookUrl = newSource.bookUrl;
        _book.origin = newSource.origin;
        _book.originName = newSource.originName;
      }

      _currentSource = source;
      // 重新加載詳情與目錄
      _book = await _service.getBookInfo(source, _book);
      _chapters = await _service.getChapterList(source, _book);
      
      if (_isInBookshelf) {
        await _chapterDao.insertChapters(_chapters);
      }
    } catch (e) {
      debugPrint('切換書源失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
