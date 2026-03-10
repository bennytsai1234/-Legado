import 'dart:convert';
import 'package:dio/dio.dart';
import 'rule_analyzer.dart';
import 'analyze_rule.dart';
import '../services/http_client.dart';

/// AnalyzeUrl - URL 構建與請求引擎
/// 對應 Android: model/analyzeRule/AnalyzeUrl.kt (29KB)
class AnalyzeUrl {
  static final RegExp jsPattern = RegExp(r'@js:|(<js>([\w\W]*?)</js>)', caseSensitive: false);
  static final RegExp pagePattern = RegExp(r'<(.*?)>');
  static final RegExp paramPattern = RegExp(r'\s*,\s*(?=\{)');

  final String mUrl;
  final String? key;
  final int? page;
  String? baseUrl;
  final AnalyzeRule? analyzer;
  
  String ruleUrl = "";
  String url = "";
  String method = "GET";
  Map<String, dynamic> headerMap = {};
  dynamic body;
  String? charset;
  bool useWebView = false;
  String? webJs;
  String? encodedQuery;
  String? encodedForm;

  AnalyzeUrl(
    this.mUrl, {
    this.key,
    this.page,
    this.baseUrl,
    this.analyzer,
    Map<String, dynamic>? initialHeaders,
  }) {
    if (initialHeaders != null) {
      headerMap.addAll(initialHeaders);
    }
    _initUrl();
  }

  void _initUrl() {
    ruleUrl = mUrl;
    // 1. 執行 JS 替換 (if any)
    _analyzeJs();
    // 2. 替換變數 {{key}}, {{page}}, {{js}}
    _replaceKeyPageJs();
    // 3. 解析 Legado URL 格式: url, {options}
    _analyzeUrl();
  }

  void _analyzeJs() {
    var start = 0;
    final matches = jsPattern.allMatches(ruleUrl);
    var result = ruleUrl;
    
    for (final match in matches) {
      if (match.start > start) {
        final prefix = ruleUrl.substring(start, match.start).trim();
        if (prefix.isNotEmpty) {
          result = prefix.replaceAll('@result', result);
        }
      }
      
      String jsCode;
      if (match.group(0)!.toLowerCase() == '@js:') {
        jsCode = ruleUrl.substring(match.end).trim();
        result = analyzer?.evalJS(jsCode, result)?.toString() ?? result;
        ruleUrl = result;
        return; // @js: matches to the end
      } else {
        jsCode = match.group(2)!.trim();
        result = analyzer?.evalJS(jsCode, result)?.toString() ?? result;
      }
      start = match.end;
    }

    if (ruleUrl.length > start) {
      final suffix = ruleUrl.substring(start).trim();
      if (suffix.isNotEmpty) {
        result = suffix.replaceAll('@result', result);
      }
    }
    ruleUrl = result;
  }

  void _replaceKeyPageJs() {
    var result = ruleUrl;
    
    // 替換 {{js}}
    if (result.contains('{{') && result.contains('}}') && analyzer != null) {
      final ra = RuleAnalyzer(result);
      result = ra.innerRuleRange('{{', '}}', fr: (js) {
        return analyzer!.evalJS(js, null)?.toString() ?? "";
      });
    }

    if (key != null) {
      result = result.replaceAll('{{key}}', key!);
    }
    if (page != null) {
      result = result.replaceAll('{{page}}', page.toString());
      // Handle <page1,page2,page3>
      final pagePattern = RegExp(r'<(.*?)>');
      result = result.replaceAllMapped(pagePattern, (match) {
        final pages = match.group(1)!.split(',');
        if (page! <= pages.length) {
          return pages[page! - 1].trim();
        } else {
          return pages.last.trim();
        }
      });
    }
    ruleUrl = result;
  }

  void _analyzeUrl() {
    // 1. Split url and options
    final match = paramPattern.firstMatch(ruleUrl);
    String urlNoOption;
    if (match != null) {
      urlNoOption = ruleUrl.substring(0, match.start).trim();
      final optionStr = ruleUrl.substring(match.end).trim();
      try {
        final options = jsonDecode(optionStr) as Map<String, dynamic>;
        if (options.containsKey('method')) {
          method = options['method'].toString().toUpperCase();
        }
        if (options.containsKey('headers')) {
          final headers = options['headers'] as Map<String, dynamic>;
          headers.forEach((k, v) {
            headerMap[k] = v.toString();
          });
        }
        if (options.containsKey('body')) {
          body = options['body'];
          if (body is String && analyzer != null) {
             body = _replaceInString(body as String);
          }
        }
        if (options.containsKey('charset')) {
          charset = options['charset'].toString();
        }
        if (options.containsKey('webView')) {
          final wv = options['webView'];
          useWebView = wv == true || wv == "true";
        }
        if (options.containsKey('webJs')) {
          webJs = options['webJs'].toString();
        }
        if (options.containsKey('js')) {
          final jsStr = options['js'].toString();
          final jsResult = analyzer?.evalJS(jsStr, urlNoOption);
          if (jsResult != null) {
            urlNoOption = jsResult.toString();
          }
        }
      } catch (e) {
        // Ignore invalid JSON options
      }
    } else {
      urlNoOption = ruleUrl.trim();
    }

    // 2. Resolve relative URL
    if (baseUrl != null && !urlNoOption.startsWith('http')) {
      final base = Uri.parse(baseUrl!);
      url = base.resolve(urlNoOption).toString();
    } else {
      url = urlNoOption;
    }

    // 3. Analyze Query and Fields
    if (method == "GET") {
      final pos = url.indexOf('?');
      if (pos != -1) {
        analyzeQuery(url.substring(pos + 1));
        url = url.substring(0, pos);
      }
    } else if (method == "POST") {
      if (body != null && body is String) {
        final bodyStr = body as String;
        // If not JSON/XML and no Content-Type, analyze as fields
        if (!bodyStr.trim().startsWith('{') && 
            !bodyStr.trim().startsWith('[') && 
            !bodyStr.trim().startsWith('<') &&
            headerMap['Content-Type'] == null) {
          analyzeFields(bodyStr);
        }
      }
    }
  }

  void analyzeFields(String fieldsTxt) {
    encodedForm = encodeParams(fieldsTxt, charset, false);
  }

  void analyzeQuery(String query) {
    encodedQuery = encodeParams(query, charset, true);
  }

  String encodeParams(String params, String? charset, bool isQuery) {
    // Basic implementation of param encoding
    // Android version handles more edge cases and charsets
    final parts = params.split('&');
    final sb = StringBuffer();
    
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) sb.write('&');
      final part = parts[i];
      final eqIndex = part.indexOf('=');
      if (eqIndex != -1) {
        final key = part.substring(0, eqIndex);
        final value = part.substring(eqIndex + 1);
        sb.write(Uri.encodeQueryComponent(key));
        sb.write('=');
        sb.write(Uri.encodeQueryComponent(value));
      } else {
        sb.write(Uri.encodeQueryComponent(part));
      }
    }
    return sb.toString();
  }

  String _replaceInString(String str) {
    var result = str;
    if (key != null) result = result.replaceAll('{{key}}', key!);
    if (page != null) result = result.replaceAll('{{page}}', page.toString());
    return result;
  }

  /// Execute the HTTP request and return response body
  Future<String> getResponseBody() async {
    final dio = HttpClient().client;
    
    // TODO: Handle charset if not UTF-8 (need iconv or similar)
    // TODO: webView mode (Phase 4+)

    try {
      final options = Options(
        method: method,
        headers: headerMap.cast<String, dynamic>(),
        responseType: ResponseType.plain,
      );

      Response response;
      if (method == 'POST') {
        response = await dio.request(url, data: body, options: options);
      } else {
        response = await dio.request(url, options: options);
      }
      return response.data.toString();
    } catch (e) {
      return '';
    }
  }
}
