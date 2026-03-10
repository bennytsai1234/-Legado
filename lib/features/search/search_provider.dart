import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/search_history_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';

class AggregatedSearchBook {
  final SearchBook book;
  final List<String> sources; // 來源名稱列表

  AggregatedSearchBook({required this.book, required this.sources});
}

class SearchProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final SearchHistoryDao _historyDao = SearchHistoryDao();
  final BookSourceService _service = BookSourceService();

  List<String> _history = [];
  List<AggregatedSearchBook> _results = [];
  bool _isSearching = false;
  int _searchCount = 0;
  int _totalSources = 0;

  List<String> get history => _history;
  List<AggregatedSearchBook> get results => _results;
  bool get isSearching => _isSearching;
  double get progress => _totalSources == 0 ? 0 : _searchCount / _totalSources;

  SearchProvider() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    _history = await _historyDao.getRecent();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyDao.clearAll();
    _history = [];
    notifyListeners();
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    _isSearching = true;
    _results = [];
    _searchCount = 0;
    notifyListeners();

    // 保存歷史
    await _historyDao.add(keyword);
    await loadHistory();

    final enabledSources = await _sourceDao.getEnabled();
    _totalSources = enabledSources.length;
    if (_totalSources == 0) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    // 並發搜尋
    final List<Future<void>> tasks = [];
    for (final source in enabledSources) {
      tasks.add(_searchSingleSource(source, keyword));
    }

    await Future.wait(tasks);
    _isSearching = false;
    notifyListeners();
  }

  Future<void> _searchSingleSource(BookSource source, String keyword) async {
    try {
      final List<SearchBook> books = await _service.searchBooks(source, keyword);
      _aggregateResults(books);
    } catch (e) {
      debugPrint('搜尋書源 ${source.bookSourceName} 失敗: $e');
    } finally {
      _searchCount++;
      notifyListeners();
    }
  }

  void _aggregateResults(List<SearchBook> newBooks) {
    for (final newBook in newBooks) {
      // 聚合條件：書名 + 作者
      final index = _results.indexWhere((r) => 
        r.book.name == newBook.name && r.book.author == newBook.author
      );

      if (index != -1) {
        // 已存在，加入來源
        if (!_results[index].sources.contains(newBook.originName)) {
          _results[index].sources.add(newBook.originName ?? '未知來源');
        }
      } else {
        // 新書籍
        _results.add(AggregatedSearchBook(
          book: newBook,
          sources: [newBook.originName ?? '未知來源'],
        ));
      }
    }
    // 依來源數量或自定義規則排序（可選）
    _results.sort((a, b) => b.sources.length.compareTo(a.sources.length));
  }
}
