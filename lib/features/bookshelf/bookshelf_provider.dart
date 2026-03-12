import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:pool/pool.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/database/dao/book_group_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/models/book.dart';
import '../../core/models/book_group.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';
import '../../core/local_book/txt_parser.dart';
import '../../core/local_book/epub_parser.dart';
import '../../core/engine/app_event_bus.dart';

class BookshelfProvider extends ChangeNotifier {
  final BookDao _bookDao = BookDao();
  final BookGroupDao _groupDao = BookGroupDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final BookSourceService _service = BookSourceService();
  StreamSubscription? _eventSub;

  List<Book> _books = [];
  List<BookGroup> _groups = [];
  int _currentGroupId = -1; // -1 表示全部
  bool _isLoading = false;
  int _updatingCount = 0;
  bool _isBatchMode = false;
  final Set<String> _selectedBookUrls = {};
  
  // 配置項
  bool isGridLayout = true;
  bool showUnread = true;
  bool showLastUpdate = false;

  List<Book> get books => _books;
  List<BookGroup> get groups => _groups;
  int get currentGroupId => _currentGroupId;
  bool get isLoading => _isLoading;
  int get updatingCount => _updatingCount;
  bool get isBatchMode => _isBatchMode;
  Set<String> get selectedBookUrls => _selectedBookUrls;

  BookshelfProvider() {
    _init();
    _eventSub = AppEventBus().onName(AppEventBus.upBookshelf).listen((_) => loadBooks());
  }

  int _sortMode = 0; // 0:手動, 1:最後閱讀, 2:最晚更新, 3:書名, 4:作者
  int get sortMode => _sortMode;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    isGridLayout = prefs.getBool('bookshelf_is_grid') ?? true;
    showUnread = prefs.getBool('bookshelf_show_unread') ?? true;
    showLastUpdate = prefs.getBool('bookshelf_show_last_update') ?? false;
    _sortMode = prefs.getInt('bookshelf_sort_mode') ?? 0;
    
    await loadGroups();
    await loadBooks();
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
    
    List<Book> allBooks = await _bookDao.getAllInBookshelf();
    
    // 1. 分組過濾 (位運算，比照 Android)
    if (_currentGroupId > 0) {
      allBooks = allBooks.where((b) => (b.group & _currentGroupId) != 0).toList();
    } else if (_currentGroupId == -1) { // 未分組
      allBooks = allBooks.where((b) => b.group == 0).toList();
    }
    
    // 2. 排序邏輯 (深度還原 Android 排序)
    switch (_sortMode) {
      case 1: // 最後閱讀
        allBooks.sort((a, b) => b.durChapterTime.compareTo(a.durChapterTime));
        break;
      case 2: // 最晚更新
        allBooks.sort((a, b) => b.latestChapterTime.compareTo(a.latestChapterTime));
        break;
      case 3: // 書名
        allBooks.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 4: // 作者
        allBooks.sort((a, b) => a.author.compareTo(b.author));
        break;
      default: // 手動
        allBooks.sort((a, b) => a.order.compareTo(b.order));
        break;
    }

    _books = allBooks;
    _isLoading = false;
    notifyListeners();
  }

  // --- UI 輔助方法 (修復報錯) ---
  void toggleLayout() {
    isGridLayout = !isGridLayout;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_is_grid', isGridLayout));
    notifyListeners();
  }

  void toggleShowUnread() {
    showUnread = !showUnread;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_show_unread', showUnread));
    notifyListeners();
  }

  void toggleShowLastUpdate() {
    showLastUpdate = !showLastUpdate;
    SharedPreferences.getInstance().then((p) => p.setBool('bookshelf_show_last_update', showLastUpdate));
    notifyListeners();
  }

  void toggleBatchMode([String? firstBookUrl]) {
    _isBatchMode = !_isBatchMode;
    _selectedBookUrls.clear();
    if (_isBatchMode && firstBookUrl != null) {
      _selectedBookUrls.add(firstBookUrl);
    }
    notifyListeners();
  }

  void clearSelected() {
    _selectedBookUrls.clear();
    _isBatchMode = false;
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

  void setSelected(String url, bool selected) {
    if (selected) {
      _selectedBookUrls.add(url);
    } else {
      _selectedBookUrls.remove(url);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedBookUrls.addAll(_books.map((b) => b.bookUrl));
    notifyListeners();
  }

  // --- 業務方法 (修復報錯) ---
  Future<void> deleteSelected() async {
    for (var url in _selectedBookUrls) {
      await _bookDao.deleteByUrl(url);
    }
    _isBatchMode = false;
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
    await loadBooks();
  }

  Future<void> createGroup(String name, {String? coverPath}) async {
    final group = BookGroup(groupId: DateTime.now().millisecondsSinceEpoch, groupName: name, coverPath: coverPath, show: true, order: 0);
    await _groupDao.insert(group);
    await loadGroups();
  }

  Future<void> renameGroup(int id, String name, {String? coverPath}) async {
    final group = await _groupDao.getById(id);
    if (group != null) {
      group.groupName = name;
      group.coverPath = coverPath;
      await _groupDao.update(group);
      await loadGroups();
    }
  }

  Future<void> deleteGroup(int id) async {
    await _groupDao.deleteById(id);
    await loadGroups();
    await loadBooks();
  }

  Future<void> reorderGroups(int oldIdx, int newIdx) async {
    // 深度還原：過濾出可排序的自定義分組
    final customGroups = _groups.where((g) => g.groupId > 0).toList();
    if (oldIdx < newIdx) newIdx -= 1;
    
    final movedGroup = customGroups.removeAt(oldIdx);
    customGroups.insert(newIdx, movedGroup);
    
    // 重新計算並更新所有分組的 Order
    for (int i = 0; i < customGroups.length; i++) {
      customGroups[i].order = i;
      await _groupDao.update(customGroups[i]);
    }
    await loadGroups();
  }

  void updateGroupVisibility(int id, bool show) async {
    final group = await _groupDao.getById(id);
    if (group != null) {
      group.show = show;
      await _groupDao.update(group);
      await loadGroups();
    }
  }

  Future<void> refreshBookshelf() async {
    AppEventBus().fire(AppEventBus.bookshelfRefreshStart);
    try {
      final disabledGroups = _groups.where((g) => !g.enableRefresh).map((g) => g.groupId).toSet();
      final onlineBooks = _books.where((b) => b.origin != 'local' && !disabledGroups.contains(b.group)).toList();

      _updatingCount = onlineBooks.length;
      notifyListeners();

      final threadCount = await SharedPreferences.getInstance().then((p) => p.getInt('thread_count') ?? 8);
      final updatePool = Pool(threadCount); 
      int completed = 0;
      final List<Future<void>> updateTasks = [];

      for (var book in onlineBooks) {
        updateTasks.add(updatePool.withResource(() async {
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
          completed++;
          _updatingCount = onlineBooks.length - completed;
          notifyListeners();
        }));
      }

      await Future.wait(updateTasks);
      _updatingCount = 0;
      await loadBooks();
    } finally {
      AppEventBus().fire(AppEventBus.bookshelfRefreshEnd);
    }
  }

  Future<void> importLocalBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub'],
    );

    if (result == null || result.files.single.path == null) return;
    return importLocalBookPath(result.files.single.path!);
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
      late Book book;
      if (ext == 'txt') {
        final parser = TxtParser(file);
        await parser.load();
        final chaptersData = await parser.splitChapters();
        book = Book(bookUrl: bookUrl, name: p.basenameWithoutExtension(path), origin: 'local', originName: '本地', isInBookshelf: true, type: 0);
        await _bookDao.insertOrUpdate(book);
        final List<BookChapter> bookChapters = [];
        final List<Map<String, dynamic>> bookContents = [];
        for (int i = 0; i < chaptersData.length; i++) {
          bookChapters.add(BookChapter(url: "$bookUrl#$i", title: chaptersData[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
          bookContents.add({'bookUrl': bookUrl, 'chapterIndex': i, 'content': chaptersData[i]['content'] ?? ""});
        }
        await ChapterDao().insertChapters(bookChapters);
        await ChapterDao().insertContents(bookContents);
      } else if (ext == 'epub') {
        final parser = EpubParser(file);
        await parser.load();
        book = Book(bookUrl: bookUrl, name: parser.title, author: parser.author, origin: "local", originName: "本地", isInBookshelf: true, type: 1);
        await _bookDao.insertOrUpdate(book);
        final chapters = parser.getChapters();
        final List<BookChapter> bookChapters = [];
        for (int i = 0; i < chapters.length; i++) {
          bookChapters.add(BookChapter(url: chapters[i]['href'] ?? "", title: chapters[i]['title'] ?? "第 $i 章", bookUrl: bookUrl, index: i));
        }
        await ChapterDao().insertChapters(bookChapters);
      }
      await loadBooks();
    } catch (e) {
      debugPrint('匯入本地書籍失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportBookshelf() async {
    try {
      final List<Map<String, String>> exportList = _books.map((b) => {"name": b.name, "author": b.author, "intro": b.intro ?? ""}).toList();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bookshelf.json');
      await file.writeAsString(jsonEncode(exportList));
      await Share.shareXFiles([XFile(file.path)], text: 'Exported Bookshelf');
    } catch (e) { debugPrint('匯出書架失敗: $e'); }
  }

  Future<void> importBookshelfFromUrl(String url) async {
    _isLoading = true;
    notifyListeners();
    try {
      final input = url.trim();
      if (input.startsWith('http') && !input.contains('[')) {
        // 單個書籍 URL 匯入
        final uri = Uri.parse(input);
        final baseUrl = "${uri.scheme}://${uri.host}";
        final sources = await _sourceDao.getEnabled();
        
        // 尋找匹配書源 (比照 Android NetworkUtils.getBaseUrl 邏輯)
        BookSource? source = sources.cast<BookSource?>().firstWhere(
          (s) => s?.bookSourceUrl.contains(baseUrl) ?? false, 
          orElse: () => null
        );

        if (source == null) {
          // 嘗試使用 bookUrlPattern 匹配
          for (var s in sources) {
            if (s.bookUrlPattern != null && RegExp(s.bookUrlPattern!).hasMatch(input)) {
              source = s;
              break;
            }
          }
        }

        if (source != null) {
          var book = Book(bookUrl: input, name: "加載中...", author: "", origin: source.bookSourceUrl, originName: source.bookSourceName, isInBookshelf: true);
          book = await _service.getBookInfo(source, book);
          final chapters = await _service.getChapterList(source, book);
          
          await _bookDao.insertOrUpdate(book);
          await ChapterDao().insertChapters(chapters);
          await loadBooks();
        }
      } else {
        // 原有 JSON 陣列匯入
        final response = await Dio().get(input);
        if (response.data != null) {
          final jsonStr = response.data is String ? response.data : jsonEncode(response.data);
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
              final newBook = bestMatch.toBook().copyWith(isInBookshelf: true);
              await _bookDao.insertOrUpdate(newBook);
            }
          }
          await loadBooks();
        }
      }
    } catch (e) { 
      debugPrint('從 URL 匯入書架失敗: $e'); 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
