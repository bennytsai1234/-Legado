import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/search_history_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final SearchHistoryDao _historyDao = SearchHistoryDao();
  final BookSourceService _service = BookSourceService();

  List<String> _history = [];
  List<AggregatedSearchBook> _results = [];
  bool _isSearching = false;
  bool _isCancelled = false;
  int _searchCount = 0;
  int _totalSources = 0;
  String _currentSource = "";

  void stopSearch() {
    _isCancelled = true;
    _isSearching = false;
    _currentSource = "已停止";
    notifyListeners();
  }

  // 搜尋範圍與熱搜詞
  List<String> _sourceGroups = ['全部'];
  String _selectedGroup = '全部';
  final List<String> _hotKeywords = ['劍來', '道詭異仙', '靈境行者', '深海餘燼', '赤心巡天', '大奉打更人']; // 模擬熱搜詞

  List<String> get history => _history;
  List<AggregatedSearchBook> get results => _results;
  bool get isSearching => _isSearching;
  String get currentSource => _currentSource;
  double get progress => _totalSources == 0 ? 0 : _searchCount / _totalSources;
  
  List<String> get sourceGroups => _sourceGroups;
  String get selectedGroup => _selectedGroup;
  List<String> get hotKeywords => _hotKeywords;

  SearchProvider() {
    loadHistory();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final sources = await _sourceDao.getAll();
    final Set<String> groups = {};
    for (var s in sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groups.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    _sourceGroups = ['全部', ...groups.toList()..sort()];
    notifyListeners();
  }

  void setGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
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
    _isCancelled = false;
    _results = [];
    _searchCount = 0;
    notifyListeners();

    // 保存歷史
    await _historyDao.add(keyword);
    await loadHistory();

    var enabledSources = await _sourceDao.getEnabled();
    
    // 套用搜尋範圍 (SearchScope) 過濾
    if (_selectedGroup != '全部') {
      enabledSources = enabledSources.where((s) {
        final g = s.bookSourceGroup ?? "";
        return g.split(',').map((e) => e.trim()).contains(_selectedGroup);
      }).toList();
    }

    _totalSources = enabledSources.length;
    if (_totalSources == 0) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    // 深度還原：使用全域 Pool 控制併發 (對應 Android threadCount)
    final threadCount = await SharedPreferences.getInstance().then((p) => p.getInt('thread_count') ?? 8);
    final searchPool = Pool(threadCount);

    // 並發搜尋
    final List<Future<void>> tasks = [];
    for (final source in enabledSources) {
      if (_isCancelled) break;
      tasks.add(searchPool.withResource(() async {
        if (_isCancelled) return;
        return _searchSingleSource(source, keyword);
      }));
    }

    await Future.wait(tasks);
    _isSearching = false;
    notifyListeners();
  }

  /// 在特定書源中搜尋 (對應 Android 站內搜尋)
  Future<void> searchInSource(BookSource source, String keyword) async {
    if (keyword.isEmpty) return;
    
    _isSearching = true;
    _isCancelled = false;
    _results = [];
    _searchCount = 0;
    _totalSources = 1;
    notifyListeners();

    try {
      await _searchSingleSource(source, keyword);
    } catch (e) {
      debugPrint('站內搜尋失敗: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> _searchSingleSource(BookSource source, String keyword) async {
    if (_isCancelled) return;
    _currentSource = source.bookSourceName;
    notifyListeners();
    try {
      // 深度對標：單個書源搜尋超時控制 (預設 30 秒)
      final List<SearchBook> books = await _service.searchBooks(
        source,
        keyword,
      ).timeout(const Duration(seconds: 30));
      
      if (_isCancelled) return;
      _aggregateResults(books);
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('搜尋書源 ${source.bookSourceName} 超時');
      } else {
        debugPrint('搜尋書源 ${source.bookSourceName} 失敗: $e');
      }
    } finally {
      _searchCount++;
      notifyListeners();
    }
  }

  void _aggregateResults(List<SearchBook> newBooks) {
    for (final newBook in newBooks) {
      // 聚合條件：書名 + 正規化後的作者 (對標 Android formatAuthor)
      final normalizedAuthor = newBook.getRealAuthor();
      final index = _results.indexWhere(
        (r) => r.book.name == newBook.name && r.book.getRealAuthor() == normalizedAuthor,
      );

      if (index != -1) {
        // 已存在，加入來源
        if (!_results[index].sources.contains(newBook.originName)) {
          _results[index].sources.add(newBook.originName ?? '未知來源');
        }
      } else {
        // 新書籍
        _results.add(
          AggregatedSearchBook(
            book: newBook,
            sources: [newBook.originName ?? '未知來源'],
          ),
        );
      }
    }
    
    // 深度還原：綜合排序 (來源數 + 書源權重)
    // 優先順序：來源數量越多越靠前，相同時參考原書源排序 (這裡簡化為來源數)
    _results.sort((a, b) {
      int cmp = b.sources.length.compareTo(a.sources.length);
      if (cmp != 0) return cmp;
      return a.book.name.length.compareTo(b.book.name.length); // 輔助排序
    });
  }
}
