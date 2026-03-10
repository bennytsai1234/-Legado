import 'package:dio/dio.dart';
import 'cookie_store.dart';

/// HttpClient - 全域 HTTP 客戶端
/// 參考 Android: help/http/HttpHelper.kt
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;

  late Dio dio;
  final CookieStore _cookieStore = CookieStore();

  static const String defaultUserAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  HttpClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
        headers: {'User-Agent': defaultUserAgent},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. 注入 Cookie
          final cookie = await _cookieStore.getCookie(options.uri.toString());
          if (cookie.isNotEmpty) {
            options.headers['Cookie'] = cookie;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // 2. 保存 Cookie (Set-Cookie)
          final setCookies = response.headers['set-cookie'];
          if (setCookies != null && setCookies.isNotEmpty) {
            final cookieStr = setCookies.join('; ');
            await _cookieStore.replaceCookie(
              response.requestOptions.uri.toString(),
              cookieStr,
            );
          }
          return handler.next(response);
        },
      ),
    );
  }

  /// 獲取 Dio 實例
  Dio get client => dio;
}
