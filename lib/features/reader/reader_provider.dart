import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/database/dao/replace_rule_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';
import '../../core/services/tts_service.dart';
import '../../shared/theme/app_theme.dart';
import 'engine/text_page.dart';
import 'engine/chapter_provider.dart';

class ReaderProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final ReplaceRuleDao _replaceDao = ReplaceRuleDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  final Book book;
  BookSource? _source;
  List<BookChapter> _chapters = [];

  int _currentChapterIndex = 0;
  int _currentPageIndex = 0;
  String _content = "";
  List<TextPage> _pages = [];
  Size? _viewSize;

  bool _isLoading = false;
  bool _showControls = false;

  // 閱讀設定
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  int _themeIndex = 0;
  double _brightness = 1.0;
  
  final TTSService tts = TTSService();

  ReaderProvider({required this.book, int chapterIndex = 0}) {
    _currentChapterIndex = chapterIndex;
    _init();
  }

  // Getters
  String get content => _content;
  List<TextPage> get pages => _pages;
  bool get isLoading => _isLoading;
  bool get showControls => _showControls;
  int get currentChapterIndex => _currentChapterIndex;
  int get currentPageIndex => _currentPageIndex;
  List<BookChapter> get chapters => _chapters;
  BookChapter? get currentChapter =>
      _chapters.isNotEmpty ? _chapters[_currentChapterIndex] : null;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  int get themeIndex => _themeIndex;
  ReadingTheme get currentTheme => AppTheme.readingThemes[_themeIndex];
  double get brightness => _brightness;

  Future<void> _init() async {
    await _loadSettings();
    await _loadChapters();
    await _loadSource();
    await loadChapter(_currentChapterIndex);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    _lineHeight = prefs.getDouble('reader_line_height') ?? 1.5;
    _themeIndex = prefs.getInt('reader_theme_index') ?? 0;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    notifyListeners();
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) await prefs.setDouble('reader_$key', value);
    if (value is int) await prefs.setInt('reader_$key', value);
    notifyListeners();
  }

  Future<void> _loadChapters() async {
    _chapters = await _chapterDao.getChapters(book.bookUrl);
    if (_chapters.isEmpty) {
      // 如果本地沒目錄，嘗試從網路抓取 (這通常在詳情頁已經做過)
      final source = await _sourceDao.getAll();
      _source = source.cast<BookSource?>().firstWhere(
        (s) => s?.bookSourceUrl == book.origin,
        orElse: () => null,
      );
      if (_source != null) {
        _chapters = await _service.getChapterList(_source!, book);
        await _chapterDao.insertChapters(_chapters);
      }
    }
    notifyListeners();
  }

  Future<void> _loadSource() async {
    if (_source != null) return;
    final sources = await _sourceDao.getAll();
    _source = sources.cast<BookSource?>().firstWhere(
      (s) => s?.bookSourceUrl == book.origin,
      orElse: () => null,
    );
  }

  Future<void> loadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    _isLoading = true;
    _currentChapterIndex = index;
    notifyListeners();

    try {
      // 1. 嘗試從快取讀取
      String? cachedContent = await _chapterDao.getContent(book.bookUrl, index);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        _content = await _applyReplaceRules(cachedContent);
      } else {
        // 2. 從網路抓取
        if (_source == null) await _loadSource();
        if (_source != null) {
          final rawContent = await _service.getContent(
            _source!,
            book,
            _chapters[index],
          );
          await _chapterDao.saveContent(book.bookUrl, index, rawContent);
          _content = await _applyReplaceRules(rawContent);
        } else {
          _content = "錯誤：找不到書源";
        }
      }

      // 3. 更新書籍進度
      await _bookDao.updateProgress(
        book.bookUrl,
        index,
        0, // reset to page 0 on new chapter
        _chapters[index].title,
      );
    } catch (e) {
      _content = "加載章節失敗: $e";
    } finally {
      if (_viewSize != null) {
        _doPaginate();
      } else {
        _isLoading = false;
        notifyListeners();
      }
      
      // 非同步預載下一章
      _preloadNextChapter(index + 1);
    }
  }

  Future<void> _preloadNextChapter(int nextIndex) async {
    if (nextIndex >= _chapters.length || _source == null) return;
    
    try {
      String? cachedContent = await _chapterDao.getContent(book.bookUrl, nextIndex);
      if (cachedContent == null || cachedContent.isEmpty) {
        final rawContent = await _service.getContent(
          _source!,
          book,
          _chapters[nextIndex],
        );
        await _chapterDao.saveContent(book.bookUrl, nextIndex, rawContent);
      }
    } catch (e) {
      // 忽略預載錯誤
    }
  }

  void updateViewSize(Size size) {
    if (_viewSize != size) {
      _viewSize = size;
      _doPaginate();
    }
  }

  void onPageChanged(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void _doPaginate() {
    if (_viewSize == null || _chapters.isEmpty || currentChapter == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Use Future.microtask or compute if it freezes, but text layout with binary search is fast enough normally in Dart
    final titleStyle = TextStyle(
      fontSize: _fontSize + 4,
      fontWeight: FontWeight.bold,
      color: currentTheme.textColor,
    );

    final contentStyle = TextStyle(
      fontSize: _fontSize,
      height: _lineHeight,
      color: currentTheme.textColor,
    );

    _pages = ChapterProvider.paginate(
      content: _content,
      chapter: currentChapter!,
      chapterIndex: _currentChapterIndex,
      chapterSize: _chapters.length,
      viewSize: _viewSize!,
      titleStyle: titleStyle,
      contentStyle: contentStyle,
    );

    _currentPageIndex = 0;
    _isLoading = false;
    notifyListeners();
  }

  Future<String> _applyReplaceRules(String content) async {
    final rules = await _replaceDao.getEnabled();
    var result = content;
    for (final rule in rules) {
      final pattern =
          rule.isRegex
              ? RegExp(rule.pattern, multiLine: true, dotAll: true)
              : RegExp(RegExp.escape(rule.pattern));
      result = result.replaceAll(pattern, rule.replacement);
    }
    // 基本排版清洗
    result = result.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    return result.trim();
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(14.0, 30.0);
    saveSetting('font_size', _fontSize);
    _doPaginate();
  }

  void setLineHeight(double height) {
    _lineHeight = height.clamp(1.2, 2.5);
    saveSetting('line_height', _lineHeight);
    _doPaginate();
  }

  void setTheme(int index) {
    _themeIndex = index % AppTheme.readingThemes.length;
    saveSetting('theme_index', _themeIndex);
    // Don't need to re-layout for theme change, just repaint, but colors are read dynamically so notify is enough.
  }

  void setBrightness(double value) {
    _brightness = value.clamp(0.0, 1.0);
    saveSetting('brightness', _brightness);
  }


  Future<void> nextChapter() => loadChapter(_currentChapterIndex + 1);
  Future<void> prevChapter() => loadChapter(_currentChapterIndex - 1);

  // === TTS Methods ===
  void toggleTts() {
    if (tts.isPlaying) {
      tts.stop();
    } else {
      // Read from current page text
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        final currentText = _pages.skip(_currentPageIndex)
          .map((p) => p.lines.map((l) => l.text).join())
          .join('\n');
        tts.speak(currentText.isNotEmpty ? currentText : _content);
      } else {
        tts.speak(_content);
      }
    }
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }
}
