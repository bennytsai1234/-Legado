import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';

import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_group_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_group.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/services/event_bus.dart';
import 'package:legado_reader/core/local_book/txt_parser.dart';
import 'package:legado_reader/core/local_book/epub_parser.dart';

class BookshelfProvider with ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final BookGroupDao _groupDao = BookGroupDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  final ChapterDao _chapterDao = ChapterDao();

  List<Book> _books = [];
  List<BookGroup> _groups = [];
  int _currentGroupId = -1; // -1: 全部
  bool _isLoading = false;
  bool _isBatchMode = false;
  final Set<String> _selectedBookUrls = {};
  StreamSubscription? _eventSub;

  List<Book> get books => _books;
  List<BookGroup> get groups => _groups;
  int get currentGroupId => _currentGroupId;
  bool get isLoading => _isLoading;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedBookUrls => _selectedBookUrls;

  bool isGridView = true;
  bool showUnread = true;
  bool _showLastUpdate = false;
  bool get showLastUpdate => _showLastUpdate;

  int _sortMode = 0; // 0:手動, 1:最後閱讀, 2:最晚更新, 3:書名, 4:作者
  int get sortMode => _sortMode;

  int _updatingCount = 0;
  int get updatingCount => _updatingCount;

  BookshelfProvider() {
    _init();
    _eventSub = AppEventBus().onName(AppEventBus.upBookshelf).listen((_) => loadBooks());
    AppEventBus().onName('importLocalBook').listen((event) {
      if (event.data is String) {
        importLocalBookPath(event.data);
      }
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    isGridView = prefs.getBool('bookshelf_is_grid') ?? true;
    showUnread = prefs.getBool('bookshelf_show_unread') ?? true;
    _showLastUpdate = prefs.getBool('bookshelf_show_last_update') ?? false;
    _sortMode = prefs.getInt('bookshelf_sort_mode') ?? 0;
    
    await loadGroups();
    await loadBooks();
  }

  void toggleViewMode() {
    isGridView = !isGridView;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_is_grid', isGridView));
    notifyListeners();
  }

  void toggleShowLastUpdate() {
    _showLastUpdate = !_showLastUpdate;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_show_last_update', _showLastUpdate));
    notifyListeners();
  }

  void toggleBatchMode({String? initialSelectedUrl}) {
    _isBatchMode = !_isBatchMode;
    _selectedBookUrls.clear();
    if (_isBatchMode && initialSelectedUrl != null) {
      _selectedBookUrls.add(initialSelectedUrl);
    }
    notifyListeners();
  }

  Future<void> setSortMode(int mode) async {
    _sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookshelf_sort_mode', mode);
    await loadBooks();
  }

  Future<void> loadGroups() async {
    _groups = await _groupDao.getAll();
    if (_groups.isEmpty) {
      await _groupDao.initDefaultGroups();
      _groups = await _groupDao.getAll();
    }
    notifyListeners();
  }

  Future<void> setGroup(int groupId) async {
    _currentGroupId = groupId;
    await loadBooks();
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      List<Book> allBooks = await _bookDao.getAllInBookshelf();
      
      // 1. 分組過濾
      if (_currentGroupId > 0) {
        allBooks = allBooks.where((b) => (b.group & _currentGroupId) != 0).toList();
      } else if (_currentGroupId == 0) {
        allBooks = allBooks.where((b) => b.group == 0).toList();
      }
      
      // 2. 排序
      switch (_sortMode) {
        case 1: allBooks.sort((a, b) => b.durChapterTime.compareTo(a.durChapterTime)); break;
        case 2: allBooks.sort((a, b) => b.latestChapterTime.compareTo(a.latestChapterTime)); break;
        case 3: allBooks.sort((a, b) => a.name.compareTo(b.name)); break;
        case 4: allBooks.sort((a, b) => a.author.compareTo(b.author)); break;
        default: allBooks.sort((a, b) => a.order.compareTo(b.order)); break;
      }

      _books = allBooks;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelect(String url) {
    _selectedBookUrls.contains(url) ? _selectedBookUrls.remove(url) : _selectedBookUrls.add(url);
    notifyListeners();
  }

  void selectAll() {
    _selectedBookUrls.length == _books.length ? _selectedBookUrls.clear() : _selectedBookUrls.addAll(_books.map((b) => b.bookUrl));
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var url in _selectedBookUrls) {
      await _bookDao.delete(url);
      await _chapterDao.deleteByBook(url);
    }
    _isBatchMode = false;
    _selectedBookUrls.clear();
    await loadBooks();
  }

  Future<void> moveSelectedToGroup(int groupId) async {
    for (var url in _selectedBookUrls) {
      final book = _books.cast<Book?>().firstWhere((b) => b?.bookUrl == url, orElse: () => null);
      if (book != null) {
        book.group = groupId;
        await _bookDao.updateProgress(book.bookUrl, book.durChapterIndex, book.durChapterPos, book.durChapterTitle ?? "");
      }
    }
    _isBatchMode = false;
    _selectedBookUrls.clear();
    await loadBooks();
  }

  Future<void> refreshBookshelf() async {
    final onlineBooks = _books.where((b) => !b.isLocal).toList();
    if (onlineBooks.isEmpty) return;

    AppEventBus().fire(AppEvent('bookshelfRefreshStart'));
    int completed = 0;
    final List<Future<void>> updateTasks = [];

    for (var book in onlineBooks) {
      updateTasks.add(Future(() async {
        try {
          final source = await _sourceDao.getByUrl(book.origin);
          if (source != null) {
            final info = await _service.getBookInfo(source, book);
            final chapters = await _service.getChapterList(source, info);
            if (chapters.length > book.totalChapterNum) {
              info.lastCheckCount = chapters.length - book.totalChapterNum;
              info.latestChapterTitle = chapters.last.title;
              info.latestChapterTime = DateTime.now().millisecondsSinceEpoch;
            }
            await _bookDao.insertOrUpdate(info);
            await _chapterDao.insertChapters(chapters);
          }
        } catch (_) {}
        completed++;
        _updatingCount = onlineBooks.length - completed;
        notifyListeners();
      }));
    }

    await Future.wait(updateTasks);
    _updatingCount = 0;
    await loadBooks();
    AppEventBus().fire(AppEvent('bookshelfRefreshEnd'));
  }

  Future<void> importLocalBookPath(String path) async {
    final file = File(path);
    final ext = path.split('.').last.toLowerCase();
    final bookUrl = "local://${file.path}";

    final existingBook = await _bookDao.getByUrl(bookUrl);
    if (existingBook != null && existingBook.isInBookshelf) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (ext == 'txt') {
        final parser = TxtParser(file);
        await parser.load();
        final chaptersData = await parser.splitChapters();
        final book = Book(bookUrl: bookUrl, name: p.basenameWithoutExtension(path), author: '本地', origin: 'local', originName: '本地', isInBookshelf: true, type: 0);
        await _bookDao.insertOrUpdate(book);
        final List<BookChapter> bookChapters = [];
        final List<Map<String, dynamic>> bookContents = [];
        for (int i = 0; i < chaptersData.length; i++) {
          bookChapters.add(BookChapter(url: "$bookUrl#$i", title: chaptersData[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
          bookContents.add({'bookUrl': bookUrl, 'chapterIndex': i, 'content': chaptersData[i]['content'] ?? ""});
        }
        await _chapterDao.insertChapters(bookChapters);
        await _chapterDao.insertContents(bookContents);
      } else if (ext == 'epub') {
        final parser = EpubParser(file);
        await parser.load();
        final book = Book(bookUrl: bookUrl, name: parser.title, author: parser.author, origin: "local", originName: "本地", isInBookshelf: true, type: 1);
        await _bookDao.insertOrUpdate(book);
        final chapters = parser.getChapters();
        final List<BookChapter> bookChapters = [];
        for (int i = 0; i < chapters.length; i++) {
          bookChapters.add(BookChapter(url: chapters[i]['href'] ?? "", title: chapters[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
        }
        await _chapterDao.insertChapters(bookChapters);
      }
      await loadBooks();
    } catch (e) {
      debugPrint('匯入本地書籍失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importBookshelfFromUrl(String url) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Dio().get(url);
      final List<dynamic> decoded = response.data is List ? response.data : jsonDecode(response.data);
      final sources = await _sourceDao.getEnabled();
      for (var item in decoded) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? "";
        final author = item['author']?.toString() ?? "";
        if (name.isEmpty) continue;
        final searchResults = await _service.preciseSearch(sources, name, author);
        if (searchResults.isNotEmpty) {
          final bestMatch = searchResults.first;
          final newBook = bestMatch.toBook().copyWith(isInBookshelf: true);
          await _bookDao.insertOrUpdate(newBook);
        }
      }
      await loadBooks();
    } catch (e) { 
      debugPrint('從 URL 匯入書架失敗: $e'); 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 分組管理對位方法 ---
  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = _groups.where((g) => g.groupId > 0).toList();
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await _groupDao.updateOrder(list);
    await loadGroups();
  }

  Future<void> updateGroupVisibility(int groupId, bool v) async {
    final g = await _groupDao.getById(groupId);
    if (g != null) {
      g.show = v;
      await _groupDao.update(g);
      await loadGroups();
    }
  }

  Future<void> createGroup(String name, {String? coverPath}) async {
    await _groupDao.insert(BookGroup(groupName: name, coverPath: coverPath));
    await loadGroups();
  }

  Future<void> renameGroup(int groupId, String name, {String? coverPath}) async {
    final g = await _groupDao.getById(groupId);
    if (g != null) {
      g.groupName = name;
      if (coverPath != null) g.coverPath = coverPath;
      await _groupDao.update(g);
      await loadGroups();
    }
  }

  Future<void> deleteGroup(int groupId) async {
    await _groupDao.deleteById(groupId);
    await loadGroups();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
