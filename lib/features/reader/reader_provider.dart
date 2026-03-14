import 'dart:async';
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
import '../../core/constant/prefer_key.dart';
import 'engine/text_page.dart';
import 'engine/chapter_provider.dart';
import '../../core/database/dao/bookmark_dao.dart';
import '../../core/models/bookmark.dart';
import '../../core/services/content_processor.dart';
import '../../core/services/webdav_service.dart';
import '../../core/database/dao/http_tts_dao.dart';
import '../../core/services/http_tts_service.dart';
import '../../core/models/http_tts.dart';

class ReaderProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final ReplaceRuleDao _replaceDao = ReplaceRuleDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  final HttpTtsDao _httpTtsDao = HttpTtsDao();
  final BookmarkDao _bookmarkDao = BookmarkDao();

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
  int get themeIndex => _themeIndex;
  ReadingTheme get currentTheme => AppTheme.readingThemes[_themeIndex];
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
    await WebDAVService().syncAllBookProgress();
    await loadChapter(_currentChapterIndex);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    _lineHeight = prefs.getDouble('reader_line_height') ?? 1.5;
    _paragraphSpacing = prefs.getDouble('reader_paragraph_spacing') ?? 1.0;
    _letterSpacing = prefs.getDouble('reader_letter_spacing') ?? 0.0;
    _textPadding = prefs.getDouble('reader_text_padding') ?? 16.0;
    _themeIndex = prefs.getInt('reader_theme_index') ?? 0;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _pageTurnMode = prefs.getInt('reader_page_turn_mode') ?? 0;
    _chineseConvert = prefs.getInt('reader_chinese_convert_v2') ?? (prefs.getBool('reader_chinese_convert') == true ? 1 : 0);
    _fontFamily = prefs.getString('selected_font_family') ?? prefs.getString('reader_font_family');
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0;
    _selectedHttpTtsId = prefs.getInt('reader_selected_http_tts_id');
    _autoPageSpeed = prefs.getDouble('reader_auto_page_speed') ?? 30.0;
    
    final isNight = _themeIndex == 1;
    _backgroundImage = prefs.getString(isNight ? PreferKey.bgImageN : PreferKey.bgImage) ?? '';

    final actionsStr = prefs.getString('reader_click_actions');
    if (actionsStr != null) {
      _clickActions = actionsStr.split(',').map((e) => int.parse(e)).toList();
    }
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

  void _doPaginate() {
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
        padding: _textPadding);
    _currentPageIndex = 0;
    _isLoading = false;
    notifyListeners();
  }

  void setFontSize(double s) {
    _fontSize = s.clamp(14.0, 30.0);
    saveSetting('font_size', _fontSize);
    _doPaginate();
  }

  void setLineHeight(double h) {
    _lineHeight = h.clamp(1.2, 2.5);
    saveSetting('line_height', _lineHeight);
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

  void setTheme(int i) async {
    _themeIndex = i % AppTheme.readingThemes.length;
    saveSetting('theme_index', _themeIndex);
    final prefs = await SharedPreferences.getInstance();
    final isNight = _themeIndex == 1;
    _backgroundImage =
        prefs.getString(isNight ? PreferKey.bgImageN : PreferKey.bgImage) ?? '';
    notifyListeners();
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

  Future<void> loadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) {
      return;
    }
    _isLoading = true;
    _currentChapterIndex = index;
    notifyListeners();
    try {
      String? cachedContent = await _chapterDao.getContent(book.bookUrl, index);
      String rawContent = "";
      if (_chapterSourceOverrides.containsKey(index)) {
        rawContent = await _service.getContent(
            _chapterSourceOverrides[index]!, book, _chapters[index]);
      } else if (cachedContent != null) {
        rawContent = cachedContent;
      } else {
        if (_source == null) {
          await _loadSource();
        }
        rawContent =
            await _service.getContent(_source!, book, _chapters[index]);
        await _chapterDao.saveContent(book.bookUrl, index, rawContent);
      }
      final enabledRules = await _replaceDao.getEnabled();
      _content = ContentProcessor.processContent(book, _chapters[index],
          rawContent,
          rules: enabledRules, chineseConvertType: _chineseConvert);
      await _bookDao.updateProgress(
          book.bookUrl, index, 0, _chapters[index].title);
      WebDAVService().uploadBookProgress(book);
      _doPaginate();
    } catch (e) {
      _content = "加載失敗: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replaceChapterSource(
      int index, BookSource source, String content) async {
    _chapterSourceOverrides[index] = source;
    _content = content;
    await _chapterDao.saveContent(book.bookUrl, index, content);
    _doPaginate();
  }

  Future<void> _loadSource() async {
    final sources = await _sourceDao.getAll();
    _source = sources
        .cast<BookSource?>()
        .firstWhere((s) => s?.bookSourceUrl == book.origin, orElse: () => null);
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
      onPageChanged(++_currentPageIndex);
    } else {
      nextChapter();
    }
  }

  Future<void> nextChapter() => loadChapter(_currentChapterIndex + 1);
  Future<void> prevChapter() => loadChapter(_currentChapterIndex - 1);

  void toggleTts() async {
    if (_ttsMode == 0) {
      if (tts.isPlaying) {
        tts.stop();
      } else {
        tts.speak(_content);
      }
    } else {
      if (httpTts.isPlaying) {
        httpTts.stop();
      } else if (_selectedHttpTtsId != null) {
        final eng =
            _httpTtsEngines.firstWhere((e) => e.id == _selectedHttpTtsId);
        await httpTts.speakList(eng, _content.split('\n'));
      }
    }
    notifyListeners();
  }

  void startAutoPage() {
    _isAutoPaging = true;
    _autoPageTimer?.cancel();
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isAutoPaging) {
        timer.cancel();
        return;
      }
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

  void toggleAutoPage() {
    _isAutoPaging ? stopAutoPage() : startAutoPage();
  }

  Future<void> toggleBookmark() async {
    final existing = _bookmarks.cast<Bookmark?>().firstWhere(
        (b) =>
            b?.chapterIndex == _currentChapterIndex &&
            b?.chapterPos == _currentPageIndex,
        orElse: () => null);
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
        if (s.bookSourceUrl == _source?.bookSourceUrl) {
          continue;
        }
        final searchResults =
            await _service.preciseSearch([s], book.name, book.author);
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
          'snippet':
              '...${c.substring((c.indexOf(kw) - 20).clamp(0, c.length), (c.indexOf(kw) + kw.length + 20).clamp(0, c.length)).replaceAll('\n', ' ')}...'
        });
      }
    }
    return res;
  }

  void updateViewSize(Size size) {
    if (_viewSize != size) {
      _viewSize = size;
      _doPaginate();
    }
  }

  void toggleReverseContent() {
    _reverseContent = !_reverseContent;
    loadChapter(_currentChapterIndex);
  }

  void toggleRemoveSameTitle() {
    _removeSameTitle = !_removeSameTitle;
    loadChapter(_currentChapterIndex);
  }

  @override
  void dispose() {
    tts.stop();
    httpTts.stop();
    _autoPageTimer?.cancel();
    super.dispose();
  }
}
