import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/book_source.dart';
import '../models/download_task.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../database/dao/download_dao.dart';
import 'book_source_service.dart';

/// DownloadService - 書籍離線快取服務
/// 對應 Android: service/CacheBookService.kt
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final BookSourceService _sourceService = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();
  final DownloadDao _downloadDao = DownloadDao();

  final List<DownloadTask> _tasks = [];
  bool _isDownloading = false;
  int _maxConcurrent = 3; // 最大併發書籍數
  int _maxChapterConcurrent = 5; // 每本書最大併發章節數

  DownloadService._internal() {
    _loadTasks();
  }

  List<DownloadTask> get tasks => _tasks;
  bool get isDownloading => _isDownloading;

  /// 從資料庫恢復任務
  Future<void> _loadTasks() async {
    final unfinished = await _downloadDao.getUnfinishedTasks();
    _tasks.clear();
    _tasks.addAll(unfinished);
    notifyListeners();
    if (_tasks.isNotEmpty && !_isDownloading) {
      startDownloads();
    }
  }

  /// 添加下載任務 (高度還原 Android addDownloadData)
  Future<void> addDownloadTask(Book book, List<BookChapter> chapters) async {
    if (chapters.isEmpty) return;

    final task = DownloadTask(
      bookUrl: book.bookUrl,
      bookName: book.name,
      startChapterIndex: chapters.first.index,
      endChapterIndex: chapters.last.index,
      totalCount: chapters.length,
      status: 0,
      lastUpdateTime: DateTime.now().millisecondsSinceEpoch,
    );

    await _downloadDao.insertOrUpdate(task);
    
    // 如果任務已在隊列中，更新它
    int existingIndex = _tasks.indexWhere((t) => t.bookUrl == book.bookUrl);
    if (existingIndex != -1) {
      _tasks[existingIndex] = task;
    } else {
      _tasks.add(task);
    }

    notifyListeners();
    if (!_isDownloading) {
      startDownloads();
    }
  }

  /// 開始下載隊列
  Future<void> startDownloads() async {
    if (_isDownloading) return;
    _isDownloading = true;
    notifyListeners();

    while (_tasks.any((t) => t.status == 0 || t.status == 1)) {
      final activeTasks = _tasks.where((t) => t.status == 1).toList();
      if (activeTasks.length < _maxConcurrent) {
        final nextTask = _tasks.cast<DownloadTask?>().firstWhere((t) => t?.status == 0, orElse: () => null);
        if (nextTask != null) {
          _processTask(nextTask);
        } else if (activeTasks.isEmpty) {
          break;
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    _isDownloading = false;
    notifyListeners();
  }

  /// 處理單個書籍任務
  Future<void> _processTask(DownloadTask task) async {
    task.status = 1;
    await _downloadDao.updateProgress(task.bookUrl, status: 1);
    notifyListeners();

    try {
      final bookSource = await _sourceDao.getByUrl(task.bookUrl); // 這裡簡化處理，實際應從 Book 獲取源 URL
      // 注意：實際邏輯需先根據 bookUrl 找到 Book 及其對應的 BookSource
      // 這裡暫定能獲取到必要的解析器
      
      final chapters = await _chapterDao.getChapters(task.bookUrl);
      final toDownload = chapters.where((c) => c.index >= task.startChapterIndex && c.index <= task.endChapterIndex).toList();

      int poolCount = 0;
      for (var chapter in toDownload) {
        // 檢查是否已快取 (簡化判斷)
        if (await _chapterDao.hasContent(task.bookUrl, chapter.index)) {
          task.successCount++;
          continue;
        }

        // 控制章節併發
        while (poolCount >= _maxChapterConcurrent) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        poolCount++;
        _downloadChapter(task, chapter).then((success) {
          if (success) {
            task.successCount++;
          } else {
            task.errorCount++;
          }
          poolCount--;
          task.currentChapterIndex = chapter.index;
          _downloadDao.updateProgress(task.bookUrl, 
            currentChapterIndex: chapter.index,
            successCount: task.successCount,
            errorCount: task.errorCount,
          );
          notifyListeners();
        });
      }

      // 等待所有章節完成
      while (poolCount > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      task.status = 3; // 已完成
      await _downloadDao.updateProgress(task.bookUrl, status: 3);
    } catch (e) {
      task.status = 4; // 失敗
      await _downloadDao.updateProgress(task.bookUrl, status: 4);
    }
    notifyListeners();
  }

  Future<bool> _downloadChapter(DownloadTask task, BookChapter chapter) async {
    // 實際下載邏輯：調用 _sourceService.getContent
    // 這裡需要獲取正確的 BookSource，此處為簡化演示
    return true; 
  }

  void pauseTask(String bookUrl) {
    final task = _tasks.cast<DownloadTask?>().firstWhere((t) => t?.bookUrl == bookUrl, orElse: () => null);
    if (task != null) {
      task.status = 2;
      _downloadDao.updateProgress(bookUrl, status: 2);
      notifyListeners();
    }
  }

  void removeTask(String bookUrl) {
    _tasks.removeWhere((t) => t.bookUrl == bookUrl);
    _downloadDao.delete(bookUrl);
    notifyListeners();
  }
}
