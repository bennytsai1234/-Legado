/// AnalyzeUrl - URL 構建與請求引擎
/// 對應 Android: model/analyzeRule/AnalyzeUrl.kt (29KB)
///
/// 職責：
/// 1. 解析書源 URL 模板 (searchUrl, bookUrl, etc.)
/// 2. 支援 POST/GET 方法切分
/// 3. 支援 Header 自訂
/// 4. 支援 {{page}}, {{pageSize}}, {{key}} 變數替換
/// 5. 支援 WebView 載入模式
/// 6. 支援 JS 預處理 URL
library;

import 'package:dio/dio.dart';

// TODO: Phase 2 實作
// - [ ] URL 模板解析 (method, body, headers, charset, webView)
// - [ ] {{page}}, {{pageSize}}, {{key}} 動態替換
// - [ ] POST body 解析 (form-data vs json)
// - [ ] JS 預處理 URL
// - [ ] WebView 載入模式

class AnalyzeUrl {
  String _url = '';
  String _method = 'GET';
  Map<String, String> _headers = {};
  String? _body;
  String? _charset;
  bool _useWebView = false;
  int _page = 1;

  /// Parse a raw URL rule string into structured request parameters
  ///
  /// Legado URL format examples:
  /// - Simple: `https://example.com/search?q={{key}}`
  /// - POST: `https://example.com/api, {"method":"POST","body":"keyword={{key}}"}`
  /// - With headers: `https://example.com, {"headers":{"User-Agent":"..."}}`
  /// - WebView: `https://example.com, {"webView":true}`
  void parse(String rawUrl, {String? key, int page = 1}) {
    _page = page;
    // TODO: Implement full URL parsing
    _url = rawUrl;
  }

  /// Execute the HTTP request and return response body
  Future<String> getResponseBody() async {
    final dio = Dio();

    try {
      final options = Options(
        method: _method,
        headers: _headers.isNotEmpty ? _headers : null,
      );

      Response response;
      if (_method.toUpperCase() == 'POST') {
        response = await dio.request(_url, data: _body, options: options);
      } else {
        response = await dio.request(_url, options: options);
      }
      return response.data.toString();
    } catch (e) {
      return '';
    }
  }

  String get url => _url;
  String get method => _method;
  Map<String, String> get headers => _headers;
  bool get useWebView => _useWebView;
}
