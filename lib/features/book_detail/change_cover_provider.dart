import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/search_book_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/models/book.dart';
import '../../core/services/book_source_service.dart';
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeCoverProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = BookSourceDao();
  final SearchBookDao _searchBookDao = SearchBookDao();
  final BookSourceService _service = BookSourceService();

  List<SearchBook> _covers = [];
  bool _isSearching = false;
  int _searchCount = 0;
  int _totalSources = 0;

  List<SearchBook> get covers => _covers;
  bool get isSearching => _isSearching;
  double get progress => _totalSources == 0 ? 0 : _searchCount / _totalSources;

  // 預設封面虛擬項 (對標 Android defaultCover)
  SearchBook _buildDefaultCoverItem(String name, String author) {
    return SearchBook(
      book: Book(
        name: name,
        author: author,
        bookUrl: 'use_default_cover',
        origin: 'system',
        originName: '恢復預設封面',
      ),
      sources: ['系統'],
    );
  }

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

  /// 深度還原：快取優先加載邏輯
  Future<void> init(String name, String author) async {
    _covers = [_buildDefaultCoverItem(name, author)];
    notifyListeners();

    // 1. 先從資料庫加載既有封面
    final cached = await _searchBookDao.getEnabledHasCover(name, author);
    if (cached.isNotEmpty) {
      for (var b in cached) {
        if (!_covers.any((c) => c.book.coverUrl == b.book.coverUrl)) {
          _covers.add(b);
        }
      }
      notifyListeners();
    }

    // 2. 若快取為空，自動發起搜尋
    if (cached.isEmpty) {
      search(name, author);
    }
  }

  Future<void> search(String name, String author) async {
    _isSearching = false; // 先停止現有任務
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));

    _isSearching = true;
    _covers = [_buildDefaultCoverItem(name, author)];
    _searchCount = 0;
    notifyListeners();

    // 重新載入快取（防止重複）
    final cached = await _searchBookDao.getEnabledHasCover(name, author);
    for (var b in cached) {
      if (!_covers.any((c) => c.book.coverUrl == b.book.coverUrl)) {
        _covers.add(b);
      }
    }

    final enabledSources = await _sourceDao.getEnabled();
    final coverSources = enabledSources.where((s) => s.ruleSearch?.coverUrl != null && s.ruleSearch!.coverUrl!.isNotEmpty).toList();

    _totalSources = coverSources.length;
    if (_totalSources == 0) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    // 深度還原：使用全域 Pool 控制併發 (對應 Android threadCount)
    final threadCount = await SharedPreferences.getInstance().then((p) => p.getInt('thread_count') ?? 8);
    final coverPool = Pool(threadCount);

    final List<Future<void>> tasks = [];
    for (final source in coverSources) {
      if (!_isSearching) break;
      tasks.add(coverPool.withResource(() => _searchSingleSource(source, name, author)));
    }

    await Future.wait(tasks);
    _isSearching = false;
    notifyListeners();
  }

  Future<void> _searchSingleSource(BookSource source, String name, String author) async {
    if (!_isSearching) return;
    try {
      final List<SearchBook> books = await _service.searchBooks(
        source,
        name,
        filter: (fName, fAuthor) {
          return fName == name && (author.isEmpty || fAuthor.contains(author) || author.contains(fAuthor));
        },
      );

      for (var result in books) {
        if (result.book.coverUrl != null && result.book.coverUrl!.isNotEmpty) {
          if (!_covers.any((c) => c.book.coverUrl == result.book.coverUrl)) {
            _covers.add(result);
            // 深度還原：搜尋成功後存入快取資料庫
            await _searchBookDao.insert(result);
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
