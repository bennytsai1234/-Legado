import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/services/check_source_service.dart';

class SourceManagerProvider with ChangeNotifier {
  final BookSourceDao _dao = BookSourceDao();
  final CheckSourceService checkService = CheckSourceService();

  List<BookSource> _sources = [];
  List<BookSource> get sources {
    List<BookSource> list = List.from(_sources);
    if (_selectedGroup != '全部') {
      list = list.where((s) => s.bookSourceGroup?.contains(_selectedGroup) ?? false).toList();
    }
    // 排序邏輯...
    if (_sortMode == 1) {
      list.sort((a, b) => b.weight.compareTo(a.weight));
    } else {
      list.sort((a, b) => a.customOrder.compareTo(b.customOrder));
    }
    return list.cast<BookSource>();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isBatchMode = false;
  bool get isBatchMode => _isBatchMode;

  final Set<String> _selectedUrls = {};
  Set<String> get selectedUrls => _selectedUrls;

  List<String> _groups = ['全部'];
  List<String> get groups => _groups;

  String _selectedGroup = '全部';
  String get selectedGroup => _selectedGroup;

  int _sortMode = 0; // 0: 手動, 1: 權重
  int get sortMode => _sortMode;

  bool _groupByDomain = false;
  bool get groupByDomain => _groupByDomain;

  SourceManagerProvider() {
    loadSources();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();
    // 使用精簡版載入列表，避免 CursorWindow 溢出 (Android 2MB 限制)
    _sources = await _dao.getAllPart();
    _updateGroups();
    _isLoading = false;
    notifyListeners();
  }

  void _updateGroups() {
    final Set<String> groupSet = {'全部'};
    for (var s in _sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groupSet.addAll(s.bookSourceGroup!.split(RegExp(r'[,，\s]+')));
      }
    }
    _groups = groupSet.toList();
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    notifyListeners();
  }

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
    if (_selectedUrls.length == sources.length) {
      _selectedUrls.clear();
    } else {
      _selectedUrls.addAll(sources.map((s) => s.bookSourceUrl));
    }
    notifyListeners();
  }

  Future<void> toggleEnabled(BookSource source) async {
    // 必須獲取完整書源，避免 getAllPart 載入的精簡數據覆蓋掉 JS 規則
    final fullSource = await _dao.getByUrl(source.bookSourceUrl);
    if (fullSource != null) {
      fullSource.enabled = !fullSource.enabled;
      await _dao.insertOrUpdate(fullSource);
      // 同步更新本地列表狀態
      source.enabled = fullSource.enabled;
      notifyListeners();
    }
  }

  Future<void> deleteSource(BookSource source) async {
    await _dao.deleteSources([source.bookSourceUrl]);
    await loadSources();
  }

  Future<void> deleteSelected() async {
    await _dao.deleteSources(_selectedUrls.toList());
    _isBatchMode = false;
    _selectedUrls.clear();
    await loadSources();
  }

  Future<void> exportSelected() async {
    final List<BookSource> selectedFullSources = [];
    for (var url in _selectedUrls) {
      final full = await _dao.getByUrl(url);
      if (full != null) selectedFullSources.add(full);
    }
    final json = jsonEncode(selectedFullSources.map((s) => s.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: json));
  }

  // --- 排序與分組管理 ---
  Future<void> reorderSource(int oldIndex, int newIndex) async {
    if (_sortMode != 0 || _groupByDomain) return;
    if (newIndex > oldIndex) newIndex -= 1;
    
    final list = sources;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await _dao.updateCustomOrder(list);
    await loadSources();
  }

  Future<void> addGroup(String name) async {
    if (name.isEmpty || _groups.contains(name)) return;
    _groups.add(name);
    notifyListeners();
  }

  Future<void> renameGroup(String oldName, String newName) async {
    if (newName.isEmpty || oldName == newName) return;
    await _dao.renameGroup(oldName, newName);
    await loadSources();
  }

  Future<void> deleteGroup(String name) async {
    await _dao.removeGroupLabel(name);
    if (_selectedGroup == name) _selectedGroup = '全部';
    await loadSources();
  }

  // --- 校驗功能 ---
  Future<void> checkSelectedSources() async {
    if (_selectedUrls.isEmpty) return;
    final urls = _selectedUrls.toList();
    _isBatchMode = false;
    _selectedUrls.clear();
    await checkService.check(urls);
  }

  Future<void> checkAllSources() async {
    final urls = sources.map((s) => s.bookSourceUrl).toList();
    await checkService.check(urls);
  }

  Future<void> clearInvalidSources() async {
    final invalidUrls = _sources
        .where((s) => (s.bookSourceGroup?.contains('失效') ?? false) || s.respondTime == -1)
        .map((s) => s.bookSourceUrl)
        .toList();
    
    if (invalidUrls.isNotEmpty) {
      await _dao.deleteSources(invalidUrls);
      await loadSources();
    }
  }

  Future<void> selectionAddToGroups(Set<String> urls, String groupName) async {
    if (urls.isEmpty || groupName.isEmpty) return;
    for (var url in urls) {
      final source = await _dao.getByUrl(url);
      if (source != null) {
        source.addGroup(groupName);
        await _dao.insertOrUpdate(source);
      }
    }
    _isBatchMode = false;
    _selectedUrls.clear();
    await loadSources();
  }

  Future<void> selectionRemoveFromGroups(Set<String> urls, String groupName) async {
    if (urls.isEmpty || groupName.isEmpty) return;
    for (var url in urls) {
      final source = await _dao.getByUrl(url);
      if (source != null) {
        source.removeGroup(groupName);
        await _dao.insertOrUpdate(source);
      }
    }
    _isBatchMode = false;
    _selectedUrls.clear();
    await loadSources();
  }

  // --- 匯入功能 ---
  Future<int> importFromUrl(String url) async {
    try {
      final response = await Dio().get(url);
      return await importFromJson(response.data);
    } catch (e) {
      return 0;
    }
  }

  Future<int> importFromText(String text) async {
    try {
      return await importFromJson(jsonDecode(text));
    } catch (e) {
      return 0;
    }
  }

  Future<int> importFromQr(String code) async {
    if (code.startsWith('http')) return await importFromUrl(code);
    return 0;
  }

  Future<int> importFromJson(dynamic data) async {
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = [data];
    }
    
    int count = 0;
    for (var item in list) {
      try {
        final source = BookSource.fromJson(item);
        await _dao.insertOrUpdate(source);
        count++;
      } catch (_) {}
    }
    await loadSources();
    return count;
  }

  void toggleGroupByDomain() { _groupByDomain = !_groupByDomain; notifyListeners(); }
  void setSortMode(int mode) { _sortMode = mode; notifyListeners(); }
}
