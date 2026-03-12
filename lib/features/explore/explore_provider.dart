import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';

class ExploreProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<BookSource> _sources = [];
  BookSource? _selectedSource;
  List<Map<String, String>> _exploreConfigs = [];
  Map<String, String>? _selectedConfig;
  
  List<SearchBook> _books = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;

  List<BookSource> get sources => _sources;
  BookSource? get selectedSource => _selectedSource;
  List<Map<String, String>> get exploreConfigs => _exploreConfigs;
  Map<String, String>? get selectedConfig => _selectedConfig;
  List<SearchBook> get books => _books;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  ExploreProvider() {
    _init();
  }

  Future<void> _init() async {
    _sources = await _sourceDao.getEnabled();
    if (_sources.isNotEmpty) {
      setSource(_sources.first);
    }
    notifyListeners();
  }

  void setSource(BookSource source) {
    _selectedSource = source;
    _exploreConfigs = _parseExploreUrl(source);
    if (_exploreConfigs.isNotEmpty) {
      setConfig(_exploreConfigs.first);
    } else {
      _books = [];
      notifyListeners();
    }
  }

  void setConfig(Map<String, String> config) {
    _selectedConfig = config;
    refresh();
  }

  List<Map<String, String>> _parseExploreUrl(BookSource source) {
    final List<Map<String, String>> results = [];
    final url = source.exploreUrl;
    if (url == null || url.isEmpty) return [];
    
    for (var line in url.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      final parts = line.split('::');
      if (parts.length >= 2) {
        results.add({'title': parts[0].trim(), 'url': parts[1].trim()});
      }
    }
    return results;
  }

  Future<void> refresh() async {
    if (_selectedSource == null || _selectedConfig == null) return;
    _isLoading = true;
    _page = 1;
    _hasMore = true;
    _books = [];
    notifyListeners();
    await _loadData();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    _page++;
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final newBooks = await _service.exploreBooks(_selectedSource!, _selectedConfig!['url']!, page: _page);
      if (newBooks.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(newBooks);
      }
    } catch (e) {
      debugPrint('Explore Error: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
