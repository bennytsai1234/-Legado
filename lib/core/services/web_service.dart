import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../database/dao/book_dao.dart';
import '../database/dao/book_source_dao.dart';
import '../models/book.dart';
import '../models/book_source.dart';

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
        final content = await utf8.decodeStream(request);
        result = await _handlePost(path, content);
      }

      if (result != null) {
        request.response.headers.contentType = ContentType.json;
        // 還原原版 ReturnData 封裝格式
        final responseData = {
          'isSuccess': true,
          'data': result,
        };
        request.response.write(jsonEncode(responseData));
      } else {
        // 若找不到 API，預留給靜態網頁 (目前返回 404)
        request.response.statusCode = HttpStatus.notFound;
        request.response.write("API Not Found or Not Implemented yet.");
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'isSuccess': false, 'error': e.toString()}));
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
      default:
        return null;
    }
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
}
