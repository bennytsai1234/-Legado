import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/engine/chapter_provider.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart' as engine;
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/services/http_tts_service.dart';
import 'package:legado_reader/core/models/http_tts.dart';
import 'package:legado_reader/core/services/widget_service.dart';

class ReaderProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final ReplaceRuleDao _replaceDao = ReplaceRuleDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  final HttpTtsDao _httpTtsDao = HttpTtsDao();
  final BookmarkDao _bookmarkDao = BookmarkDao();
  
  final StreamController<int> _jumpPageController = StreamController<int>.broadcast();
  Stream<int> get jumpPageStream => _jumpPageController.stream;

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
  int _scrubbingChapterIndex = -1;

  // 排版設定
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  double _paragraphSpacing = 1.0;
  double _letterSpacing = 0.0;
  double _textPadding = 16.0;
  int _textIndent = 2;
  double _titleTopSpacing = 0.0;
  double _titleBottomSpacing = 8.0;
  bool _textFullJustify = true;
  int _themeIndex = 0;
  double _brightness = 1.0;
  int _chineseConvert = 0;
  String? _fontFamily;
  String _backgroundImage = '';

  final TTSService tts = TTSService();
  final HttpTtsService httpTts = HttpTtsService();

  List<Bookmark> _bookmarks = [];
  int _pageTurnMode = 0;

  int _ttsMode = 0;
  int? _selectedHttpTtsId;
  List<HttpTTS> _httpTtsEngines = [];

  bool _isAutoPaging = false;
  double _autoPageSpeed = 30.0;
  double _autoPageProgress = 0.0;
  Timer? _autoPageTimer;

  bool _reverseContent = false;
  bool _removeSameTitle = false;
  List<int> _clickActions = [2, 2, 1, 2, 0, 1, 2, 1, 1];

  final Map<int, BookSource> _chapterSourceOverrides = {};

  ReaderProvider({required this.book, int chapterIndex = 0, int chapterPos = 0}) {
    _currentChapterIndex = chapterIndex;
    _currentPageIndex = chapterPos;
    _init();
    tts.onComplete = () { if (tts.isPlaying) nextPage(); };
  }

  // Getters
  String get content => _content;
  List<TextPage> get pages => _pages;

  // 預加載緩存
  final Map<int, List<TextPage>> _chapterCache = {};
  final Map<int, String> _chapterContentCache = {};
  bool _isPreloading = false;
  bool get isLoading => _isLoading;
  bool get showControls => _showControls;
  int get currentChapterIndex => _scrubbingChapterIndex != -1 ? _scrubbingChapterIndex : _currentChapterIndex;
  int get currentPageIndex => _currentPageIndex;
  List<BookChapter> get chapters => _chapters;
  BookChapter? get currentChapter => _chapters.isNotEmpty && currentChapterIndex < _chapters.length ? _chapters[currentChapterIndex] : null;

  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  double get paragraphSpacing => _paragraphSpacing;
  double get letterSpacing => _letterSpacing;
  double get textPadding => _textPadding;
  int get textIndent => _textIndent;
  double get titleTopSpacing => _titleTopSpacing;
  double get titleBottomSpacing => _titleBottomSpacing;
  bool get textFullJustify => _textFullJustify;
  int get themeIndex => _themeIndex;
  ReadingTheme get currentTheme {
    if (AppTheme.readingThemes.isEmpty) {
      return const ReadingTheme(name: 'Loading', backgroundColor: Colors.white, textColor: Colors.black);
    }
    if (_themeIndex < 0 || _themeIndex >= AppTheme.readingThemes.length) {
      return AppTheme.readingThemes[0];
    }
    return AppTheme.readingThemes[_themeIndex];
  }
  double get brightness => _brightness;
  int get pageTurnMode => _pageTurnMode;
  int get chineseConvert => _chineseConvert;
  String? get fontFamily => _fontFamily;
  String get backgroundImage => _backgroundImage;
  int get ttsMode => _ttsMode;
  int? get selectedHttpTtsId => _selectedHttpTtsId;
  List<HttpTTS> get httpTtsEngines => _httpTtsEngines;
  bool get isAutoPaging => _isAutoPaging;
  double get autoPageSpeed => _autoPageSpeed;
  double get autoPageProgress => _autoPageProgress;
  bool get reverseContent => _reverseContent;
  bool get removeSameTitle => _removeSameTitle;
  List<int> get clickActions => _clickActions;
  int get batteryLevel => 100;

  bool get isBookmarked => _bookmarks.any((b) => b.chapterIndex == _currentChapterIndex && b.chapterPos == _currentPageIndex);

  Future<void> _init() async {
    await _loadSettings();
    await _loadBookmarks();
    await _loadChapters();
    await _loadSource();
    await _loadHttpTtsEngines();
    if (await WebDAVService().isConfigured()) {
      await WebDAVService().syncAllBookProgress();
    }
    await loadChapter(_currentChapterIndex);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    _lineHeight = prefs.getDouble('reader_line_height') ?? 1.5;
    _paragraphSpacing = prefs.getDouble('reader_paragraph_spacing') ?? 1.0;
    _textIndent = prefs.getInt('reader_text_indent') ?? 2; // Keep as int
    _letterSpacing = prefs.getDouble('reader_letter_spacing') ?? 0.0;
    _textPadding = prefs.getDouble('reader_text_padding') ?? 16.0;
    _titleTopSpacing = prefs.getDouble('reader_title_top_spacing') ?? 0.0;
    _titleBottomSpacing = prefs.getDouble('reader_title_bottom_spacing') ?? 10.0;
    _textFullJustify = prefs.getBool('reader_text_full_justify') ?? true;
    _fontFamily = prefs.getString('selected_font_family') ?? prefs.getString('reader_font_family'); // Keep original logic
    _themeIndex = prefs.getInt('reader_theme_index') ?? 0;
    _brightness = prefs.getDouble('reader_brightness') ?? 0.5;
    _pageTurnMode = prefs.getInt('reader_page_turn_mode') ?? 0;
    _chineseConvert = prefs.getInt('reader_chinese_convert_v2') ?? (prefs.getBool('reader_chinese_convert') == true ? 1 : 0); // Keep original logic
    _removeSameTitle = prefs.getBool('reader_remove_same_title') ?? false;
    _autoPageSpeed = prefs.getDouble('reader_auto_page_speed') ?? 30.0;
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0; // Keep original logic
    _selectedHttpTtsId = prefs.getInt('reader_selected_http_tts_id'); // Keep original logic
    
    final isNight = _themeIndex == 1;
    _backgroundImage = prefs.getString(isNight ? PreferKey.bgImageN : PreferKey.bgImage) ?? '';

    final actionsStr = prefs.getString('reader_click_actions') ?? '2,0,1,2,0,1,2,0,1';
    _clickActions = actionsStr.split(',').map((e) => int.parse(e)).toList();
    if (_clickActions.length < 9) _clickActions = [2,0,1,2,0,1,2,0,1];
    notifyListeners();
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('reader_$key');
    } else if (value is double) {
      await prefs.setDouble('reader_$key', value);
    } else if (value is int) {
      await prefs.setInt('reader_$key', value);
    } else if (value is bool) {
      await prefs.setBool('reader_$key', value);
    } else if (value is String) {
      await prefs.setString('reader_$key', value);
    }
    notifyListeners();
  }

  void _doPaginate({bool fromEnd = false}) {
    if (_viewSize == null || _chapters.isEmpty || currentChapter == null) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    final titleStyle = TextStyle(
        fontSize: _fontSize + 4,
        fontWeight: FontWeight.bold,
        color: currentTheme.textColor,
        fontFamily: _fontFamily,
        letterSpacing: _letterSpacing);
    final contentStyle = TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
        color: currentTheme.textColor,
        fontFamily: _fontFamily,
        letterSpacing: _letterSpacing);
    _pages = ChapterProvider.paginate(
        content: _content,
        chapter: currentChapter!,
        chapterIndex: _currentChapterIndex,
        chapterSize: _chapters.length,
        viewSize: _viewSize!,
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        paragraphSpacing: _paragraphSpacing,
        textIndent: _textIndent,
        titleTopSpacing: _titleTopSpacing,
        titleBottomSpacing: _titleBottomSpacing,
        textFullJustify: _textFullJustify,
        padding: _textPadding);
    
    _currentPageIndex = fromEnd ? (_pages.length - 1).clamp(0, double.infinity).toInt() : 0;
    _jumpPageController.add(_currentPageIndex);
    _isLoading = false;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(12.0, 40.0);
    saveSetting('font_size', _fontSize);
    _chapterCache.clear(); // 設定改變，清除緩存
    _chapterContentCache.clear();
    _doPaginate();
  }

  void setLineHeight(double height) {
    _lineHeight = height.clamp(1.0, 3.0);
    saveSetting('line_height', _lineHeight);
    _chapterCache.clear();
    _chapterContentCache.clear();
    _doPaginate();
  }

  void setParagraphSpacing(double s) {
    _paragraphSpacing = s.clamp(0.0, 5.0);
    saveSetting('paragraph_spacing', _paragraphSpacing);
    _doPaginate();
  }

  void setLetterSpacing(double s) {
    _letterSpacing = s.clamp(-1.0, 5.0);
    saveSetting('letter_spacing', _letterSpacing);
    _doPaginate();
  }

  void setTextPadding(double p) {
    _textPadding = p.clamp(0.0, 50.0);
    saveSetting('text_padding', _textPadding);
    _doPaginate();
  }

  void setTextIndent(int v) {
    _textIndent = v.clamp(0, 8);
    saveSetting('text_indent', _textIndent);
    _doPaginate();
  }

  void setTitleTopSpacing(double v) {
    _titleTopSpacing = v.clamp(0.0, 100.0);
    saveSetting('title_top_spacing', _titleTopSpacing);
    _doPaginate();
  }

  void setTitleBottomSpacing(double v) {
    _titleBottomSpacing = v.clamp(0.0, 100.0);
    saveSetting('title_bottom_spacing', _titleBottomSpacing);
    _doPaginate();
  }

  void setTextFullJustify(bool v) {
    _textFullJustify = v;
    saveSetting('text_full_justify', _textFullJustify);
    _doPaginate();
  }

  void setTheme(int i) {
    _themeIndex = i.clamp(0, AppTheme.readingThemes.length - 1);
    final theme = AppTheme.readingThemes[_themeIndex];
    
    // 套用主題內的排版設定
    _fontSize = theme.textSize;
    _lineHeight = theme.lineSpacing;
    _paragraphSpacing = theme.paragraphSpacing;
    _letterSpacing = theme.letterSpacing;
    _backgroundImage = theme.backgroundImage ?? "";
    
    saveSetting('theme_index', _themeIndex);
    _doPaginate();
  }

  void setBrightness(double v) {
    _brightness = v.clamp(0.0, 1.0);
    saveSetting('brightness', _brightness);
    notifyListeners();
  }

  void setPageTurnMode(int m) {
    _pageTurnMode = m;
    saveSetting('page_turn_mode', _pageTurnMode);
    notifyListeners();
  }

  void setChineseConvert(int v) {
    _chineseConvert = v;
    saveSetting('chinese_convert_v2', _chineseConvert);
    loadChapter(_currentChapterIndex);
  }

  void setFontFamily(String? f) {
    _fontFamily = f;
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      if (f != null) {
        p.setString('selected_font_family', f);
        p.setString('reader_font_family', f);
      } else {
        p.remove('selected_font_family');
        p.remove('reader_font_family');
      }
    });
    _doPaginate();
  }

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void onScrubbing(int index) {
    _scrubbingChapterIndex = index;
    notifyListeners();
  }

  void onScrubEnd(int index) {
    _scrubbingChapterIndex = -1;
    loadChapter(index);
  }

  void setAutoPageSpeed(double speed) {
    _autoPageSpeed = speed.clamp(5.0, 300.0);
    saveSetting('auto_page_speed', _autoPageSpeed);
  }

  void onPageChanged(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void jumpToPage(int index) {
    _currentPageIndex = index;
    _jumpPageController.add(index);
    notifyListeners();
  }

  Future<void> loadChapter(int index, {bool fromEnd = false}) async {
    if (index < 0 || index >= _chapters.length) return;
    if (_isLoading && !_chapterCache.containsKey(index)) return; // 避免重複加載，但允許緩存切換
    
    // 如果已有緩存，先快速切換
    if (_chapterCache.containsKey(index) && _chapterContentCache.containsKey(index)) {
      _currentChapterIndex = index;
      _pages = _chapterCache[index]!;
      _content = _chapterContentCache[index]!;
      _currentPageIndex = fromEnd ? (_pages.length - 1).remainder(_pages.length).toInt() : 0;
      _jumpPageController.add(_currentPageIndex);
      notifyListeners();
      _afterChapterLoaded(index);
      _startPreloading(index);
      return;
    }

    _isLoading = true;
    _currentChapterIndex = index;
    notifyListeners();
    try {
      final result = await _fetchChapterData(index);
      _content = result.content;
      _pages = result.pages;
      
      _chapterCache[index] = _pages;
      _chapterContentCache[index] = _content;

      _currentPageIndex = fromEnd ? (_pages.length - 1).clamp(0, double.infinity).toInt() : 0;
      _jumpPageController.add(_currentPageIndex);
      _isLoading = false;
      notifyListeners();
      
      _afterChapterLoaded(index);
      _startPreloading(index);
    } catch (e) {
      _content = "加載失敗: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  void _afterChapterLoaded(int index) async {
    final chapter = _chapters[index];
    _bookDao.updateProgress(book.bookUrl, index, 0, chapter.title);
    if (await WebDAVService().isConfigured()) {
      WebDAVService().uploadBookProgress(book);
    }
    
    // 同步到桌面小組件
    final progress = _chapters.isNotEmpty ? (index / _chapters.length) : 0.0;
    WidgetService().updateRecentBook(book, lastChapterTitle: chapter.title, progress: progress);
  }

  void _startPreloading(int currentIndex) async {
    if (_isPreloading) return;
    _isPreloading = true;
    
    // 清理遠端緩存，只保留鄰近章節
    _chapterCache.removeWhere((key, value) => (key - currentIndex).abs() > 2);
    _chapterContentCache.removeWhere((key, value) => (key - currentIndex).abs() > 2);

    try {
      // 預加載下一章
      if (currentIndex + 1 < _chapters.length && !_chapterCache.containsKey(currentIndex + 1)) {
        final res = await _fetchChapterData(currentIndex + 1);
        _chapterCache[currentIndex + 1] = res.pages;
        _chapterContentCache[currentIndex + 1] = res.content;
      }
      // 預加載上一章
      if (currentIndex - 1 >= 0 && !_chapterCache.containsKey(currentIndex - 1)) {
        final res = await _fetchChapterData(currentIndex - 1);
        _chapterCache[currentIndex - 1] = res.pages;
        _chapterContentCache[currentIndex - 1] = res.content;
      }
    } catch (e) {
      debugPrint("Preload error: $e");
    } finally {
      _isPreloading = false;
    }
  }

  Future<({String content, List<TextPage> pages})> _fetchChapterData(int index) async {
    final chapter = _chapters[index];
    String? cachedContent = await _chapterDao.getContent(book.bookUrl, index);
    String rawContent = "";
    
    if (_chapterSourceOverrides.containsKey(index)) {
      rawContent = await _service.getContent(_chapterSourceOverrides[index]!, book, chapter);
    } else if (cachedContent != null) {
      rawContent = cachedContent;
    } else {
      if (_source == null) await _loadSource();
      rawContent = await _service.getContent(_source!, book, chapter);
      await _chapterDao.saveContent(book.bookUrl, index, rawContent);
    }

    final rules = await _replaceDao.getEnabled();
    final content = engine.ContentProcessor.process(
      book: book,
      chapter: chapter,
      rawContent: rawContent,
      rules: rules,
      chineseConvertType: _chineseConvert,
      reSegmentEnabled: true,
      removeSameTitle: _removeSameTitle,
    );

    final titleStyle = TextStyle(
        fontSize: _fontSize + 4,
        fontWeight: FontWeight.bold,
        color: currentTheme.textColor,
        fontFamily: _fontFamily,
        letterSpacing: _letterSpacing);
    final contentStyle = TextStyle(
        fontSize: _fontSize,
        height: _lineHeight,
        color: currentTheme.textColor,
        fontFamily: _fontFamily,
        letterSpacing: _letterSpacing);

    final pages = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: index,
        chapterSize: _chapters.length,
        viewSize: _viewSize ?? const Size(360, 640), // 降級處理
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        paragraphSpacing: _paragraphSpacing,
        textIndent: _textIndent,
        titleTopSpacing: _titleTopSpacing,
        titleBottomSpacing: _titleBottomSpacing,
        textFullJustify: _textFullJustify,
        padding: _textPadding);
    
    return (content: content, pages: pages);
  }

  Future<void> replaceChapterSource(int index, BookSource source, String content) async {
    _chapterSourceOverrides[index] = source;
    _content = content;
    await _chapterDao.saveContent(book.bookUrl, index, content);
    _doPaginate();
  }

  Future<void> _loadSource() async {
    final sources = await _sourceDao.getAll();
    _source = sources.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == book.origin, orElse: () => null);
  }

  Future<void> _loadChapters() async {
    _chapters = await _chapterDao.getChapters(book.bookUrl);
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    _bookmarks = await _bookmarkDao.getByBook(book.name, book.author);
    notifyListeners();
  }

  Future<void> _loadHttpTtsEngines() async {
    _httpTtsEngines = await _httpTtsDao.getAll();
    notifyListeners();
  }

  void setClickAction(int index, int action) {
    _clickActions[index] = action;
    saveSetting('click_actions', _clickActions.join(','));
    notifyListeners();
  }

  void nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      jumpToPage(_currentPageIndex + 1);
    } else {
      nextChapter();
    }
  }

  Future<void> nextChapter() => loadChapter(_currentChapterIndex + 1);
  Future<void> prevChapter() => loadChapter(_currentChapterIndex - 1, fromEnd: true);

  void toggleTts() async {
    if (_ttsMode == 0) {
      tts.isPlaying ? tts.stop() : tts.speak(_content);
    } else {
      if (httpTts.isPlaying) {
        httpTts.stop();
      } else if (_selectedHttpTtsId != null) {
        final eng = _httpTtsEngines.firstWhere((e) => e.id == _selectedHttpTtsId);
        await httpTts.speakList(eng, _content.split('\n'));
      }
    }
    notifyListeners();
  }

  void startAutoPage() {
    _isAutoPaging = true;
    _autoPageTimer?.cancel();
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isAutoPaging) { timer.cancel(); return; }
      final delta = 0.016 / _autoPageSpeed;
      _autoPageProgress += delta;
      if (_autoPageProgress >= 1.0) {
        _autoPageProgress = 0.0;
        nextPage();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopAutoPage() {
    _isAutoPaging = false;
    _autoPageProgress = 0.0;
    _autoPageTimer?.cancel();
    _autoPageTimer = null;
    notifyListeners();
  }

  void toggleAutoPage() { _isAutoPaging ? stopAutoPage() : startAutoPage(); }

  Future<void> toggleBookmark() async {
    final existing = _bookmarks.cast<Bookmark?>().firstWhere((b) => b?.chapterIndex == _currentChapterIndex && b?.chapterPos == _currentPageIndex, orElse: () => null);
    if (existing != null) {
      await _bookmarkDao.delete(existing);
    } else {
      await _bookmarkDao.insert(Bookmark(
          time: DateTime.now().millisecondsSinceEpoch,
          bookName: book.name,
          bookAuthor: book.author,
          chapterIndex: _currentChapterIndex,
          chapterPos: _currentPageIndex,
          chapterName: currentChapter?.title ?? "",
          bookUrl: book.bookUrl,
          content: ""));
    }
    await _loadBookmarks();
  }

  Future<void> autoChangeSource() async {
    _isLoading = true;
    notifyListeners();
    try {
      final sources = await _sourceDao.getEnabled();
      for (final s in sources) {
        if (s.bookSourceUrl == _source?.bookSourceUrl) continue;
        final searchResults = await _service.preciseSearch([s], book.name, book.author);
        if (searchResults.isNotEmpty) {
          final bestMatch = searchResults.first;
          book.bookUrl = bestMatch.bookUrl;
          book.origin = bestMatch.origin;
          book.originName = bestMatch.originName ?? "";
          _source = s;
          final updatedBook = await _service.getBookInfo(s, book);
          _chapters = await _service.getChapterList(s, updatedBook);
          await _bookDao.insertOrUpdate(updatedBook);
          await _chapterDao.insertChapters(_chapters);
          await loadChapter(_currentChapterIndex);
          return;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> searchContent(String kw) async {
    final res = <Map<String, dynamic>>[];
    for (int i = 0; i < chapters.length; i++) {
      String? c = await _chapterDao.getContent(book.bookUrl, i);
      if (c != null && c.contains(kw)) {
        res.add({
          'chapterIndex': i,
          'chapterTitle': chapters[i].title,
          'snippet': '...${c.substring((c.indexOf(kw) - 20).clamp(0, c.length), (c.indexOf(kw) + kw.length + 20).clamp(0, c.length)).replaceAll('\n', ' ')}...'
        });
      }
    }
    return res;
  }

  void updateViewSize(Size size) { if (_viewSize != size) { _viewSize = size; _doPaginate(); } }
  void toggleReverseContent() { _reverseContent = !_reverseContent; loadChapter(_currentChapterIndex); }
  void toggleRemoveSameTitle() { _removeSameTitle = !_removeSameTitle; loadChapter(_currentChapterIndex); }

  @override
  void dispose() { 
    tts.stop(); 
    httpTts.stop(); 
    _autoPageTimer?.cancel(); 
    _jumpPageController.close();
    super.dispose(); 
  }
}
