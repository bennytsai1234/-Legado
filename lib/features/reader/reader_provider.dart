import 'dart:async';
import 'package:flutter/material.dart';
import 'provider/reader_provider_base.dart';
import 'provider/reader_settings_mixin.dart';
import 'provider/reader_content_mixin.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/services/widget_service.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/bookmark.dart';

export 'provider/reader_provider_base.dart';
export 'provider/reader_settings_mixin.dart';
export 'provider/reader_content_mixin.dart';

/// ReaderProvider - 閱讀器狀態管理 (重構後)
/// 對應 Android: ui/book/read/ReadBookViewModel.kt
class ReaderProvider extends ReaderProviderBase with ReaderSettingsMixin, ReaderContentMixin {
  ReaderProvider({required super.book, int chapterIndex = 0, int chapterPos = 0}) {
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
    if (existing != null) await bookmarkDao.delete(existing);
    else await bookmarkDao.insert(Bookmark(time: DateTime.now().millisecondsSinceEpoch, bookName: book.name, bookAuthor: book.author, chapterIndex: currentChapterIndex, chapterPos: currentPageIndex, chapterName: chapters[currentChapterIndex].title, bookUrl: book.bookUrl, content: ""));
    bookmarks = await bookmarkDao.getByBook(book.name, book.author); notifyListeners();
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
}
