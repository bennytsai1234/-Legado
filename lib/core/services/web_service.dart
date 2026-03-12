import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/chapter_dao.dart';
import '../database/dao/replace_rule_dao.dart';
import '../database/dao/rss_source_dao.dart';
import '../models/api_response.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/book_progress.dart';
import '../models/replace_rule.dart';
import '../models/rss_source.dart';
import 'book_source_service.dart';

/// WebService - 本地 Web 伺服器
/// 對應 Android: service/WebService.kt 與 web/HttpServer.kt
class WebService extends ChangeNotifier {
  static final WebService _instance = WebService._internal();
  factory WebService() => _instance;

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 8659;
  String? _ipAddress;

  final BookDao _bookDao = BookDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();
  final ReplaceRuleDao _replaceDao = ReplaceRuleDao();
  final RssSourceDao _rssDao = RssSourceDao();
  final BookSourceService _sourceService = BookSourceService();

  WebService._internal();

  bool get isRunning => _isRunning;
  int get port => _port;
  String? get ipAddress => _ipAddress;

  /// 啟動 Web 服務器
  Future<void> start({int port = 8659}) async {
    if (_isRunning) return;

    try {
      _port = port;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;
      _ipAddress = await _getLocalIpAddress();
      
      _server!.listen(_handleRequest);
      
      debugPrint("WebService started at http://$_ipAddress:$_port");
      notifyListeners();
    } catch (e) {
      debugPrint("WebService failed to start: $e");
      _isRunning = false;
      notifyListeners();
    }
  }

  /// 停止 Web 伺服器
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _ipAddress = null;
    notifyListeners();
  }

  /// 處理 HTTP 請求 (高度還原 HttpServer.kt 路由邏輯)
  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    // CORS 處理 (高度還原 Android OPTIONS 處理)
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      dynamic result;
      if (method == 'GET') {
        result = await _handleGet(path, request.uri.queryParameters);
      } else if (method == 'POST') {
        if (path == '/addLocalBook') {
          result = await _handleAddLocalBook(request);
        } else {
          final content = await utf8.decodeStream(request);
          result = await _handlePost(path, content);
        }
      }

      if (result != null) {
        request.response.headers.contentType = ContentType.json;
        // 使用統一的 ApiResponse 封裝 (高度還原 ReturnData.kt)
        final response = ApiResponse.success(result);
        request.response.write(response.toJsonString());
      } else {
        // 若找不到 API，預留給靜態網頁 (目前返回 404)
        request.response.statusCode = HttpStatus.notFound;
        request.response.write("API Not Found or Not Implemented yet.");
      }
    } catch (e) {
      debugPrint("WebService Error: $e");
      request.response.statusCode = HttpStatus.internalServerError;
      final response = ApiResponse.error(e.toString());
      request.response.write(response.toJsonString());
    } finally {
      await request.response.close();
    }
  }

  /// 處理 GET 請求 (對標 HttpServer.kt)
  Future<dynamic> _handleGet(String path, Map<String, String> params) async {
    switch (path) {
      case '/getBookSources':
        final sources = await _sourceDao.getAllPart();
        return sources.map((s) => s.toJson()).toList();
      case '/getBookSource':
        final url = params['url'];
        if (url == null) return null;
        final source = await _sourceDao.getByUrl(url);
        return source?.toJson();
      case '/getBookshelf':
        final books = await _bookDao.getBookshelf();
        return books.map((b) => b.toJson()).toList();
      case '/getChapterList':
        final url = params['url'];
        if (url == null) return null;
        var chapters = await _chapterDao.getChapters(url);
        if (chapters.isEmpty) {
          // 如果資料庫沒章節，嘗試重新整理
          return await _refreshToc(url);
        }
        return chapters.map((c) => c.toJson()).toList();
      case '/refreshToc':
        final url = params['url'];
        if (url == null) return null;
        return await _refreshToc(url);
      case '/getBookContent':
        final url = params['url'];
        final indexStr = params['index'];
        if (url == null || indexStr == null) return null;
        final index = int.parse(indexStr);
        return await _getBookContent(url, index);
      case '/getReplaceRules':
        final rules = await _replaceDao.getAll();
        return rules.map((r) => r.toJson()).toList();
      case '/getRssSources':
        final sources = await _rssDao.getAll();
        return sources.map((s) => s.toJson()).toList();
      case '/getRssSource':
        final url = params['url'];
        if (url == null) return null;
        final sources = await _rssDao.getAll();
        final match = sources.where((s) => s.sourceUrl == url).firstOrNull;
        return match?.toJson();
      default:
        return null;
    }
  }

  /// 處理 POST 請求 (對標 HttpServer.kt)
  Future<dynamic> _handlePost(String path, String body) async {
    switch (path) {
      case '/saveBookSource':
        final source = BookSource.fromJson(jsonDecode(body));
        await _sourceDao.insertOrUpdate(source);
        return true;
      case '/saveBookSources':
        final List<dynamic> list = jsonDecode(body);
        final sources = list.map((e) => BookSource.fromJson(e)).toList();
        await _sourceDao.insertOrUpdateAll(sources);
        return true;
      case '/deleteBookSources':
        final List<dynamic> urls = jsonDecode(body);
        await _sourceDao.deleteSources(urls.cast<String>());
        return true;
      case '/saveBook':
        final book = Book.fromJson(jsonDecode(body));
        await _bookDao.insertOrUpdate(book);
        return "";
      case '/deleteBook':
        final book = Book.fromJson(jsonDecode(body));
        await _bookDao.delete(book.bookUrl);
        await _chapterDao.deleteByBook(book.bookUrl);
        return "";
      case '/saveBookProgress':
        final progress = BookProgress.fromJson(jsonDecode(body));
        final book = await _bookDao.getByNameAndAuthor(progress.name, progress.author);
        if (book != null) {
          await _bookDao.updateProgress(
            book.bookUrl,
            progress.durChapterIndex,
            progress.durChapterPos,
            progress.durChapterTitle ?? "",
          );
          return "";
        }
        return null;
      case '/clearCache':
        final cacheDir = await getTemporaryDirectory();
        final jsCache = Directory("${cacheDir.path}/js_cache");
        if (await jsCache.exists()) {
          await jsCache.delete(recursive: true);
        }
        return "";
      case '/addLocalBook':
        // 本地書上傳已由外層 _handleAddLocalBook 攔截處理
        return "";
      case '/saveReplaceRule':
        final rule = ReplaceRule.fromJson(jsonDecode(body));
        await _replaceDao.insertOrUpdate(rule);
        return "";
      case '/deleteReplaceRule':
        final rule = ReplaceRule.fromJson(jsonDecode(body));
        await _replaceDao.delete(rule.id);
        return "";
      case '/testReplaceRule':
        final Map<String, dynamic> map = jsonDecode(body);
        final dynamic ruleData = map['rule'];
        final rule = ReplaceRule.fromJson(ruleData is String ? jsonDecode(ruleData) : ruleData);
        final String text = map['text'] ?? "";
        if (rule.pattern.isEmpty) return "替換規則不能為空";
        try {
          if (rule.isRegex) {
            return text.replaceAll(RegExp(rule.pattern), rule.replacement);
          } else {
            return text.replaceAll(rule.pattern, rule.replacement);
          }
        } catch (e) {
          return e.toString();
        }
      case '/saveRssSource':
        final source = RssSource.fromJson(jsonDecode(body));
        await _rssDao.insertOrUpdate(source);
        return "";
      case '/saveRssSources':
        final List<dynamic> list = jsonDecode(body);
        final sources = list.map((e) => RssSource.fromJson(e)).toList();
        for (var s in sources) {
          await _rssDao.insertOrUpdate(s);
        }
        return sources.map((s) => s.toJson()).toList();
      case '/deleteRssSources':
        final List<dynamic> list = jsonDecode(body);
        for (var item in list) {
          final source = RssSource.fromJson(item);
          await _rssDao.delete(source.sourceUrl);
        }
        return "已執行";
      default:
        return null;
    }
  }

  /// 重新整理目錄
  Future<List<Map<String, dynamic>>> _refreshToc(String bookUrl) async {
    final book = await _bookDao.getByUrl(bookUrl);
    if (book == null) throw Exception("書籍不存在");
    
    final source = await _sourceDao.getByUrl(book.origin);
    if (source == null) throw Exception("書源不存在");

    final chapters = await _sourceService.getChapterList(source, book);
    await _chapterDao.deleteByBook(bookUrl);
    await _chapterDao.insertChapters(chapters);
    
    // 更新書籍總章節數
    book.totalChapterNum = chapters.length;
    await _bookDao.insertOrUpdate(book);

    return chapters.map((c) => c.toJson()).toList();
  }

  /// 獲取章節內容
  Future<String> _getBookContent(String bookUrl, int index) async {
    // 優先從本地獲取
    var content = await _chapterDao.getContent(bookUrl, index);
    if (content != null) return content;

    final book = await _bookDao.getByUrl(bookUrl);
    if (book == null) throw Exception("書籍不存在");

    final chapter = await _chapterDao.getChapterByIndex(bookUrl, index);
    if (chapter == null) throw Exception("章節不存在");

    final source = await _sourceDao.getByUrl(book.origin);
    if (source == null) throw Exception("書源不存在");

    // 從網路獲取
    content = await _sourceService.getContent(source, book, chapter);
    await _chapterDao.saveContent(bookUrl, index, content);
    
    return content;
  }

  /// 獲取本地 IP
  Future<String> _getLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return "127.0.0.1";
  }

  Future<String> _handleAddLocalBook(HttpRequest request) async {
    final contentType = request.headers.contentType;
    final boundary = contentType?.parameters['boundary'];
    if (boundary == null) throw Exception("No boundary found in multipart");

    final boundaryBytes = utf8.encode('--$boundary');
    final data = await request.expand((b) => b).toList();

    int start = _indexOfBytes(data, boundaryBytes, 0);
    if (start == -1) throw Exception("Invalid multipart format");
    start += boundaryBytes.length + 2;

    final headerEnd = _indexOfBytes(data, utf8.encode('\r\n\r\n'), start);
    if (headerEnd == -1) throw Exception("Invalid headers");
    
    final headerStr = utf8.decode(data.sublist(start, headerEnd));
    String fileName = "upload.txt";
    final match = RegExp(r'filename="([^"]+)"').firstMatch(headerStr);
    if (match != null) {
      fileName = match.group(1)!;
    }

    int contentStart = headerEnd + 4;
    int contentEnd = _indexOfBytes(data, boundaryBytes, contentStart) - 2;

    if (contentEnd < contentStart) throw Exception("Invalid content");

    final fileData = data.sublist(contentStart, contentEnd);
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(fileData);

    // TODO: Actually import the book using BookshelfProvider or BookDao
    // But since this is a background service, simply saving it might be enough if Legado UI expects it.
    return "File uploaded to ${file.path}";
  }

  int _indexOfBytes(List<int> data, List<int> pattern, int start) {
    for (int i = start; i <= data.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }
}
