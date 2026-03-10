import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/book_source.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/chapter_dao.dart';
import 'book_source_service.dart';

/// 下載任務模型
class DownloadTask {
  final Book book;
  final BookChapter chapter;
  final BookSource source;

  DownloadTask({
    required this.book,
    required this.chapter,
    required this.source,
  });
}

/// DownloadService - 離線下載服務
/// 在背景批次下載章節內容到本地資料庫 (ChapterDao)
class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;

  final ChapterDao _chapterDao = ChapterDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  final Queue<DownloadTask> _queue = Queue<DownloadTask>();
  bool _isDownloading = false;
  int _totalTaskCount = 0;
  int _completedTaskCount = 0;

  bool get isDownloading => _isDownloading;
  int get queueSize => _queue.length;
  double get progress =>
      _totalTaskCount > 0 ? _completedTaskCount / _totalTaskCount : 0.0;

  DownloadService._internal();

  /// 新增下載任務
  Future<void> addDownloadTasks(Book book, List<BookChapter> chapters) async {
    final source = await _sourceDao.getByUrl(book.origin);
    if (source == null) {
      debugPrint("Download ignored: Source not found.");
      return;
    }

    for (var chapter in chapters) {
      _queue.add(DownloadTask(book: book, chapter: chapter, source: source));
    }

    _totalTaskCount += chapters.length;
    notifyListeners();

    if (!_isDownloading) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isDownloading = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();

      try {
        final cached = await _chapterDao.getContent(
          task.book.bookUrl,
          task.chapter.index,
        );

        // 未快取或快取為空，則進行下載
        if (cached == null || cached.isEmpty) {
          final content = await _service.getContent(
            task.source,
            task.book,
            task.chapter,
          );

          if (content.isNotEmpty && !content.contains("錯誤")) {
            await _chapterDao.saveContent(
              task.book.bookUrl,
              task.chapter.index,
              content,
            );
          }
        }
      } catch (e) {
        debugPrint("Download Error for chapter ${task.chapter.index}: $e");
      }

      _completedTaskCount++;
      notifyListeners();

      // 可以考慮加入 Future.delayed 避免過度占用 CPU 與網路
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isDownloading = false;
    _totalTaskCount = 0;
    _completedTaskCount = 0;
    notifyListeners();
  }

  /// 停止下載清空佇列
  void cancelDownloads() {
    _queue.clear();
    _isDownloading = false;
    _totalTaskCount = 0;
    _completedTaskCount = 0;
    notifyListeners();
  }
}
