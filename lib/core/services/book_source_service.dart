import '../models/book.dart';
import '../models/chapter.dart';
import '../models/search_book.dart';
import '../models/book_source.dart';
import '../engine/analyze_rule.dart';
import '../engine/analyze_url.dart';

/// BookSourceService - 書源業務服務
/// 對應 Android: model/webBook/WebBook.kt 及其附屬類別
class BookSourceService {
  
  /// 搜尋書籍
  Future<List<SearchBook>> searchBooks(
    BookSource source,
    String keyword, {
    int page = 1,
  }) async {
    final searchUrl = source.searchUrl;
    if (searchUrl == null || searchUrl.isEmpty) return [];

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
  }

  /// 發現頁書籍
  Future<List<SearchBook>> exploreBooks(
    BookSource source,
    String url, {
    int page = 1,
  }) async {
    final analyzeRule = AnalyzeRule(source: source);
    final analyzeUrl = AnalyzeUrl(
      url,
      page: page,
      baseUrl: source.bookSourceUrl,
      analyzer: analyzeRule,
    );

    final resBody = await analyzeUrl.getResponseBody();
    if (resBody.isEmpty) return [];

    return _analyzeBookList(source, resBody, analyzeUrl.url, isSearch: false);
  }

  /// 獲取書籍詳情
  Future<Book> getBookInfo(BookSource source, Book book) async {
    final analyzeRule = AnalyzeRule(source: source);
    final analyzeUrl = AnalyzeUrl(
      book.bookUrl,
      baseUrl: source.bookSourceUrl,
      analyzer: analyzeRule,
    );

    final resBody = await analyzeUrl.getResponseBody();
    if (resBody.isEmpty) return book;

    final rule = AnalyzeRule(source: source).setContent(resBody, baseUrl: analyzeUrl.url);
    
    // 解析詳情欄位
    final infoRule = source.ruleBookInfo as BookInfoRule?;
    if (infoRule != null) {
      book.name = rule.getString(infoRule.name ?? "") ?? book.name;
      book.author = rule.getString(infoRule.author ?? "") ?? book.author;
      book.kind = rule.getString(infoRule.kind ?? "") ?? book.kind;
      book.coverUrl = rule.getString(infoRule.coverUrl ?? "") ?? book.coverUrl;
      book.intro = rule.getString(infoRule.intro ?? "") ?? book.intro;
      book.latestChapterTitle = rule.getString(infoRule.lastChapter ?? "") ?? book.latestChapterTitle;
    }
    
    return book;
  }

  /// 獲取章節目錄
  Future<List<BookChapter>> getChapterList(BookSource source, Book book) async {
    final tocUrl = book.tocUrl.isEmpty ? book.bookUrl : book.tocUrl;
    final analyzeRule = AnalyzeRule(source: source);
    final analyzeUrl = AnalyzeUrl(
      tocUrl,
      baseUrl: source.bookSourceUrl,
      analyzer: analyzeRule,
    );

    final resBody = await analyzeUrl.getResponseBody();
    if (resBody.isEmpty) return [];

    final rule = AnalyzeRule(source: source).setContent(resBody, baseUrl: analyzeUrl.url);
    final tocRule = source.ruleToc as TocRule?;
    if (tocRule == null) return [];

    final elements = rule.getElements(tocRule.chapterList ?? "");
    final chapters = <BookChapter>[];

    for (int i = 0; i < elements.length; i++) {
      final itemRule = AnalyzeRule(source: source).setContent(elements[i], baseUrl: analyzeUrl.url);
      chapters.add(BookChapter(
        url: itemRule.getString(tocRule.chapterUrl ?? "") ?? "",
        title: itemRule.getString(tocRule.chapterName ?? "") ?? "",
        index: i,
        bookUrl: book.bookUrl,
      ));
    }

    return chapters;
  }

  /// 獲取正文內容
  Future<String> getContent(BookSource source, Book book, BookChapter chapter) async {
    final analyzeRule = AnalyzeRule(source: source);
    final analyzeUrl = AnalyzeUrl(
      chapter.url,
      baseUrl: book.bookUrl,
      analyzer: analyzeRule,
    );

    final resBody = await analyzeUrl.getResponseBody();
    if (resBody.isEmpty) return "";

    final rule = AnalyzeRule(source: source).setContent(resBody, baseUrl: analyzeUrl.url);
    final contentRule = source.ruleContent as ContentRule?;
    if (contentRule == null) return "";

    var content = rule.getString(contentRule.content ?? "") ?? "";
    
    return content;
  }

  /// 解析書籍列表 (搜尋或發現)
  List<SearchBook> _analyzeBookList(
    BookSource source,
    String body,
    String baseUrl, {
    required bool isSearch,
  }) {
    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final dynamic listRuleObj = isSearch ? source.ruleSearch : source.ruleExplore;
    if (listRuleObj == null) return [];

    // Cast listRule correctly based on type
    final dynamic listRule = isSearch ? (listRuleObj as SearchRule) : (listRuleObj as ExploreRule);

    final elements = rule.getElements(listRule.bookList ?? "");
    final books = <SearchBook>[];

    for (final element in elements) {
      final itemRule = AnalyzeRule(source: source).setContent(element, baseUrl: baseUrl);
      books.add(SearchBook(
        bookUrl: itemRule.getString(listRule.bookUrl ?? "") ?? "",
        name: itemRule.getString(listRule.name ?? "") ?? "Unknown",
        author: itemRule.getString(listRule.author ?? ""),
        kind: itemRule.getString(listRule.kind ?? ""),
        coverUrl: itemRule.getString(listRule.coverUrl ?? ""),
        intro: itemRule.getString(listRule.intro ?? ""),
        latestChapterTitle: itemRule.getString(listRule.lastChapter ?? ""),
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
      ));
    }

    return books;
  }
}
