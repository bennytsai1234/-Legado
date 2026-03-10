import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book_source.dart';

class SourceManagerProvider extends ChangeNotifier {
  final BookSourceDao _dao = BookSourceDao();
  List<BookSource> _sources = [];
  List<String> _groups = [];
  String _selectedGroup = '全部';
  bool _isLoading = false;

  List<BookSource> get sources {
    if (_selectedGroup == '全部') return _sources;
    return _sources
        .where((s) => s.bookSourceGroup?.contains(_selectedGroup) ?? false)
        .toList();
  }

  List<String> get groups => ['全部', ..._groups];
  String get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;

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

  /// 從文本匯入 (JSON 格式)
  Future<int> importFromText(String text) async {
    try {
      final dynamic decoded = jsonDecode(text);
      List<BookSource> newSources = [];

      if (decoded is List) {
        newSources =
            decoded
                .map(
                  (item) => BookSource.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      } else if (decoded is Map) {
        newSources = [BookSource.fromJson(decoded as Map<String, dynamic>)];
      }

      if (newSources.isNotEmpty) {
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
  Future<int> importFromUrl(String url) async {
    try {
      final response = await Dio().get(url);
      if (response.data != null) {
        String content;
        if (response.data is String) {
          content = response.data;
        } else {
          content = jsonEncode(response.data);
        }
        return await importFromText(content);
      }
    } catch (e) {
      debugPrint('從 URL 匯入失敗: $e');
    }
    return 0;
  }
}
