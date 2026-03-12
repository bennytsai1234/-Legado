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
  List<String> _groups = ['全部'];
  String _selectedGroup = '全部';
  BookSource? _selectedSource;
  Map<String, String>? _selectedConfig;
  List<SearchBook> _books = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;

  List<BookSource> get sources => _filteredSources;
  List<String> get groups => _groups;
  String get selectedGroup => _selectedGroup;
  BookSource? get selectedSource => _selectedSource;
  List<Map<String, String>> get exploreConfigs => _selectedSource != null ? _parseExploreUrl(_selectedSource!) : [];
  Map<String, String>? get selectedConfig => _selectedConfig;
  List<SearchBook> get books => _books;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  ExploreProvider() {
    _init();
  }

  Future<void> _init() async {
    _allSources = await _sourceDao.getEnabled();
    // 過濾掉沒有發現規則的書源
    _allSources = _allSources.where((s) => s.exploreUrl != null && s.exploreUrl!.isNotEmpty).toList();
    
    final groupSet = {'全部'};
    for (var s in _allSources) {
      if (s.bookSourceGroup != null) {
        groupSet.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    _groups = groupSet.toList()..sort();
    _applyGroupFilter();
  }

  void setGroup(String group) {
    _selectedGroup = group;
    _applyGroupFilter();
    notifyListeners();
  }

  void _applyGroupFilter() {
    if (_selectedGroup == '全部') {
      _filteredSources = _allSources;
    } else {
      _filteredSources = _allSources.where((s) {
        final g = s.bookSourceGroup ?? "";
        return g.split(',').map((e) => e.trim()).contains(_selectedGroup);
      }).toList();
    }
  }

  void setSource(BookSource? source) {
    _selectedSource = source;
    _selectedConfig = null;
    _books = [];
    _page = 1;
    _hasMore = true;
    notifyListeners();
  }

  void setConfig(Map<String, String> config) {
    _selectedConfig = config;
    _books = [];
    _page = 1;
    _hasMore = true;
    notifyListeners();
    loadMore();
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    _books = [];
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _selectedSource == null || _selectedConfig == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final moreBooks = await _service.exploreBooks(
        _selectedSource!,
        _selectedConfig!['url']!,
        page: _page,
      );
      if (moreBooks.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(moreBooks);
        _page++;
      }
    } catch (e) {
      debugPrint('載入更多發現失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> topSource(BookSource source) async {
    final minOrder = await _sourceDao.getMinOrder();
    source.customOrder = minOrder - 1;
    await _sourceDao.update(source);
    await _init();
  }

  Future<void> deleteSource(BookSource source) async {
    await _sourceDao.delete(source.bookSourceUrl);
    if (_selectedSource?.bookSourceUrl == source.bookSourceUrl) {
      _selectedSource = null;
    }
    await _init();
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
