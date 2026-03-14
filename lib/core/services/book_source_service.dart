import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/engine/web_book/book_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/book_info_parser.dart';
import 'package:legado_reader/core/engine/web_book/chapter_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/content_parser.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/services/http_client.dart';


/// BookSourceService - 書源服務 (對標 Android model/webBook/WebBook.kt)
/// 負責發起網路請求並委派解析器處理數據
class BookSourceService {

  Future<List<SearchBook>> searchBooks(BookSource source, String keyword, {int page = 1}) async {
    final analyzeUrl = AnalyzeUrl(
      source.searchUrl ?? "",
      source: source,
      key: keyword,
      page: page,
    );
    
    // 執行登入檢查 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();

    
    final body = await analyzeUrl.getResponseBody();
    return BookListParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
      isSearch: true,
    );
  }

  Future<List<SearchBook>> exploreBooks(BookSource source, String url, {int page = 1}) async {
    final analyzeUrl = AnalyzeUrl(url, source: source, page: page);
    
    // 執行登入檢查 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();
    
    final body = await analyzeUrl.getResponseBody();

    return BookListParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
      isSearch: false,
    );
  }

  Future<Book> getBookInfo(BookSource source, Book book) async {
    final analyzeUrl = AnalyzeUrl(book.bookUrl, source: source);
    
    // 執行登入檢查 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();
    
    final body = await analyzeUrl.getResponseBody();

    return BookInfoParser.parse(
      source: source,
      book: book,
      body: body,
      baseUrl: analyzeUrl.url,
    );
  }

  Future<List<BookChapter>> getChapterList(BookSource source, Book book) async {
    final analyzeUrl = AnalyzeUrl(book.tocUrl, source: source);
    
    // 執行登入檢查與目錄預整理 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();
    await rule.preUpdateToc();
    
    final body = await analyzeUrl.getResponseBody();

    return ChapterListParser.parse(
      source: source,
      book: book,
      body: body,
      baseUrl: analyzeUrl.url,
    );
  }

  Future<String> getContent(BookSource source, Book book, BookChapter chapter, {String? nextChapterUrl}) async {
    final analyzeUrl = AnalyzeUrl(chapter.url, source: source);
    
    // 執行登入檢查 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();
    
    final body = await analyzeUrl.getResponseBody();

    return ContentParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
    );
  }

  /// 精準搜尋 (對標 Android WebBook.preciseSearchAwait)
  Future<List<SearchBook>> preciseSearch(List<BookSource> sources, String name, String author) async {
    final List<SearchBook> results = [];
    for (final source in sources) {
      try {
        final books = await searchBooks(source, name);
        final match = books.where((b) => b.name == name && (author.isEmpty || (b.author?.contains(author) ?? false) || author.contains(b.author ?? "")));
        if (match.isNotEmpty) {
          results.addAll(match);
        }
      } catch (e) {
        debugPrint("Precise search failed for ${source.bookSourceName}: $e");
      }
    }
    return results;
  }

  Future<List<Book>> importBookshelf(String url) async {
    try {
      final response = await HttpClient().client.get(url);
      if (response.data is List) {
        return (response.data as List).map((e) => Book.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
