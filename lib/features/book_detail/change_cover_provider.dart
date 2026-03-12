import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';

class ChangeCoverProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<SearchBook> _covers = [];
  bool _isSearching = false;
  int _searchCount = 0;
  int _totalSources = 0;

  List<SearchBook> get covers => _covers;
  bool get isSearching => _isSearching;
  double get progress => _totalSources == 0 ? 0 : _searchCount / _totalSources;

  void stopSearch() {
    _isSearching = false;
    notifyListeners();
  }

  void clear() {
    _covers = [];
    _isSearching = false;
    _searchCount = 0;
    _totalSources = 0;
    notifyListeners();
  }

  Future<void> search(String name, String author) async {
    _isSearching = false; // 先停止
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));

    _isSearching = true;
    _covers = [];
    _searchCount = 0;
    notifyListeners();

    final enabledSources = await _sourceDao.getEnabled();
    // 過濾掉沒有封面搜尋規則的書源 (比照 Legado ChangeCoverViewModel)
    final coverSources = enabledSources.where((s) => s.ruleSearch?.coverUrl != null && s.ruleSearch!.coverUrl!.isNotEmpty).toList();

    _totalSources = coverSources.length;
    if (_totalSources == 0) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    // 並發搜尋
    final List<Future<void>> tasks = [];
    for (final source in coverSources) {
      if (!_isSearching) break; // 深度補齊：循環中斷檢查
      tasks.add(_searchSingleSource(source, name, author));
    }

    await Future.wait(tasks);
    _isSearching = false;
    notifyListeners();
  }

  Future<void> _searchSingleSource(BookSource source, String name, String author) async {
    if (!_isSearching) return; // 深度補齊：開始請求前檢查
    try {
      final List<SearchBook> books = await _service.searchBooks(
        source,
        name,
        filter: (fName, fAuthor) {
          // 精確匹配書名與作者 (作者可模糊匹配或留空)
          return fName == name && (author.isEmpty || fAuthor.contains(author) || author.contains(fAuthor));
        },
      );

      for (var book in books) {
        if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
          // 避免重複封面 URL
          if (!_covers.any((c) => c.coverUrl == book.coverUrl)) {
            _covers.add(book);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('搜尋封面書源 ${source.bookSourceName} 失敗: $e');
    } finally {
      _searchCount++;
      notifyListeners();
    }
  }
}
