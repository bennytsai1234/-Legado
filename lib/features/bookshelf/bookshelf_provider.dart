import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/base/base_provider.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/book_group_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/models/book_group.dart';
import '../../core/services/book_source_service.dart';
import '../../core/services/event_bus.dart';
import '../../core/local_book/epub_parser.dart';
import '../../core/local_book/txt_parser.dart';

class BookshelfProvider extends BaseProvider {
  final BookDao _bookDao = BookDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookGroupDao _groupDao = BookGroupDao();
  final BookSourceService _service = BookSourceService();
  StreamSubscription? _eventSub;

  List<Book> _books = [];
  // _isLoading is now handled by BaseProvider

  List<BookGroup> _groups = [];
  int _currentGroupId = BookGroup.idAll;
  int _sortType = 0; // 0: order, 1: latestChapterTime, 2: readTime

  bool _isBatchMode = false;
  Set<String> _selectedBookUrls = {};
  bool _isGridLayout = true;

  List<Book> get books => _books;
  // isLoading is now handled by BaseProvider

  List<BookGroup> get groups => _groups;
  int get currentGroupId => _currentGroupId;
  int get sortType => _sortType;

  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedBookUrls => _selectedBookUrls;
  bool get isGridLayout => _isGridLayout;

  BookshelfProvider() {
    _loadLayout();
    loadGroups();
    loadBooks();
    _initEventBus();
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    _isGridLayout = prefs.getBool('bookshelf_is_grid') ?? true;
    notifyListeners();
  }

  void toggleLayout() async {
    _isGridLayout = !_isGridLayout;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bookshelf_is_grid', _isGridLayout);
  }

  void _initEventBus() {
    _eventSub = AppEventBus().onName(AppEventBus.upBookshelf).listen((event) {
      debugPrint("BookshelfProvider: received upBookshelf event for ${event.data}");
      loadBooks();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
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
    if (_sortType != type) {
      _sortType = type;
      loadBooks();
    }
  }

  String get _currentOrderBy {
    switch (_sortType) {
      case 1:
        return 'latestChapterTime DESC';
      case 2:
        return 'durChapterTime DESC';
      default:
        return '"order" ASC, latestChapterTime DESC';
    }
  }

  Future<void> loadBooks() async {
    await runTask(() async {
      // 將 BookGroup 的 ID 轉換為 BookDao 可識別的查詢 ID (高度還原 Android 過濾)
      int queryGroupId = _currentGroupId;
      if (_currentGroupId == BookGroup.idAudio) {
        queryGroupId = -2; // BookDao 中的音訊過濾 ID
      } else if (_currentGroupId == BookGroup.idLocal) {
        queryGroupId = -3; // BookDao 中的本地過濾 ID
      } else if (_currentGroupId == BookGroup.idError) {
        queryGroupId = -4; // BookDao 中的更新錯誤過濾 ID
      }

      _books = await _bookDao.getBookshelf(
          groupId: queryGroupId, orderBy: _currentOrderBy);
    });
  }

  /// 手動排序書籍
  Future<void> reorderBook(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final book = _books.removeAt(oldIndex);
    _books.insert(newIndex, book);
    notifyListeners();

    // 更新資料庫中的排序 (非同步執行，不阻塞 UI)
    _updateAllBookOrder();
  }

  Future<void> _updateAllBookOrder() async {
    for (int i = 0; i < _books.length; i++) {
      _books[i].order = i;
      await _bookDao.updateOrder(_books[i].bookUrl, i);
    }
  }

  /// 檢查更新
  Future<void> refreshBookshelf() async {
    if (_books.isEmpty) return;

    await runTask(() async {
      final sources = await _sourceDao.getAll();
      final List<Future<void>> tasks = [];

      for (final book in _books) {
        final source = sources.cast<BookSource?>().firstWhere(
          (s) => s?.bookSourceUrl == book.origin,
          orElse: () => null,
        );
        if (source != null) {
          tasks.add(_refreshSingleBook(source, book));
        }
      }

      await Future.wait(tasks);
      await loadBooks(); // 重新加載以反映更新後的狀態
    });
  }

  Future<void> _refreshSingleBook(BookSource source, Book book) async {
    try {
      final oldLastChapter = book.latestChapterTitle;
      final updatedBook = await _service.getBookInfo(source, book, cancelToken: cancelToken);

      if (updatedBook.latestChapterTitle != oldLastChapter) {
        // 有新章節
        updatedBook.lastCheckCount = (updatedBook.lastCheckCount) + 1;
        // 清除原本的更新錯誤標記 (若有的話)
        updatedBook.type &= ~BookType.updateError;
        await _bookDao.insertOrUpdate(updatedBook);
      }
    } catch (e) {
      debugPrint('刷新書籍 ${book.name} 失敗: $e');
      // 標記為更新錯誤 (高度還原 Android)
      book.type |= BookType.updateError;
      await _bookDao.insertOrUpdate(book);
    }
  }

  Future<void> removeBook(Book book) async {
    await _bookDao.updateInBookshelf(book.bookUrl, false);
    await loadBooks();
  }

  // --- 批量管理功能 ---
  void toggleBatchMode() {
    _isBatchMode = !_isBatchMode;
    if (!_isBatchMode) {
      _selectedBookUrls.clear();
    }
    notifyListeners();
  }

  void toggleSelect(String bookUrl) {
    if (_selectedBookUrls.contains(bookUrl)) {
      _selectedBookUrls.remove(bookUrl);
    } else {
      _selectedBookUrls.add(bookUrl);
    }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedBookUrls.length == _books.length) {
      _selectedBookUrls.clear();
    } else {
      _selectedBookUrls = _books.map((b) => b.bookUrl).toSet();
    }
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
        book.group = groupId; // 修復：直接賦值 int
        await _bookDao.insertOrUpdate(book);
      }
    }
    _isBatchMode = false;
    _selectedBookUrls.clear();
    await loadBooks();
  }

  /// 建立全新群組
  Future<void> createGroup(String name) async {
    final groupId = await _groupDao.getUnusedId();
    final group = BookGroup(groupId: groupId, groupName: name);
    await _groupDao.insert(group);
    await loadGroups();
  }

  /// 匯入本地書籍
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

        // 檢查是否已匯入
        final existingBook = await _bookDao.getByUrl(bookUrl);
        if (existingBook != null && existingBook.isInBookshelf) {
          return;
        }

        late Book book;
        final List<BookChapter> bookChapters = [];
        final List<Map<String, dynamic>> bookContents = [];
        final ChapterDao chapterDao = ChapterDao();

        // 預設群組
        int groupValue = 0;
        if (_currentGroupId > 0) {
          groupValue = _currentGroupId;
        }

        if (ext == 'epub') {
          final parser = EpubParser(file);
          await parser.load();

          book = Book(
            bookUrl: bookUrl,
            name: parser.title,
            author: parser.author,
            origin: "local",
            originName: "本地書籍",
            isInBookshelf: true,
            coverUrl: file.path,
            group: groupValue,
            type: BookType.local | BookType.text,
          );

          final chapters = parser.getChapters();
          for (int i = 0; i < chapters.length; i++) {
            final chapterUrl = chapters[i]['href'] ?? "";
            bookChapters.add(
              BookChapter(
                url: chapterUrl,
                title: chapters[i]['title'] ?? "Unnamed Chapter",
                bookUrl: bookUrl,
                index: i,
              ),
            );
            final content = parser.getChapterContent(chapterUrl);
            bookContents.add({
              'bookUrl': bookUrl,
              'chapterIndex': i,
              'content': content,
            });
          }
          book.totalChapterNum = chapters.length;
        } else if (ext == 'txt') {
          final parser = TxtParser(file);
          await parser.load();

          book = Book(
            bookUrl: bookUrl,
            name: file.uri.pathSegments.last
                .replaceAll('.txt', '')
                .replaceAll('.TXT', ''),
            author: "Unknown Author",
            origin: "local",
            originName: "本地書籍",
            isInBookshelf: true,
            group: groupValue,
            type: BookType.local | BookType.text,
          );

          final chapters = parser.splitChapters();
          for (int i = 0; i < chapters.length; i++) {
            bookChapters.add(
              BookChapter(
                url: "local_index_$i",
                title: chapters[i]['title'] ?? "Unnamed Chapter",
                bookUrl: bookUrl,
                index: i,
              ),
            );
            bookContents.add({
              'bookUrl': bookUrl,
              'chapterIndex': i,
              'content': chapters[i]['content'] ?? "",
            });
          }
          book.totalChapterNum = chapters.length;
        } else {
          return;
        }

        await _bookDao.insertOrUpdate(book);
        await chapterDao.insertChapters(bookChapters);
        
        await loadBooks();
      }
    });
  }
}
