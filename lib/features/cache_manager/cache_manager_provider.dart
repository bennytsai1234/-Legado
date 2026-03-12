import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/services/download_service.dart';

class CacheManagerProvider extends ChangeNotifier {
  final Book book;
  final ChapterDao _chapterDao = ChapterDao();
  final DownloadService downloadService = DownloadService();

  List<BookChapter> _chapters = [];
  final Set<int> _cachedIndices = {};
  bool _isLoading = false;

  List<BookChapter> get chapters => _chapters;
  Set<int> get cachedIndices => _cachedIndices;
  bool get isLoading => _isLoading;

  CacheManagerProvider(this.book) {
    loadStatus();
    downloadService.addListener(notifyListeners);
  }

  @override
  void dispose() {
    downloadService.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> loadStatus() async {
    _isLoading = true;
    notifyListeners();

    _chapters = await _chapterDao.getChapters(book.bookUrl);
    _cachedIndices.clear();
    
    // 檢查每章是否有快取 (這在大章節數下可能較慢，可優化為一次性 SQL 查詢)
    for (var chapter in _chapters) {
      final content = await _chapterDao.getContent(book.bookUrl, chapter.index);
      if (content != null && content.isNotEmpty) {
        _cachedIndices.add(chapter.index);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> downloadChapters(int start, int end) async {
    final toDownload = _chapters.sublist(
      start.clamp(0, _chapters.length),
      end.clamp(0, _chapters.length),
    );
    await downloadService.addDownloadTask(book, toDownload);
  }

  Future<void> clearCache() async {
    await _chapterDao.deleteByBook(book.bookUrl);
    await loadStatus();
  }
}
