import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/search_book.dart';
import '../models/book_source.dart';
import '../engine/analyze_rule.dart';
import '../engine/analyze_url.dart';
import 'rate_limiter.dart';

/// BookSourceService - 書源業務服務
/// 整合解析引擎與業務流程
class BookSourceService {
  
  /// 搜尋書籍
  Future<List<SearchBook>> searchBooks(
    BookSource source,
    String keyword, {
    int page = 1,
  }) async {
    final searchUrl = source.searchUrl;
    if (searchUrl == null || searchUrl.isEmpty) return [];

    final limiter = ConcurrentRateLimiter(source);
    return await limiter.withLimit(() async {
      final analyzeRule = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        searchUrl,
        key: keyword,
        page: page,
        baseUrl: source.bookSourceUrl,
        analyzer: analyzeRule,
      );

      final resBody = await analyzeUrl.getResponseBody();
      if (resBody.isEmpty) return [];

      return _analyzeBookList(source, resBody, analyzeUrl.url, isSearch: true);
    });
  }

  /// 獲取書籍詳情
  Future<Book> getBookInfo(BookSource source, Book book) async {
    final limiter = ConcurrentRateLimiter(source);
    return await limiter.withLimit(() async {
      final analyzeRule = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        book.bookUrl,
        baseUrl: source.bookSourceUrl,
        analyzer: analyzeRule,
      );

      final resBody = await analyzeUrl.getResponseBody();
      if (resBody.isEmpty) return book;

      final rule = analyzeRule.setContent(resBody, baseUrl: analyzeUrl.url);
      final infoRule = source.ruleBookInfo;
      if (infoRule != null) {
        if (infoRule.init != null && infoRule.init!.isNotEmpty) {
          rule.setContent(rule.getElements(infoRule.init!));
        }
        book.name = rule.getString(infoRule.name ?? "") ?? book.name;
        book.author = rule.getString(infoRule.author ?? "") ?? book.author;
        book.kind = rule.getStringList(infoRule.kind ?? "").join(',');
        book.coverUrl = rule.getString(infoRule.coverUrl ?? "", isUrl: true);
        book.intro = rule.getString(infoRule.intro ?? "");
        book.latestChapterTitle = rule.getString(infoRule.lastChapter ?? "");
        book.tocUrl = rule.getString(infoRule.tocUrl ?? "", isUrl: true);
        if (book.tocUrl.isEmpty) book.tocUrl = book.bookUrl;
      }
      return book;
    });
  }

  /// 獲取章節目錄 (支援翻頁)
  Future<List<BookChapter>> getChapterList(BookSource source, Book book) async {
    final chapters = <BookChapter>[];
    String? nextUrl = book.tocUrl.isEmpty ? book.bookUrl : book.tocUrl;

    while (nextUrl != null && nextUrl.isNotEmpty) {
      final res = await _fetchChapterPage(source, book, nextUrl);
      chapters.addAll(res.chapters);
      nextUrl = res.nextUrl;
      
      // 防止死循環或過多翻頁 (Legado 預設通常也有限制)
      if (chapters.length > 5000) break; 
    }
    return chapters;
  }

  Future<({List<BookChapter> chapters, String? nextUrl})> _fetchChapterPage(
    BookSource source,
    Book book,
    String url,
  ) async {
    final limiter = ConcurrentRateLimiter(source);
    return await limiter.withLimit(() async {
      final analyzeRule = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        url,
        baseUrl: source.bookSourceUrl,
        analyzer: analyzeRule,
      );

      final resBody = await analyzeUrl.getResponseBody();
      if (resBody.isEmpty) return (chapters: <BookChapter>[], nextUrl: null);

      final rule = analyzeRule.setContent(resBody, baseUrl: analyzeUrl.url);
      final tocRule = source.ruleToc;
      if (tocRule == null) return (chapters: <BookChapter>[], nextUrl: null);

      final elements = rule.getElements(tocRule.chapterList ?? "");
      final List<BookChapter> pageChapters = [];

      for (int i = 0; i < elements.length; i++) {
        final itemRule = AnalyzeRule(source: source).setContent(elements[i], baseUrl: analyzeUrl.url);
        pageChapters.add(BookChapter(
          url: itemRule.getString(tocRule.chapterUrl ?? "", isUrl: true),
          title: itemRule.getString(tocRule.chapterName ?? ""),
          index: i,
          bookUrl: book.bookUrl,
        ));
      }

      String? nextTocUrl = rule.getString(tocRule.nextTocUrl ?? "", isUrl: true);
      if (nextTocUrl == url) nextTocUrl = null; // 避免原地踏步

      return (chapters: pageChapters, nextUrl: nextTocUrl);
    });
  }

  /// 獲取正文內容
  Future<String> getContent(BookSource source, Book book, BookChapter chapter) async {
    final limiter = ConcurrentRateLimiter(source);
    return await limiter.withLimit(() async {
      final analyzeRule = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        chapter.url,
        baseUrl: book.bookUrl,
        analyzer: analyzeRule,
      );

      final resBody = await analyzeUrl.getResponseBody();
      if (resBody.isEmpty) return "";

      final rule = analyzeRule.setContent(resBody, baseUrl: analyzeUrl.url);
      final contentRule = source.ruleContent;
      if (contentRule == null) return "";

      return rule.getString(contentRule.content ?? "");
    });
  }

  List<SearchBook> _analyzeBookList(
    BookSource source,
    String body,
    String baseUrl, {
    required bool isSearch,
  }) {
    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final listRule = isSearch ? source.ruleSearch : source.ruleExplore;
    if (listRule == null) return [];

    final elements = rule.getElements(listRule.bookList ?? "");
    final books = <SearchBook>[];

    for (final element in elements) {
      final itemRule = AnalyzeRule(source: source).setContent(element, baseUrl: baseUrl);
      books.add(SearchBook(
        bookUrl: itemRule.getString(listRule.bookUrl ?? "", isUrl: true),
        name: itemRule.getString(listRule.name ?? "") ?? "Unknown",
        author: itemRule.getString(listRule.author ?? ""),
        kind: itemRule.getStringList(listRule.kind ?? "").join(','),
        coverUrl: itemRule.getString(listRule.coverUrl ?? "", isUrl: true),
        intro: itemRule.getString(listRule.intro ?? ""),
        latestChapterTitle: itemRule.getString(listRule.lastChapter ?? ""),
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
      ));
    }

    return books;
  }
}
