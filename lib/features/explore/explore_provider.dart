import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';

class ExploreProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<BookSource> _allSources = [];
  List<BookSource> _filteredSources = [];
  List<String> _groups = [];
  String _currentGroup = '全部';

  BookSource? _selectedSource;
  List<Map<String, String>> _exploreConfigs = [];
  Map<String, String>? _selectedConfig;
  
  List<SearchBook> _books = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;

  List<BookSource> get sources => _filteredSources;
  List<String> get groups => _groups;
  String get currentGroup => _currentGroup;
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
    _allSources = await _sourceDao.getEnabled();
    _groups = _allSources.map((s) => s.bookSourceGroup ?? '未分組').toSet().toList();
    _groups.removeWhere((g) => g.isEmpty);
    _groups.sort();
    
    _applyGroupFilter();
    
    if (_filteredSources.isNotEmpty) {
      setSource(_filteredSources.first);
    }
    notifyListeners();
  }

  void setGroup(String group) {
    _currentGroup = group;
    _applyGroupFilter();
    if (_filteredSources.isNotEmpty) {
      setSource(_filteredSources.first);
    } else {
      _selectedSource = null;
      _exploreConfigs = [];
      _selectedConfig = null;
      _books = [];
    }
    notifyListeners();
  }

  void _applyGroupFilter() {
    if (_currentGroup == '全部') {
      _filteredSources = _allSources;
    } else {
      _filteredSources = _allSources.where((s) => (s.bookSourceGroup ?? '未分組').contains(_currentGroup)).toList();
    }
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

  Future<void> refresh() async {
    if (_selectedSource == null || _selectedConfig == null) return;
    _page = 1;
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    try {
      _books = await _service.exploreBooks(
        _selectedSource!,
        _selectedConfig!['url']!,
        _page,
      );
    } catch (e) {
      debugPrint('發現失敗: $e');
      _books = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _selectedSource == null || _selectedConfig == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _page++;
      final moreBooks = await _service.exploreBooks(
        _selectedSource!,
        _selectedConfig!['url']!,
        _page,
      );
      if (moreBooks.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(moreBooks);
      }
    } catch (e) {
      debugPrint('載入更多發現失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, String>> _parseExploreUrl(BookSource source) {
    final String? exploreUrl = source.exploreUrl;
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    final List<Map<String, String>> configs = [];
    final lines = exploreUrl.split(RegExp(r'[\n\r]+'));
    for (var line in lines) {
      final parts = line.split('::');
      if (parts.length >= 2) {
        configs.add({
          'title': parts[0].trim(),
          'url': parts[1].trim(),
        });
      }
    }
    return configs;
  }
}
