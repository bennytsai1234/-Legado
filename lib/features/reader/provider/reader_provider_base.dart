import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

/// ReaderProvider 的基礎狀態與 DAO 定義
abstract class ReaderProviderBase extends ChangeNotifier {
  final BookDao bookDao = BookDao();
  final ChapterDao chapterDao = ChapterDao();
  final ReplaceRuleDao replaceDao = ReplaceRuleDao();
  final BookSourceDao sourceDao = BookSourceDao();
  final BookSourceService service = BookSourceService();
  final BookmarkDao bookmarkDao = BookmarkDao();
  final StreamController<int> jumpPageController = StreamController<int>.broadcast();

  final Book book;
  BookSource? source;
  List<BookChapter> chapters = [];
  int currentChapterIndex = 0;
  int currentPageIndex = 0;
  String content = "";
  List<TextPage> pages = [];
  Size? viewSize;
  bool isLoading = false;
  bool showControls = false;
  int scrubbingChapterIndex = -1;

  final Map<int, List<TextPage>> chapterCache = {};
  final Map<int, String> chapterContentCache = {};
  bool isPreloading = false;
  List<Bookmark> bookmarks = [];

  ReaderProviderBase(this.book);

  @override
  void dispose() {
    jumpPageController.close();
    super.dispose();
  }
}
