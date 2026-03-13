import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int _sortMode = 0; // 0:手動, 1:權重, 2:響應速度, 3:更新時間, 4:名稱
  bool _groupByDomain = false;
  bool _isLoading = false;

  bool _isBatchMode = false;
  Set<String> _selectedUrls = {};

  List<BookSource> get sources {
    List<BookSource> list = List.from(_sources);
    if (_selectedGroup != '全部') {
      list = list.where((s) => s.bookSourceGroup?.contains(_selectedGroup) ?? false).toList();
    }
    return list;
  }

  List<String> get groups => ['全部', ..._groups];
  String get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedUrls => _selectedUrls;
  int get sortMode => _sortMode;
  bool get groupByDomain => _groupByDomain;
  
  CheckSourceService get checkService => _checkService;

  SourceManagerProvider() {
    _init();
    // 監聽校驗服務的變化以更新 UI
    _checkService.addListener(() {
      if (!_checkService.isChecking) {
        loadSources(); // 校驗完成後重新載入
      }
      notifyListeners();
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _sortMode = prefs.getInt('source_sort_mode') ?? 0;
    _groupByDomain = prefs.getBool('source_group_by_domain') ?? false;
    await loadSources();
  }

  Future<void> setSortMode(int mode) async {
    _sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('source_sort_mode', mode);
    _applySort();
    notifyListeners();
  }

  Future<void> toggleGroupByDomain() async {
    _groupByDomain = !_groupByDomain;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('source_group_by_domain', _groupByDomain);
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    if (_groupByDomain) {
      _sources.sort((a, b) {
        final hostA = Uri.tryParse(a.bookSourceUrl)?.host ?? "";
        final hostB = Uri.tryParse(b.bookSourceUrl)?.host ?? "";
        int res = hostA.compareTo(hostB);
        if (res == 0) {
          res = b.lastUpdateTime.compareTo(a.lastUpdateTime);
        }
        return res;
      });
      return;
    }

    switch (_sortMode) {
      case 1: // 權重
        _sources.sort((a, b) => b.weight.compareTo(a.weight));
        break;
      case 2: // 響應速度
        _sources.sort((a, b) => a.respondTime.compareTo(b.respondTime));
        break;
      case 3: // 更新時間
        _sources.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
        break;
      case 4: // 名稱
        _sources.sort((a, b) => a.bookSourceName.compareTo(b.bookSourceName));
        break;
      default: // 手動
        _sources.sort((a, b) => a.customOrder.compareTo(b.customOrder));
        break;
    }
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();

    _sources = await _dao.getAllPart();
    _groups = await _dao.getGroups();
    _applySort();

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

  void selectInterval() {
    if (_selectedUrls.isEmpty) return;
    
    final currentVisibleSources = sources;
    int minIdx = -1;
    int maxIdx = -1;
    
    for (int i = 0; i < currentVisibleSources.length; i++) {
      if (_selectedUrls.contains(currentVisibleSources[i].bookSourceUrl)) {
        if (minIdx == -1) minIdx = i;
        maxIdx = i;
      }
    }
    
    if (minIdx != -1 && maxIdx != -1) {
      for (int i = minIdx; i <= maxIdx; i++) {
        _selectedUrls.add(currentVisibleSources[i].bookSourceUrl);
      }
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
      return await importFromData(decoded);
    } catch (e) {
      debugPrint('從文本匯入書源失敗: $e');
    }
    return 0;
  }

  /// 從解析後的資料匯入 (List 或 Map)
  Future<int> importFromData(dynamic data) async {
    try {
      if (data == null) return 0;
      List<dynamic> list = data is List ? data : [data];
      List<BookSource> newSources = [];
      
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          final source = BookSource.fromJson(item);
          source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
          newSources.add(source);
        }
      }

      if (newSources.isNotEmpty) {
        await _dao.insertOrUpdateAll(newSources);
        await loadSources();
        return newSources.length;
      }
    } catch (e) {
      debugPrint('匯入書源資料失敗: $e');
    }
    return 0;
  }

  /// 從 JSON 匯入
  Future<int> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      return await importFromData(data);
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
          // Dio 會根據 Content-Type 自動解析 JSON 為 Map 或 List
          // 如果已經是解析好的物件，直接使用 importFromData
          totalCount += await importFromData(response.data);
        }
      } catch (e) {
        debugPrint('從 URL 匯入書源失敗 ($u): $e');
      }
    }
    return totalCount;
  }
}
