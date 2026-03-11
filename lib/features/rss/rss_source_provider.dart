import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/database/dao/rss_source_dao.dart';
import '../../core/models/rss_source.dart';

class RssSourceProvider extends ChangeNotifier {
  final RssSourceDao _dao = RssSourceDao();
  List<RssSource> _sources = [];
  bool _isLoading = false;
  final String _currentGroup = "全部";

  List<RssSource> get sources => _sources;
  bool get isLoading => _isLoading;
  String get currentGroup => _currentGroup;

  RssSourceProvider() {
    loadSources();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();
    _sources = await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleEnabled(RssSource source) async {
    final newState = !source.enabled;
    await _dao.updateEnabled(source.sourceUrl, newState);
    source.enabled = newState;
    notifyListeners();
  }

  Future<void> deleteSource(String url) async {
    await _dao.delete(url);
    await loadSources();
  }

  Future<int> importFromUrl(String url) async {
    try {
      final response = await Dio().get(url);
      if (response.data != null) {
        final List<dynamic> jsonList = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;
        
        int count = 0;
        for (final item in jsonList) {
          final source = RssSource.fromJson(item);
          await _dao.insertOrUpdate(source);
          count++;
        }
        await loadSources();
        return count;
      }
    } catch (e) {
      debugPrint('匯入 RSS 來源失敗: $e');
    }
    return 0;
  }
}
