import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/download_task.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../database/dao/download_dao.dart';
import 'book_source_service.dart';
import 'event_bus.dart';

/// DownloadService - 書籍離線快取服務
/// 對應 Android: service/CacheBookService.kt
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final BookDao _bookDao = BookDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();
  final DownloadDao _downloadDao = DownloadDao();
  final BookSourceService _sourceService = BookSourceService();

  final List<DownloadTask> _tasks = [];
  bool _isDownloading = false;
  final int _maxConcurrent = 3; // 最大併發書籍數
  final int _maxChapterConcurrent = 5; // 每本書最大併發章節數

  DownloadService._internal() {
    _loadTasks();
  }

  List<DownloadTask> get tasks => _tasks;
  bool get isDownloading => _isDownloading;

  /// 獲取總體下載進度 (0.0 - 1.0)
  double get progress {
    if (_tasks.isEmpty) return 0.0;
    int total = 0;
    int success = 0;
    for (var task in _tasks) {
      total += task.totalCount;
      success += task.successCount;
    }
    return total == 0 ? 0.0 : success / total;
  }

  /// 取消所有下載
  void cancelDownloads() {
    _isDownloading = false;
    for (var task in _tasks) {
      if (task.status == 0 || task.status == 1) {
        task.status = 2; // Paused
        _downloadDao.updateProgress(task.bookUrl, status: 2);
      }
    }
    notifyListeners();
  }

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
      final book = await _bookDao.getByUrl(task.bookUrl);
      if (book == null) throw Exception("書籍不存在");
      
      final source = await _sourceDao.getByUrl(book.origin);
      if (source == null) throw Exception("書源不存在");
      
      final chapters = await _chapterDao.getChapters(task.bookUrl);
      final toDownload = chapters.where((c) => c.index >= task.startChapterIndex && c.index <= task.endChapterIndex).toList();

      int poolCount = 0;
      for (var chapter in toDownload) {
        if (!_isDownloading || task.status == 2) break; // Check for pause/cancel
        
        // 檢查是否已快取
        if (await _chapterDao.hasContent(task.bookUrl, chapter.index)) {
          task.successCount++;
          continue;
        }

        // 控制章節併發
        while (poolCount >= _maxChapterConcurrent) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        poolCount++;
        _downloadChapter(book, source, task, chapter).then((success) {
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

      if (task.status != 2) {
        task.status = 3; // 已完成
        await _downloadDao.updateProgress(task.bookUrl, status: 3);
        
        // 觸發書架刷新 (對標 Android 任務結束後的通知)
        AppEventBus().fire(AppEvent(AppEventBus.upBookshelf, data: task.bookUrl));
      }
    } catch (e) {
      if (task.status != 2) {
        task.status = 4; // 失敗
        await _downloadDao.updateProgress(task.bookUrl, status: 4);
      }
    }
    notifyListeners();
  }

  Future<bool> _downloadChapter(Book book, dynamic source, DownloadTask task, BookChapter chapter) async {
    try {
      final content = await _sourceService.getContent(source, book, chapter);
      if (content.isNotEmpty) {
        await _chapterDao.saveContent(book.bookUrl, chapter.index, content);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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

