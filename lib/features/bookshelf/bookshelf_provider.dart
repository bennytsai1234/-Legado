import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/base/base_provider.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/book_group_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/book_group.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';
import '../../core/local_book/epub_parser.dart';
import '../../core/local_book/txt_parser.dart';
import '../../core/engine/app_event_bus.dart';

class BookshelfProvider extends BaseProvider {
  final BookDao _bookDao = BookDao();
  final BookGroupDao _groupDao = BookGroupDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();

  List<Book> _books = [];
  List<BookGroup> _groups = [];
  int _currentGroupId = BookGroup.idAll;
  int _sortType = 0; // 0: order, 1: latestChapter, 2: lastRead

  bool _isBatchMode = false;
  final Set<String> _selectedBookUrls = {};
  StreamSubscription? _eventSub;

  bool _isGridLayout = true;
  bool _showUnread = true;
  bool _showLastUpdate = true;

  List<Book> get books => _books;
  List<BookGroup> get groups => _groups;
  int get currentGroupId => _currentGroupId;
  int get sortType => _sortType;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedBookUrls => _selectedBookUrls;
  bool get isGridLayout => _isGridLayout;
  bool get showUnread => _showUnread;
  bool get showLastUpdate => _showLastUpdate;

  BookshelfProvider() {
    _loadLayout();
    loadGroups();
    loadBooks();
    _initEventBus();
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    _isGridLayout = prefs.getBool('bookshelf_is_grid') ?? true;
    _showUnread = prefs.getBool('bookshelf_show_unread') ?? true;
    _showLastUpdate = prefs.getBool('bookshelf_show_last_update') ?? true;
    notifyListeners();
  }

  void toggleLayout() async {
    _isGridLayout = !_isGridLayout;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bookshelf_is_grid', _isGridLayout);
  }

  void toggleShowUnread() async {
    _showUnread = !_showUnread;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bookshelf_show_unread', _showUnread);
  }

  void toggleShowLastUpdate() async {
    _showLastUpdate = !_showLastUpdate;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bookshelf_show_last_update', _showLastUpdate);
  }

  void _initEventBus() {
    _eventSub = AppEventBus().onName(AppEventBus.upBookshelf).listen((event) {
      loadBooks();
    });
  }

  Future<void> loadGroups() async {
    _groups = await _groupDao.getAll();
    notifyListeners();
  }

  void setGroup(int groupId) {
    if (_currentGroupId != groupId) {
      _currentGroupId = groupId;
      loadBooks();
    }
  }

  void setSortType(int type) {
    _sortType = type;
    loadBooks();
  }

  Future<void> loadBooks() async {
    await runTask(() async {
      String? orderBy;
      switch (_sortType) {
        case 1: orderBy = 'latestChapterTime DESC'; break;
        case 2: orderBy = 'durChapterTime DESC'; break;
        default: orderBy = '"order" ASC'; break;
      }

      int queryGroupId = _currentGroupId;
      _books = await _bookDao.getBookshelf(groupId: queryGroupId, orderBy: orderBy);
    });
  }

  Future<void> refreshBookshelf() async {
    await runTask(() async {
      for (var book in _books) {
        if (book.origin != 'local') {
          final source = await _sourceDao.getByUrl(book.origin);
          if (source != null) {
            try {
              final updatedBook = await _service.getBookInfo(source, book);
              final chapters = await _service.getChapterList(source, updatedBook);
              if (chapters.length > book.totalChapterNum) {
                book.lastCheckCount = chapters.length - book.totalChapterNum;
                book.totalChapterNum = chapters.length;
                book.latestChapterTitle = chapters.last.title;
                await _bookDao.insertOrUpdate(book);
                await ChapterDao().insertChapters(chapters);
              }
            } catch (e) {
              debugPrint('更新書籍 ${book.name} 失敗: $e');
            }
          }
        }
      }
      await loadBooks();
    });
  }

  void toggleBatchMode(String? initialUrl) {
    _isBatchMode = !_isBatchMode;
    _selectedBookUrls.clear();
    if (initialUrl != null) _selectedBookUrls.add(initialUrl);
    notifyListeners();
  }

  void toggleSelect(String url) {
    if (_selectedBookUrls.contains(url)) {
      _selectedBookUrls.remove(url);
    } else {
      _selectedBookUrls.add(url);
    }
    notifyListeners();
  }

  void clearSelected() {
    _isBatchMode = false;
    _selectedBookUrls.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var url in _selectedBookUrls) {
      await _bookDao.updateInBookshelf(url, false);
    }
    _isBatchMode = false;
    _selectedBookUrls.clear();
    await loadBooks();
  }

  Future<void> moveSelectedToGroup(int groupId) async {
    for (var url in _selectedBookUrls) {
      final book = await _bookDao.getByUrl(url);
      if (book != null) {
        book.group = groupId;
        await _bookDao.insertOrUpdate(book);
      }
    }
    _isBatchMode = false;
    _selectedBookUrls.clear();
    await loadBooks();
  }

  Future<void> createGroup(String name) async {
    final groupId = await _groupDao.getUnusedId();
    final group = BookGroup(groupId: groupId, groupName: name, order: _groups.length);
    await _groupDao.insert(group);
    await loadGroups();
  }

  Future<void> renameGroup(int groupId, String newName) async {
    final group = _groups.firstWhere((g) => g.groupId == groupId);
    group.groupName = newName;
    await _groupDao.update(group);
    await loadGroups();
  }

  Future<void> deleteGroup(int groupId) async {
    final group = _groups.firstWhere((g) => g.groupId == groupId);
    await _groupDao.delete(group);
    final booksInGroup = await _bookDao.getBookshelf(groupId: groupId);
    for (var b in booksInGroup) {
      b.group = 0;
      await _bookDao.insertOrUpdate(b);
    }
    await loadGroups();
    await loadBooks();
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    final customGroups = _groups.where((g) => g.groupId > 0).toList();
    if (oldIndex < newIndex) newIndex -= 1;
    final group = customGroups.removeAt(oldIndex);
    customGroups.insert(newIndex, group);
    
    // 更新資料庫順序
    for (int i = 0; i < customGroups.length; i++) {
      customGroups[i].order = i;
      await _groupDao.update(customGroups[i]);
    }
    await loadGroups();
  }

  Future<void> importLocalBook() async {
    await runTask(() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        final bookUrl = "local://${file.path}";

        final existingBook = await _bookDao.getByUrl(bookUrl);
        if (existingBook != null && existingBook.isInBookshelf) return;

        late Book book;
        final List<BookChapter> bookChapters = [];
        final List<Map<String, dynamic>> bookContents = [];
        final ChapterDao chapterDao = ChapterDao();

        int groupValue = _currentGroupId > 0 ? _currentGroupId : 0;

        if (ext == 'epub') {
          final parser = EpubParser(file);
          await parser.load();
          book = Book(bookUrl: bookUrl, name: parser.title, author: parser.author, origin: "local", originName: "本地書籍", isInBookshelf: true, coverUrl: file.path, group: groupValue, type: 1);
          final chapters = parser.getChapters();
          for (int i = 0; i < chapters.length; i++) {
            final chapterUrl = chapters[i]['href'] ?? "";
            bookChapters.add(BookChapter(url: chapterUrl, title: chapters[i]['title'] ?? "Unnamed Chapter", bookUrl: bookUrl, index: i));
            bookContents.add({'bookUrl': bookUrl, 'chapterIndex': i, 'content': parser.getChapterContent(chapterUrl)});
          }
          book.totalChapterNum = chapters.length;
        } else if (ext == 'txt') {
          final parser = TxtParser(file);
          await parser.load();
          book = Book(bookUrl: bookUrl, name: file.uri.pathSegments.last.replaceAll('.txt', '').replaceAll('.TXT', ''), author: "Unknown Author", origin: "local", originName: "本地書籍", isInBookshelf: true, group: groupValue, type: 1);
          final chapters = parser.splitChapters();
          for (int i = 0; i < chapters.length; i++) {
            bookChapters.add(BookChapter(url: "local_index_$i", title: chapters[i]['title'] ?? "Unnamed Chapter", bookUrl: bookUrl, index: i));
            bookContents.add({'bookUrl': bookUrl, 'chapterIndex': i, 'content': chapters[i]['content'] ?? ""});
          }
          book.totalChapterNum = chapters.length;
        } else return;

        await _bookDao.insertOrUpdate(book);
        await chapterDao.insertChapters(bookChapters);
        await chapterDao.insertContents(bookContents);
        await loadBooks();
      }
    });
  }

  Future<void> exportBookshelf() async {
    await runTask(() async {
      try {
        final List<Map<String, String>> exportList = _books.map((b) => {"name": b.name, "author": b.author ?? "", "intro": b.intro ?? ""}).toList();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/bookshelf.json');
        await file.writeAsString(jsonEncode(exportList));
        await Share.shareXFiles([XFile(file.path)], text: 'Exported Bookshelf');
      } catch (e) { debugPrint('匯出書架失敗: $e'); }
    });
  }

  Future<void> importBookshelfFromJson(String jsonStr, {int groupId = 0}) async {
    await runTask(() async {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final sources = await _sourceDao.getEnabled();
        for (var item in decoded) {
          if (item is! Map) continue;
          final name = item['name']?.toString() ?? "";
          final author = item['author']?.toString() ?? "";
          if (name.isEmpty) continue;
          final searchResults = await _service.preciseSearch(sources, name, author);
          if (searchResults.isNotEmpty) {
            final bestMatch = searchResults.first;
            final newBook = Book(bookUrl: bestMatch.bookUrl, name: bestMatch.name, author: bestMatch.author ?? "", origin: bestMatch.origin, originName: bestMatch.originName ?? "", isInBookshelf: true, group: groupId > 0 ? groupId : _currentGroupId);
            await _bookDao.insertOrUpdate(newBook);
          }
        }
        await loadBooks();
      } catch (e) { debugPrint('匯入書架失敗: $e'); }
    });
  }

  Future<void> importBookshelfFromUrl(String url, {int groupId = 0}) async {
    await runTask(() async {
      try {
        final response = await Dio().get(url);
        if (response.data != null) {
           final jsonStr = response.data is String ? response.data : jsonEncode(response.data);
           await importBookshelfFromJson(jsonStr, groupId: groupId);
        }
      } catch (e) { debugPrint('從 URL 匯入書架失敗: $e'); }
    });
  }

  @override
  void dispose() { _eventSub?.cancel(); super.dispose(); }
}
