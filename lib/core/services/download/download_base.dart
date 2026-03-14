import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/download_task.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/download_dao.dart';
import '../book_source_service.dart';

/// DownloadService 的基礎狀態與 DAO 定義
abstract class DownloadBase extends ChangeNotifier {
  final BookDao bookDao = BookDao();
  final BookSourceDao sourceDao = BookSourceDao();
  final ChapterDao chapterDao = ChapterDao();
  final DownloadDao downloadDao = DownloadDao();
  final BookSourceService sourceService = BookSourceService();

  final List<DownloadTask> tasks = [];
  bool isDownloading = false;
  bool isPaused = false;
  Completer<void>? pauseCompleter;
  bool isScheduling = false;
  bool isBookshelfRefreshing = false;
  
  final int maxConcurrent = 3;
  final int maxChapterConcurrent = 5;

  double get totalProgress {
    if (tasks.isEmpty) return 0.0;
    int total = 0;
    int success = 0;
    for (var task in tasks) {
      total += task.totalCount;
      success += task.successCount;
    }
    return total == 0 ? 0.0 : success / total;
  }

  void update() => notifyListeners();
}
