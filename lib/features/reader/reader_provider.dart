import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/services/widget_service.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/bookmark.dart';

export 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
export 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';

/// ReaderProvider - 閱讀器狀態管理 (重構後)
/// 對應 Android: ui/book/read/ReadBookViewModel.kt
class ReaderProvider extends ReaderProviderBase with ReaderSettingsMixin, ReaderContentMixin {
  ReaderProvider({required Book book, int chapterIndex = 0, int chapterPos = 0}) : super(book) {
    currentChapterIndex = chapterIndex;
    currentPageIndex = chapterPos;
    _init();
  }

  Future<void> _init() async {
    await loadSettings();
    await _loadChapters();
    await _loadSource();
    if (await WebDAVService().isConfigured()) await WebDAVService().syncAllBookProgress();
    await loadChapter(currentChapterIndex);
  }

  Future<void> _loadChapters() async { chapters = await chapterDao.getChapters(book.bookUrl); notifyListeners(); }
  Future<void> _loadSource() async { source = (await sourceDao.getAll()).cast<dynamic>().firstWhere((s) => s.bookSourceUrl == book.origin, orElse: () => null); }

  void onPageChanged(int i) { if (currentPageIndex != i) { currentPageIndex = i; notifyListeners(); } }
  void toggleControls() { showControls = !showControls; notifyListeners(); }
  
  void updateViewSize(Size s) { if (viewSize != s) { viewSize = s; doPaginate(); } }

  void afterChapterLoaded(int i) async {
    bookDao.updateProgress(book.bookUrl, i, 0, chapters[i].title);
    if (await WebDAVService().isConfigured()) await WebDAVService().uploadBookProgress(book);
    WidgetService().updateRecentBook(book, lastChapterTitle: chapters[i].title, progress: chapters.isNotEmpty ? (i / chapters.length) : 0.0);
  }

  Future<void> toggleBookmark() async {
    final existing = bookmarks.cast<Bookmark?>().firstWhere((b) => b?.chapterIndex == currentChapterIndex && b?.chapterPos == currentPageIndex, orElse: () => null);
    if (existing != null) {
      await bookmarkDao.delete(existing);
    } else {
      await bookmarkDao.insert(Bookmark(time: DateTime.now().millisecondsSinceEpoch, bookName: book.name, bookAuthor: book.author, chapterIndex: currentChapterIndex, chapterPos: currentPageIndex, chapterName: chapters[currentChapterIndex].title, bookUrl: book.bookUrl, content: ""));
    }
    bookmarks = await bookmarkDao.getByBook(book.name, book.author); notifyListeners();
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

  // --- 缺失屬性與方法補全 ---
  bool isAutoPaging = false;
  Stream<int> get jumpPageStream => jumpPageController.stream;

  void toggleTts() { /* Placeholder for TTS toggle */ }
  void toggleAutoPage() { isAutoPaging = !isAutoPaging; notifyListeners(); }

  // --- 缺失屬性補全 ---
  double autoPageSpeed = 1.0;
  int batteryLevel = 100;
  double autoPageProgress = 0.0;
  double textPadding = 16.0;
  int ttsMode = 0;
  double rate = 1.0;

  BookChapter? get currentChapter => chapters.isNotEmpty ? chapters[currentChapterIndex] : null;
  bool get isBookmarked => bookmarks.any((b) => b.chapterIndex == currentChapterIndex && b.chapterPos == currentPageIndex);

  void setAutoPageSpeed(double v) { autoPageSpeed = v; notifyListeners(); }
  void stopAutoPage() { isAutoPaging = false; notifyListeners(); }
  void setChineseConvert(int v) { chineseConvert = v; clearReaderCache(); doPaginate(); }
  void setTtsMode(int v) { ttsMode = v; notifyListeners(); }
  void setTtsRate(double v) { rate = v; notifyListeners(); }
  void syncWebDAV() { /* Placeholder */ }
  void setClickAction(int area, int action) { clickActions[area] = action; notifyListeners(); }
  void onScrubStart() { /* Placeholder */ }
  void onScrubbing(int i) { scrubbingChapterIndex = i; notifyListeners(); }
  void onScrubEnd(int i) { loadChapter(i); }

  dynamic get tts => null; // Placeholder for actual TTS state

  Future<void> replaceChapterSource(int index, BookSource newSource, String newContent) async {
    chapterContentCache[index] = newContent;
    // Update local DB if needed, or just keep in memory for current session
    notifyListeners();
    loadChapter(index);
  }
}
