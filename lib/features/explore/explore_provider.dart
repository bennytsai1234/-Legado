import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';

class ExploreItem {
  final String title;
  final String url;
  final BookSource source;

  ExploreItem({required this.title, required this.url, required this.source});
}

class ExploreProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<BookSource> _sources = [];
  Map<String, List<ExploreItem>> _exploreMap = {};
  bool _isLoading = false;

  List<BookSource> get sources => _sources;
  Map<String, List<ExploreItem>> get exploreMap => _exploreMap;
  bool get isLoading => _isLoading;

  ExploreProvider() {
    loadExploreData();
  }

  Future<void> loadExploreData() async {
    _isLoading = true;
    notifyListeners();

    _sources = await _sourceDao.getEnabled();
    _exploreMap = {};

    debugPrint("Explore: Found \${_sources.length} enabled sources.");

    for (final source in _sources) {
      if (source.enabledExplore &&
          source.exploreUrl != null &&
          source.exploreUrl!.isNotEmpty) {
        final items = _parseExploreUrl(source);
        debugPrint("Explore: Source '\${source.bookSourceName}' parsed \${items.length} items.");
        if (items.isNotEmpty) {
          _exploreMap[source.bookSourceName] = items;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<ExploreItem> _parseExploreUrl(BookSource source) {
    final List<ExploreItem> results = [];
    final lines = source.exploreUrl!.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final parts = line.split('::');
      if (parts.length >= 2) {
        results.add(
          ExploreItem(
            title: parts[0].trim(),
            url: parts[1].trim(),
            source: source,
          ),
        );
      } else {
        // Fallback for single URL
        results.add(ExploreItem(title: '預設分類', url: line, source: source));
      }
    }
    return results;
  }

  // 分頁載入結果
  Future<List<SearchBook>> loadCategoryBooks(ExploreItem item, int page) async {
    try {
      return await _service.exploreBooks(item.source, item.url, page: page);
    } catch (e) {
      debugPrint('載入發現頁書籍失敗: $e');
      return [];
    }
  }
}
