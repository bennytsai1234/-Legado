import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';

class SourceManagerProvider extends ChangeNotifier {
  final BookSourceDao _dao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  
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

  SourceManagerProvider() {
    loadSources();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();

    _sources = await _dao.getAll();
    _groups = await _dao.getGroups();

    _isLoading = false;
    notifyListeners();
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    // 重置選取狀態
    if (_isBatchMode) {
      _selectedUrls.clear();
    }
    notifyListeners();
  }

  Future<void> toggleEnabled(BookSource source) async {
    final newState = !source.enabled;
    await _dao.updateEnabled(source.bookSourceUrl, newState);
    source.enabled = newState;
    notifyListeners();
  }

  Future<void> deleteSource(BookSource source) async {
    await _dao.delete(source.bookSourceUrl);
    _sources.removeWhere((s) => s.bookSourceUrl == source.bookSourceUrl);
    notifyListeners();
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
    for (final url in _selectedUrls) {
      await _dao.delete(url);
    }
    _selectedUrls.clear();
    _isBatchMode = false;
    await loadSources();
  }

  Future<void> exportSelected() async {
    if (_selectedUrls.isEmpty) return;
    
    final exportSources = _sources.where((s) => _selectedUrls.contains(s.bookSourceUrl)).toList();
    final jsonStr = jsonEncode(exportSources.map((s) => s.toJson()).toList());
    
    await Clipboard.setData(ClipboardData(text: jsonStr));
    
    _isBatchMode = false;
    _selectedUrls.clear();
    notifyListeners();
  }
  
  Future<void> validateSelected() async {
    if (_selectedUrls.isEmpty) return;

    final urlsToValidate = _selectedUrls.toList();
    _isBatchMode = false;
    _selectedUrls.clear();
    _isLoading = true;
    notifyListeners();

    final futures = <Future>[];
    for (final url in urlsToValidate) {
      final s = _sources.firstWhere((element) => element.bookSourceUrl == url);
      futures.add(_validateSource(s));
    }
    
    await Future.wait(futures);
    await loadSources();
  }

  Future<void> _validateSource(BookSource s) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    try {
      final res = await _service.searchBooks(s, "系統", page: 1, filter: null);
      if (res.isNotEmpty) {
        final cost = DateTime.now().millisecondsSinceEpoch - startTime;
        s.respondTime = cost;
      } else {
        s.respondTime = -1; // 查無資料也視為失效較為嚴格，或可算失敗
      }
    } catch (e) {
      s.respondTime = -1;
    }
    s.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    await _dao.insertOrUpdate(s);
  }

  /// 從文本匯入 (JSON 格式)
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
        // 設定更新時間
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
  Future<int> importFromUrl(String urlText) async {
    final urls = urlText.split(RegExp(r'[\n\r]+')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    int totalCount = 0;
    
    for (final url in urls) {
      try {
        final response = await Dio().get(url);
        if (response.data != null) {
          String content;
          if (response.data is String) {
            content = response.data;
          } else {
            content = jsonEncode(response.data);
          }
          totalCount += await importFromText(content);
        }
      } catch (e) {
        debugPrint('從 URL 匯入失敗 ($url): $e');
      }
    }
    return totalCount;
  }
}
