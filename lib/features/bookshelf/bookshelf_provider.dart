import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/book_source.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/services/book_source_service.dart';

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
        orElse: () => null
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

  // TODO: 分組管理
}
