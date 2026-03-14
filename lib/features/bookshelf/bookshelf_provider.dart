import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider/bookshelf_provider_base.dart';
import 'provider/bookshelf_logic_mixin.dart';
import 'provider/bookshelf_update_mixin.dart';
import 'provider/bookshelf_import_mixin.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/services/event_bus.dart';

export 'provider/bookshelf_provider_base.dart';
export 'provider/bookshelf_logic_mixin.dart';
export 'provider/bookshelf_update_mixin.dart';
export 'provider/bookshelf_import_mixin.dart';

/// BookshelfProvider - 書架狀態管理 (重構後)
/// 對應 Android: ui/main/MainViewModel.kt
class BookshelfProvider extends BookshelfProviderBase with BookshelfLogicMixin, BookshelfUpdateMixin, BookshelfImportMixin {
  StreamSubscription? _eventSub;

  BookshelfProvider() {
    _init();
    _eventSub = AppEventBus().onName(AppEventBus.upBookshelf).listen((_) => loadBooks());
    AppEventBus().onName('importLocalBook').listen((e) { if (e.data is String) importLocalBookPath(e.data); });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    isGridView = prefs.getBool('bookshelf_is_grid') ?? true;
    showUnread = prefs.getBool('bookshelf_show_unread') ?? true;
    showLastUpdate = prefs.getBool('bookshelf_show_last_update') ?? false;
    sortMode = prefs.getInt('bookshelf_sort_mode') ?? 0;
    await loadGroups();
    await loadBooks();
  }

  Future<void> setSortMode(int mode) async {
    sortMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookshelf_sort_mode', mode);
    await loadBooks();
  }

  Future<void> setGroup(int groupId) async {
    currentGroupId = groupId;
    await loadBooks();
  }

  Future<void> loadBooks() async {
    isLoading = true; notifyListeners();
    try {
      List<Book> allBooks = await bookDao.getAllInBookshelf();
      if (currentGroupId > 0) {
        allBooks = allBooks.where((b) => (b.group & currentGroupId) != 0).toList();
      } else if (currentGroupId == 0) {
        allBooks = allBooks.where((b) => b.group == 0).toList();
      }
      
      switch (sortMode) {
        case 1: allBooks.sort((a, b) => b.durChapterTime.compareTo(a.durChapterTime)); break;
        case 2: allBooks.sort((a, b) => b.latestChapterTime.compareTo(a.latestChapterTime)); break;
        case 3: allBooks.sort((a, b) => a.name.compareTo(b.name)); break;
        case 4: allBooks.sort((a, b) => a.author.compareTo(b.author)); break;
        default: allBooks.sort((a, b) => a.order.compareTo(b.order)); break;
      }
      books = allBooks;
    } finally { isLoading = false; notifyListeners(); }
  }

  @override void dispose() { _eventSub?.cancel(); super.dispose(); }
}
