import 'package:flutter/foundation.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';
import '../../core/services/webdav_service.dart';
import '../../core/engine/app_event_bus.dart';
import '../../core/local_book/txt_parser.dart';
import '../../core/local_book/epub_parser.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class BookDetailProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final ChapterDao _chapterDao = ChapterDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  late Book _book;
  List<BookChapter> _chapters = [];
  bool _isLoading = true;
  bool _isInBookshelf = false;
  BookSource? _currentSource;

  Book get book => _book;
  List<BookChapter> get chapters => _chapters;
  bool get isLoading => _isLoading;
  bool get isInBookshelf => _isInBookshelf;
  BookSource? get currentSource => _currentSource;

  String _searchQuery = "";
  bool _isReversed = false;
  String get searchQuery => _searchQuery;
  bool get isReversed => _isReversed;

  List<BookChapter> get filteredChapters {
    var list = _chapters.where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (_isReversed) list = list.reversed.toList();
    return list;
  }

  void setSearchQuery(String q) { _searchQuery = q; notifyListeners(); }
  void toggleSort() { _isReversed = !_isReversed; notifyListeners(); }

  BookDetailProvider(AggregatedSearchBook searchBook) {
    if (searchBook.book is Book) {
      _book = searchBook.book as Book;
    } else {
      final sb = searchBook.book;
      _book = Book(
        bookUrl: sb.bookUrl,
        name: sb.name,
        author: sb.author ?? "未知",
        coverUrl: sb.coverUrl,
        intro: sb.intro,
        origin: sb.origin,
        originName: sb.originName ?? "發現",
        type: sb.type,
      );
    }
    _init();
  }

  Future<void> _init() async {
    final existing = await _bookDao.getByUrl(_book.bookUrl);
    if (existing != null) {
      _book = existing;
      _isInBookshelf = existing.isInBookshelf;
    }
    await _loadSource();
    await _loadChapters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSource() async {
    final sources = await _sourceDao.getAll();
    _currentSource = sources.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == _book.origin, orElse: () => null);
  }

  Future<void> _loadChapters() async {
    // 深度還原：處理本地書籍缺失時的 WebDav 同步
    if (_book.origin == 'local') {
      final file = File(_book.bookUrl);
      if (!await file.exists()) {
        final syncedFile = await WebDAVService().downloadLocalBook(_book);
        if (syncedFile != null) {
          _book.bookUrl = syncedFile.path;
          if (_isInBookshelf) await _bookDao.insertOrUpdate(_book);
        }
      }
      
      // 如果檔案現在存在，則嘗試解析目錄 (比照 LocalBookProvider)
      final currentFile = File(_book.bookUrl);
      if (await currentFile.exists()) {
        final ext = p.extension(currentFile.path).toLowerCase();
        if (ext == '.txt') {
          final parser = TxtParser(currentFile);
          await parser.load();
          final data = await parser.splitChapters();
          _chapters = data.asMap().entries.map((e) => BookChapter(url: "${_book.bookUrl}#${e.key}", title: e.value['title'] ?? "", bookUrl: _book.bookUrl, index: e.key)).toList();
        } else if (ext == '.epub') {
          final parser = EpubParser(currentFile);
          await parser.load();
          final data = parser.getChapters();
          _chapters = data.asMap().entries.map((e) => BookChapter(url: e.value['href'] ?? "", title: e.value['title'] ?? "", bookUrl: _book.bookUrl, index: e.key)).toList();
        }
      }
    }

    if (_chapters.isEmpty) {
      _chapters = await _chapterDao.getChapters(_book.bookUrl);
    }
    
    if (_chapters.isEmpty && _currentSource != null) {
      try {
        _chapters = await _service.getChapterList(_currentSource!, _book);
        if (_isInBookshelf) await _chapterDao.insertChapters(_chapters);
      } catch (e) { debugPrint('加載目錄失敗: $e'); }
    }
  }

  Future<void> toggleInBookshelf() async {
    _isInBookshelf = !_isInBookshelf;
    _book.isInBookshelf = _isInBookshelf;
    await _bookDao.insertOrUpdate(_book);
    if (_isInBookshelf && _chapters.isNotEmpty) {
      await _chapterDao.insertChapters(_chapters);
      
      // 深度還原：本地書籍加入書架時上傳至 WebDav
      if (_book.origin == 'local') {
        WebDAVService().uploadLocalBook(_book, File(_book.bookUrl));
      }
    }
    AppEventBus().fire(AppEventBus.upBookshelf);
    notifyListeners();
  }

  Future<void> updateBookInfo(String name, String author, String intro, String coverUrl) async {
    _book.name = name; _book.author = author; _book.intro = intro; _book.coverUrl = coverUrl;
    if (_isInBookshelf) await _bookDao.insertOrUpdate(_book);
    notifyListeners();
  }

  Future<void> updateCover(String coverUrl) async {
    _book.customCoverUrl = coverUrl.isEmpty ? null : coverUrl;
    if (_isInBookshelf) await _bookDao.insertOrUpdate(_book);
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _chapterDao.deleteContentByBook(_book.bookUrl);
  }

  Future<void> preloadChapters(int start, int count) async {
    if (_currentSource == null) return;
    int end = start + count - 1;
    for (int i = start; i <= end && i < _chapters.length; i++) {
      try {
        final content = await _service.getContent(_currentSource!, _book, _chapters[i]);
        await _chapterDao.saveContent(_book.bookUrl, i, content);
      } catch (_) {}
    }
  }
}
