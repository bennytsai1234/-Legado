/// BookSourceService - 書源業務服務
/// 對應 Android: model/webBook/*.kt
///
/// 職責：
/// 1. 使用書源規則搜尋書籍
/// 2. 取得書籍詳情
/// 3. 取得章節目錄
/// 4. 取得章節正文
/// 5. 取得發現頁內容
library;

import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../models/search_book.dart';

// TODO: Phase 2 實作

class BookSourceService {
  final BookSource source;

  BookSourceService(this.source);

  /// Search books using this source
  /// 對應 Android: WebBook.searchBook()
  Future<List<SearchBook>> searchBooks(String keyword, {int page = 1}) async {
    // TODO: Implement
    // 1. Build search URL with AnalyzeUrl
    // 2. Fetch response
    // 3. Parse bookList with AnalyzeRule
    // 4. Extract name, author, coverUrl, etc.
    return [];
  }

  /// Get book detail info
  /// 對應 Android: WebBook.getBookInfo()
  Future<Book> getBookInfo(Book book) async {
    // TODO: Implement
    return book;
  }

  /// Get chapter list (TOC)
  /// 對應 Android: WebBook.getChapterList()
  Future<List<BookChapter>> getChapterList(Book book) async {
    // TODO: Implement
    return [];
  }

  /// Get chapter content
  /// 對應 Android: WebBook.getContent()
  Future<String> getContent(Book book, BookChapter chapter) async {
    // TODO: Implement
    return '';
  }

  /// Get explore/discover page content
  /// 對應 Android: WebBook.exploreBook()
  Future<List<SearchBook>> exploreBooks(String exploreUrl,
      {int page = 1}) async {
    // TODO: Implement
    return [];
  }
}
