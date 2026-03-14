import 'package:flutter/material.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/engine/chapter_provider.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart' as engine;
import 'package:legado_reader/shared/theme/app_theme.dart';

/// ReaderProvider 的內容加載與分頁邏輯擴展
mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  void doPaginate({bool fromEnd = false}) {
    if (viewSize == null || chapters.isEmpty) return;
    final currentTheme = AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final ts = TextStyle(fontSize: fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, letterSpacing: letterSpacing);
    final cs = TextStyle(fontSize: fontSize, height: lineHeight, color: currentTheme.textColor, letterSpacing: letterSpacing);
    
    pages = ChapterProvider.paginate(
      content: content, chapter: chapters[currentChapterIndex], chapterIndex: currentChapterIndex, chapterSize: chapters.length,
      viewSize: viewSize!, titleStyle: ts, contentStyle: cs,
      paragraphSpacing: paragraphSpacing, textIndent: textIndent, textFullJustify: textFullJustify, padding: 16.0
    );
    currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
    jumpPageController.add(currentPageIndex);
    notifyListeners();
  }

  Future<void> loadChapter(int i, {bool fromEnd = false}) async {
    if (i < 0 || i >= chapters.length) return;
    if (chapterCache.containsKey(i)) {
      currentChapterIndex = i;
      pages = chapterCache[i]!;
      content = chapterContentCache[i]!;
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 50), () => jumpPageController.add(currentPageIndex));
      return;
    }
    isLoading = true; notifyListeners();
    try {
      final res = await fetchChapterData(i);
      content = res.content; pages = res.pages.cast<TextPage>();
      chapterCache[i] = pages; chapterContentCache[i] = content;
      currentChapterIndex = i;
      currentPageIndex = fromEnd ? (pages.length - 1).clamp(0, 999) : 0;
      isLoading = false; notifyListeners();
      Future.delayed(const Duration(milliseconds: 50), () => jumpPageController.add(currentPageIndex));
    } catch (e) {
      content = "加載失敗: $e"; isLoading = false; notifyListeners();
    }
  }

  Future<({String content, List<dynamic> pages})> fetchChapterData(int i) async {
    final chapter = chapters[i];
    String? raw = await chapterDao.getContent(book.bookUrl, i);
    if (raw == null) {
      source ??= (await sourceDao.getAll()).firstWhere((s) => s.bookSourceUrl == book.origin);
      raw = await service.getContent(source!, book, chapter);
      await chapterDao.saveContent(book.bookUrl, i, raw);
    }
    final rules = await replaceDao.getEnabled();
    final c = engine.ContentProcessor.process(
      book: book, chapter: chapter, rawContent: raw, rules: rules,
      chineseConvertType: chineseConvert, reSegmentEnabled: true,
    );
    // Placeholder for actual pagination to keep mixin clean
    return (content: c, pages: []); 
  }

  void nextPage() {
    if (currentPageIndex < pages.length - 1) {
      currentPageIndex++; notifyListeners();
      jumpPageController.add(currentPageIndex);
    } else {
      nextChapter();
    }
  }

  void prevPage() {
    if (currentPageIndex > 0) {
      currentPageIndex--; notifyListeners();
      jumpPageController.add(currentPageIndex);
    } else {
      prevChapter();
    }
  }

  Future<void> nextChapter() async { if (currentChapterIndex < chapters.length - 1) await loadChapter(currentChapterIndex + 1); }
  Future<void> prevChapter() async { if (currentChapterIndex > 0) await loadChapter(currentChapterIndex - 1, fromEnd: true); }
}
