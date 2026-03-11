import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book_source.dart';
import '../models/book.dart';
import '../database/dao/book_source_dao.dart';
import 'book_source_service.dart';

/// CheckSourceService - 書源校驗服務
/// 對應 Android: service/CheckSourceService.kt
class CheckSourceService extends ChangeNotifier {
  static final CheckSourceService _instance = CheckSourceService._internal();
  factory CheckSourceService() => _instance;

  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();

  bool _isChecking = false;
  int _totalCount = 0;
  int _currentCount = 0;
  String _statusMsg = "";

  CheckSourceService._internal();

  bool get isChecking => _isChecking;
  int get totalCount => _totalCount;
  int get currentCount => _currentCount;
  String get statusMsg => _statusMsg;

  /// 開始校驗選中的書源 (高度還原 Android check 邏輯)
  Future<void> check(List<String> urls) async {
    if (_isChecking) return;
    
    _isChecking = true;
    _totalCount = urls.length;
    _currentCount = 0;
    notifyListeners();

    // 實作併發控制 (預設 5 個併發)
    const int maxConcurrent = 5;
    final List<Future> tasks = [];
    final List<String> queue = List.from(urls);

    while (queue.isNotEmpty || tasks.isNotEmpty) {
      while (queue.isNotEmpty && tasks.length < maxConcurrent) {
        final url = queue.removeAt(0);
        final task = _checkSingleSource(url).then((_) {
          _currentCount++;
          notifyListeners();
        });
        tasks.add(task);
        // 移除已完成的 task
        task.then((_) => tasks.remove(task));
      }
      if (tasks.isNotEmpty) {
        await Future.wait(List.from(tasks));
      }
    }

    _isChecking = false;
    _statusMsg = "校驗完成";
    notifyListeners();
  }

  /// 單個書源深度校驗 (高度還原 Android checkSource)
  Future<void> _checkSingleSource(String url) async {
    final source = await _sourceDao.getByUrl(url);
    if (source == null) return;

    _statusMsg = "正在校驗: ${source.bookSourceName}";
    notifyListeners();

    try {
      // 1. 移除舊的錯誤標籤
      source.removeGroup("搜尋失效");
      source.removeGroup("目錄失效");
      source.removeGroup("正文失效");
      source.removeGroup("校驗超時");

      final stopwatch = Stopwatch().start();

      // 2. 測試搜尋 (Search Check)
      final searchWord = source.getCheckKeyword("我的");
      final searchResults = await _service.searchBook(source, searchWord).timeout(const Duration(seconds: 15));
      
      if (searchResults.isEmpty) {
        source.addGroup("搜尋失效");
      } else {
        // 3. 測試詳情與目錄 (Info & TOC Check)
        final firstBook = searchResults.first;
        final chapters = await _service.getChapterList(source, firstBook).timeout(const Duration(seconds: 10));
        
        if (chapters.isEmpty) {
          source.addGroup("目錄失效");
        } else {
          // 4. 測試正文 (Content Check)
          final firstChapter = chapters.firstWhere((c) => !c.isVolume, orElse: () => chapters.first);
          final content = await _service.getContent(source, firstBook, firstChapter).timeout(const Duration(seconds: 10));
          
          if (content.isEmpty || content.length < 10) {
            source.addGroup("正文失效");
          }
        }
      }

      stopwatch.stop();
      source.respondTime = stopwatch.elapsedMilliseconds;
      source.lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
      
      // 更新書源狀態
      await _sourceDao.insertOrUpdate(source);
    } on TimeoutException {
      source.addGroup("校驗超時");
      await _sourceDao.insertOrUpdate(source);
    } catch (e) {
      debugPrint("CheckSource Error [${source.bookSourceName}]: $e");
      source.addGroup("網站失效");
      await _sourceDao.insertOrUpdate(source);
    }
  }

  void cancel() {
    _isChecking = false;
    notifyListeners();
  }
}
