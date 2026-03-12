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
import 'engine/text_page.dart';
import 'engine/chapter_provider.dart';
import '../../core/database/dao/bookmark_dao.dart';
import '../../core/models/bookmark.dart';
import '../../core/services/content_processor.dart';
import '../../core/services/webdav_service.dart';
import '../../core/database/dao/http_tts_dao.dart';
import '../../core/services/http_tts_service.dart';
import '../../core/models/http_tts.dart';

/// ReaderProvider - 閱讀器狀態管理
class ReaderProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final ReplaceRuleDao _replaceDao = ReplaceRuleDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  final HttpTtsDao _httpTtsDao = HttpTtsDao();

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
  int _scrubbingChapterIndex = -1; // 用於滑桿預覽

  // 閱讀設定
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  int _themeIndex = 0;
  double _brightness = 1.0;
  bool _chineseConvert = false;
  String? _fontFamily;

  final TTSService tts = TTSService();
  final HttpTtsService httpTts = HttpTtsService();
  final BookmarkDao _bookmarkDao = BookmarkDao();

  List<Bookmark> _bookmarks = [];
  int _pageTurnMode = 0; // 0: 平滑水平, 1: 無動畫(覆蓋), 2: 平滑垂直

  // TTS 擴展
  int _ttsMode = 0; // 0: 系統 TTS, 1: HTTP TTS
  int? _selectedHttpTtsId;
  List<HttpTTS> _httpTtsEngines = [];

  // 自動翻頁擴展
  bool _isAutoPaging = false;
  double _autoPageSpeed = 30.0;
  double _autoPageProgress = 0.0;
  Timer? _autoPageTimer;

  // 換源與內容處理
  final Map<int, BookSource> _chapterSourceOverrides = {};
  bool _reverseContent = false;
  bool _removeSameTitle = false;

  /// 為特定章節設定臨時覆蓋書源
  Future<void> replaceChapterSource(int index, BookSource source, String content) async {
    _chapterSourceOverrides[index] = source;
    _content = content;
    // 更新資料庫快取 (可選，這裡比照 Legado 僅臨時替換)
    await _chapterDao.saveContent(book.bookUrl, index, content);
    _doPaginate();
  }

  /// 獲取指定書源的特定章節內容
  Future<String> fetchChapterContent(BookSource source, Book book, BookChapter chapter) async {
    return await _service.getContent(source, book, chapter);
  }

  // 九宮格點擊動作 (高度還原 Android)
  // 0:TL, 1:TC, 2:TR, 3:ML, 4:MC, 5:MR, 6:BL, 7:BC, 8:BR
  // 動作 ID: 0:選單, 1:下一頁, 2:上一頁, 3:下一章, 4:上一章
  List<int> _clickActions = [2, 2, 1, 2, 0, 1, 2, 1, 1]; // 預設配置

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
  int get themeIndex => _themeIndex;
  ReadingTheme get currentTheme => AppTheme.readingThemes[_themeIndex];
  double get brightness => _brightness;
  int get pageTurnMode => _pageTurnMode;
  bool get chineseConvert => _chineseConvert;
  String? get fontFamily => _fontFamily;
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
    
    // 深度還原：啟動時同步 WebDAV 進度
    await WebDAVService().syncAllBookProgress();
    
    await loadChapter(_currentChapterIndex);
  }

  void setClickAction(int index, int action) {
    _clickActions[index] = action;
    saveSetting('click_actions', _clickActions.join(','));
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    _lineHeight = prefs.getDouble('reader_line_height') ?? 1.5;
    _themeIndex = prefs.getInt('reader_theme_index') ?? 0;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _pageTurnMode = prefs.getInt('reader_page_turn_mode') ?? 0;
    _chineseConvert = prefs.getBool('reader_chinese_convert') ?? false;
    _fontFamily = prefs.getString('reader_font_family');
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0;
    _selectedHttpTtsId = prefs.getInt('reader_selected_http_tts_id');
    _autoPageSpeed = prefs.getDouble('reader_auto_page_speed') ?? 30.0;

    final actionsStr = prefs.getString('reader_click_actions');
    if (actionsStr != null) {
      _clickActions = actionsStr.split(',').map((e) => int.parse(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _loadHttpTtsEngines() async {
    _httpTtsEngines = await _httpTtsDao.getAll();
    notifyListeners();
  }

  Future<void> setTtsMode(int mode) async { _ttsMode = mode; saveSetting('tts_mode', mode); }
  Future<void> setSelectedHttpTts(int? id) async {
    _selectedHttpTtsId = id;
    if (id != null) {
      saveSetting('selected_http_tts_id', id);
    } else {
      (await SharedPreferences.getInstance()).remove('reader_selected_http_tts_id');
    }
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    _bookmarks = await _bookmarkDao.getByBook(book.name, book.author);
    notifyListeners();
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) await prefs.setDouble('reader_$key', value);
    if (value is int) await prefs.setInt('reader_$key', value);
    if (value is bool) await prefs.setBool('reader_$key', value);
    if (value is String) await prefs.setString('reader_$key', value);
    notifyListeners();
  }

  void toggleControls() {
    _showControls = !_showControls;
    if (_showControls) {
      _scrubbingChapterIndex = -1;
      if (_isAutoPaging) stopAutoPage();
    }
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
    if (_isAutoPaging) startAutoPage();
  }

  void toggleAutoPage() { _isAutoPaging ? stopAutoPage() : startAutoPage(); }
  void startAutoPage() {
    _isAutoPaging = true;
    _autoPageTimer?.cancel();
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isAutoPaging) { timer.cancel(); return; }
      final delta = 0.016 / _autoPageSpeed;
      _autoPageProgress += delta;
      if (_autoPageProgress >= 1.0) { _autoPageProgress = 0.0; nextPage(); }
      notifyListeners();
    });
    notifyListeners();
  }
  void stopAutoPage() {
    _isAutoPaging = false; _autoPageProgress = 0.0;
    _autoPageTimer?.cancel(); _autoPageTimer = null;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      onPageChanged(_currentPageIndex + 1);
    } else {
      nextChapter();
    }
  }

  Future<void> _loadChapters() async {
    _chapters = await _chapterDao.getChapters(book.bookUrl);
    if (_chapters.isEmpty) {
      final source = await _sourceDao.getAll();
      _source = source.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == book.origin, orElse: () => null);
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
    _source = sources.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == book.origin, orElse: () => null);
  }

  void toggleReverseContent() { _reverseContent = !_reverseContent; loadChapter(_currentChapterIndex); }
  void toggleRemoveSameTitle() { _removeSameTitle = !_removeSameTitle; loadChapter(_currentChapterIndex); }

  Future<void> autoChangeSource() async {
    _isLoading = true; notifyListeners();
    try {
      final sources = await _sourceDao.getEnabled();
      for (final s in sources) {
        if (s.bookSourceUrl == _source?.bookSourceUrl) continue;
        final searchResults = await _service.preciseSearch([s], book.name, book.author ?? "");
        if (searchResults.isNotEmpty) {
          final bestMatch = searchResults.first;
          book.bookUrl = bestMatch.bookUrl; book.origin = bestMatch.origin; book.originName = bestMatch.originName ?? "";
          _source = s;
          final updatedBook = await _service.getBookInfo(s, book);
          _chapters = await _service.getChapterList(s, updatedBook);
          await _bookDao.insertOrUpdate(updatedBook);
          await _chapterDao.insertChapters(_chapters);
          await loadChapter(_currentChapterIndex);
          return;
        }
      }
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> loadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;
    _isLoading = true; _currentChapterIndex = index; notifyListeners();
    try {
      String? cachedContent = await _chapterDao.getContent(book.bookUrl, index);
      String rawContent = "";
      if (_chapterSourceOverrides.containsKey(index)) {
        rawContent = await _service.getContent(_chapterSourceOverrides[index]!, book, _chapters[index]);
      } else if (cachedContent != null && cachedContent.isNotEmpty) rawContent = cachedContent;
      else {
        if (_source == null) await _loadSource();
        if (_source != null) {
          rawContent = await _service.getContent(_source!, book, _chapters[index]);
          await _chapterDao.saveContent(book.bookUrl, index, rawContent);
        } else {
          rawContent = book.origin == "local" ? "缺失內容" : "找不到書源";
        }
      }
      rawContent = _processContent(rawContent, _chapters[index].title);
      final enabledRules = await _replaceDao.getEnabled();
      _content = ContentProcessor.processContent(book, _chapters[index], rawContent, chineseConvert: _chineseConvert, rules: enabledRules);
      await _bookDao.updateProgress(book.bookUrl, index, 0, _chapters[index].title);
      
      // 深度還原：加載章節後非同步上傳進度至 WebDAV
      WebDAVService().uploadBookProgress(book);
    } catch (e) { _content = "加載失敗: $e"; }
    finally { if (_viewSize != null) {
      _doPaginate();
    } else { _isLoading = false; notifyListeners(); } _preloadNextChapter(index + 1); }
  }

  String _processContent(String raw, String title) {
    String p = raw;
    if (_removeSameTitle) { final lines = p.split('\n'); if (lines.isNotEmpty && lines.first.trim() == title.trim()) { lines.removeAt(0); p = lines.join('\n'); } }
    if (_reverseContent) p = p.split('\n').reversed.join('\n');
    return p;
  }

  Future<void> _preloadNextChapter(int nextIndex) async {
    if (nextIndex >= _chapters.length || _source == null) return;
    try {
      String? cached = await _chapterDao.getContent(book.bookUrl, nextIndex);
      if (cached == null || cached.isEmpty) {
        final raw = await _service.getContent(_source!, book, _chapters[nextIndex]);
        await _chapterDao.saveContent(book.bookUrl, nextIndex, raw);
      }
    } catch (_) {}
  }

  void updateViewSize(Size size) { if (_viewSize != size) { _viewSize = size; _doPaginate(); } }
  void onPageChanged(int index) { _currentPageIndex = index; _autoPageProgress = 0.0; notifyListeners(); }

  void _doPaginate() {
    if (_viewSize == null || _chapters.isEmpty || currentChapter == null) return;
    _isLoading = true; notifyListeners();
    final titleStyle = TextStyle(fontSize: _fontSize + 4, fontWeight: FontWeight.bold, color: currentTheme.textColor, fontFamily: _fontFamily);
    final contentStyle = TextStyle(fontSize: _fontSize, height: _lineHeight, color: currentTheme.textColor, fontFamily: _fontFamily);
    _pages = ChapterProvider.paginate(content: _content, chapter: currentChapter!, chapterIndex: _currentChapterIndex, chapterSize: _chapters.length, viewSize: _viewSize!, titleStyle: titleStyle, contentStyle: contentStyle);
    _currentPageIndex = 0; _isLoading = false; notifyListeners();
  }

  void setFontSize(double s) { _fontSize = s.clamp(14.0, 30.0); saveSetting('font_size', _fontSize); _doPaginate(); }
  void setLineHeight(double h) { _lineHeight = h.clamp(1.2, 2.5); saveSetting('line_height', _lineHeight); _doPaginate(); }
  void setTheme(int i) { _themeIndex = i % AppTheme.readingThemes.length; saveSetting('theme_index', _themeIndex); }
  void setBrightness(double v) { _brightness = v.clamp(0.0, 1.0); saveSetting('brightness', _brightness); }
  void setPageTurnMode(int m) { _pageTurnMode = m; saveSetting('page_turn_mode', _pageTurnMode); }
  void setChineseConvert(bool v) { _chineseConvert = v; saveSetting('chinese_convert', _chineseConvert); loadChapter(_currentChapterIndex); }
  void setFontFamily(String? f) {
    _fontFamily = f;
    if (f == null) {
      SharedPreferences.getInstance().then((p) => p.remove('reader_font_family'));
    } else {
      saveSetting('font_family', f);
    }
    _doPaginate();
  }

  Future<void> toggleBookmark() async {
    final existing = _bookmarks.cast<Bookmark?>().firstWhere((b) => b?.chapterIndex == _currentChapterIndex && b?.chapterPos == _currentPageIndex, orElse: () => null);
    if (existing != null) {
      await _bookmarkDao.delete(existing);
    } else {
      String snip = "空白書籤";
      if (_pages.isNotEmpty && _currentPageIndex < _pages.length) {
        snip = _pages[_currentPageIndex].lines.map((l) => l.text).join().replaceAll("\n", " ");
        if (snip.length > 50) snip = "${snip.substring(0, 50)}...";
      }
      final newBm = Bookmark(time: DateTime.now().millisecondsSinceEpoch, bookName: book.name, bookAuthor: book.author, chapterIndex: _currentChapterIndex, chapterPos: _currentPageIndex, chapterName: currentChapter?.title ?? "Unknown", bookUrl: book.bookUrl, content: snip);
      await _bookmarkDao.insert(newBm);
    }
    await _loadBookmarks();
  }

  Future<void> nextChapter() => loadChapter(_currentChapterIndex + 1);
  Future<void> prevChapter() => loadChapter(_currentChapterIndex - 1);

  void toggleTts() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble('speech_rate') ?? 0.5;
    final pitch = prefs.getDouble('speech_pitch') ?? 1.0;
    final volume = prefs.getDouble('speech_volume') ?? 1.0;
    if (_ttsMode == 0) {
      if (tts.isPlaying) {
        tts.stop();
      } else {
        await tts.setRate(rate); await tts.setPitch(pitch); await tts.setVolume(volume);
        final txt = _pages.isNotEmpty && _currentPageIndex < _pages.length ? _pages.skip(_currentPageIndex).map((p) => p.lines.map((l) => l.text).join()).join('\n') : _content;
        tts.speak(txt);
      }
    } else {
      if (httpTts.isPlaying) {
        httpTts.stop();
      } else {
        if (_selectedHttpTtsId == null && _httpTtsEngines.isNotEmpty) _selectedHttpTtsId = _httpTtsEngines.first.id;
        final config = _httpTtsEngines.cast<HttpTTS?>().firstWhere((e) => e?.id == _selectedHttpTtsId, orElse: () => null);
        if (config != null) {
          final List<String> para = _content.split('\n').where((s) => s.trim().isNotEmpty).toList();
          await httpTts.speakList(config, para, speed: (rate * 10).toInt());
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> searchContent(String kw) async {
    final res = <Map<String, dynamic>>[];
    for (int i = 0; i < chapters.length; i++) {
      final c = await _chapterDao.getContent(book.bookUrl, i);
      if (c != null && c.contains(kw)) {
        final idx = c.indexOf(kw);
        final start = (idx - 20).clamp(0, c.length);
        final end = (idx + kw.length + 20).clamp(0, c.length);
        res.add({'chapterIndex': i, 'chapterTitle': chapters[i].title, 'snippet': '...${c.substring(start, end).replaceAll('\n', ' ')}...'});
      }
    }
    return res;
  }

  @override
  void dispose() { 
    tts.stop(); 
    httpTts.stop(); 
    _autoPageTimer?.cancel(); 
    
    // 深度還原：關閉閱讀器時上傳進度
    WebDAVService().uploadBookProgress(book);
    
    super.dispose(); 
  }
}
