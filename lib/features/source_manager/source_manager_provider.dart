import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/services/check_source_service.dart';

class SourceManagerProvider extends ChangeNotifier {
  final BookSourceDao _dao = BookSourceDao();
  final BookDao _bookDao = BookDao();
  final CheckSourceService _checkService = CheckSourceService();
  
  List<BookSource> _sources = [];
  List<String> _groups = [];
  String _selectedGroup = '全部';
  bool _isLoading = false;

  bool _isBatchMode = false;
  Set<String> _selectedUrls = {};

  List<BookSource> get sources {
    if (_selectedGroup == '全部') return _sources;
    return _sources
        .where((s) => s.bookSourceGroup?.contains(_selectedGroup) ?? false)
        .toList();
  }

  List<String> get groups => ['全部', ..._groups];
  String get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedUrls => _selectedUrls;
  
  CheckSourceService get checkService => _checkService;

  SourceManagerProvider() {
    loadSources();
    // 監聽校驗服務的變化以更新 UI
    _checkService.addListener(() {
      if (!_checkService.isChecking) {
        loadSources(); // 校驗完成後重新載入
      }
      notifyListeners();
    });
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();

    _sources = await _dao.getAllPart();
    _groups = await _dao.getGroups();

    _isLoading = false;
    notifyListeners();
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    if (_isBatchMode) {
      _selectedUrls.clear();
    }
    notifyListeners();
  }

  Future<void> toggleEnabled(BookSource source) async {
    final newState = !source.enabled;
    source.enabled = newState;
    await _dao.insertOrUpdate(source);
    notifyListeners();
  }

  Future<void> deleteSource(BookSource source) async {
    await _dao.deleteSources([source.bookSourceUrl]);
    await loadSources();
  }

  // --- 批量管理功能 ---
  void toggleBatchMode() {
    _isBatchMode = !_isBatchMode;
    if (!_isBatchMode) _selectedUrls.clear();
    notifyListeners();
  }
  
  void toggleSelect(String url) {
    if (_selectedUrls.contains(url)) {
      _selectedUrls.remove(url);
    } else {
      _selectedUrls.add(url);
    }
    notifyListeners();
  }
  
  void selectAll() {
    final currentVisibleSources = sources;
    if (_selectedUrls.length == currentVisibleSources.length) {
      _selectedUrls.clear();
    } else {
      _selectedUrls = currentVisibleSources.map((s) => s.bookSourceUrl).toSet();
    }
    notifyListeners();
  }
  
  Future<void> deleteSelected() async {
    await _dao.deleteSources(_selectedUrls.toList());
    _selectedUrls.clear();
    _isBatchMode = false;
    await loadSources();
  }

  Future<void> exportSelected() async {
    if (_selectedUrls.isEmpty) return;
    
    // 需要獲取完整書源數據進行匯出
    final List<BookSource> exportList = [];
    for (var url in _selectedUrls) {
      final s = await _dao.getByUrl(url);
      if (s != null) exportList.add(s);
    }
    
    final jsonStr = jsonEncode(exportList.map((s) => s.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    
    _isBatchMode = false;
    _selectedUrls.clear();
    notifyListeners();
  }

  // --- 校驗功能 ---
  Future<void> checkSelectedSources() async {
    if (_selectedUrls.isEmpty) return;
    final urls = _selectedUrls.toList();
    _isBatchMode = false;
    _selectedUrls.clear();
    await _checkService.check(urls);
  }

  // --- 書源遷移 (高度還原 Android migrateSource) ---
  Future<void> migrateSource(String oldUrl, String newUrl) async {
    final books = await _bookDao.getAll();
    final toUpdate = books.where((b) => b.origin == oldUrl).toList();
    
    for (var book in toUpdate) {
      book.origin = newUrl;
      await _bookDao.insertOrUpdate(book);
    }
    notifyListeners();
  }

  // --- 分組清理 ---
  Future<void> cleanupGroups() async {
    // 重新載入分組數據即可更新清單
    await loadSources();
  }

  /// 從文本匯入
  Future<int> importFromText(String text) async {
    try {
      final dynamic decoded = jsonDecode(text);
      List<BookSource> newSources = [];

      if (decoded is List) {
        newSources = decoded.map((item) => BookSource.fromJson(item as Map<String, dynamic>)).toList();
      } else if (decoded is Map) {
        newSources = [BookSource.fromJson(decoded as Map<String, dynamic>)];
      }

      if (newSources.isNotEmpty) {
        for (var element in newSources) {
          element.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
        }
        await _dao.insertOrUpdateAll(newSources);
        await loadSources();
        return newSources.length;
      }
    } catch (e) {
      debugPrint('匯入書源失敗: $e');
    }
    return 0;
  }

  /// 從 URL 匯入
  Future<int> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      List<dynamic> list = data is List ? data : [data];
      int count = 0;
      for (var item in list) {
        final source = BookSource.fromJson(item);
        await _dao.insertOrUpdate(source);
        count++;
      }
      await loadSources();
      return count;
    } catch (e) {
      debugPrint('從 JSON 匯入書源失敗: $e');
      return 0;
    }
  }

  Future<int> importFromUrl(String url) async {
    final urls = url.split(RegExp(r'[\n\r]+')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    int totalCount = 0;
    final dio = Dio();
    
    for (final u in urls) {
      try {
        final response = await dio.get(u);
        if (response.data != null) {
          final String jsonStr = response.data is String ? response.data : jsonEncode(response.data);
          totalCount += await importFromJson(jsonStr);
        }
      } catch (e) {
        debugPrint('從 URL 匯入書源失敗 ($u): $e');
      }
    }
    return totalCount;
  }
}
