import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';
import '../../core/services/check_source_service.dart';

class SourceManagerProvider extends ChangeNotifier {
  final BookSourceDao _dao = BookSourceDao();
  final CheckSourceService _checkService = CheckSourceService();
  
  List<BookSource> _sources = [];
  List<String> _groups = [];
  String _selectedGroup = '全部';
  bool _isLoading = false;

  bool _isBatchMode = false;
  Set<String> _selectedUrls = {};

  // 校驗結果
  final Map<String, CheckSourceResult> _checkResults = {};
  bool _isChecking = false;

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
  Map<String, CheckSourceResult> get checkResults => _checkResults;
  bool get isChecking => _isChecking;

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
  
  // --- 校驗功能 ---

  Future<void> checkVisibleSources() async {
    if (_isChecking) return;
    _isChecking = true;
    _checkResults.clear();
    notifyListeners();

    final currentVisible = sources;
    final List<Future<void>> tasks = [];
    for (final source in currentVisible) {
      tasks.add(_checkSingleSource(source));
    }

    await Future.wait(tasks);
    _isChecking = false;
    notifyListeners();
  }

  Future<void> _checkSingleSource(BookSource source) async {
    final result = await _checkService.checkSource(source);
    _checkResults[source.bookSourceUrl] = result;
    
    // 更新書源的回應時間
    if (result.result == CheckResult.success) {
      source.respondTime = result.milliseconds;
    } else {
      source.respondTime = -1;
    }
    await _dao.insertOrUpdate(source);
    notifyListeners();
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
    } catch (e, stack) {
      debugPrint('匯入書源失敗: $e\n$stack');
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
