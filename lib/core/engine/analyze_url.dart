import 'dart:convert';
import 'package:dio/dio.dart';
import 'rule_analyzer.dart';
import 'analyze_rule.dart';
import '../services/http_client.dart';

/// AnalyzeUrl - URL 構建與請求引擎
/// 對應 Android: model/analyzeRule/AnalyzeUrl.kt (29KB)
class AnalyzeUrl {
  final String mUrl;
  final String? key;
  final int? page;
  final String? baseUrl;
  final AnalyzeRule? analyzer;
  
  String ruleUrl = "";
  String url = "";
  String method = "GET";
  Map<String, dynamic> headerMap = {};
  dynamic body;
  String? charset;
  bool useWebView = false;
  String? webJs;

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
    // Legado 支援 @js: 內嵌在 URL 中
    if (ruleUrl.contains('@js:')) {
      final parts = ruleUrl.split('@js:');
      if (parts.length > 1 && analyzer != null) {
        final jsCode = parts[1];
        final result = analyzer!.evalJS(jsCode, parts[0]);
        ruleUrl = result?.toString() ?? parts[0];
      }
    }
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
    // Split by comma followed by {
    final commaIndex = ruleUrl.indexOf(RegExp(r',\s*\{'));
    String urlNoOption;
    if (commaIndex != -1) {
      urlNoOption = ruleUrl.substring(0, commaIndex).trim();
      final optionStr = ruleUrl.substring(commaIndex + 1).trim();
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
             // 替換 body 中的變數
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
      } catch (e) {
        // Ignore invalid JSON options
      }
    } else {
      urlNoOption = ruleUrl.trim();
    }

    // Resolve relative URL
    if (baseUrl != null && !urlNoOption.startsWith('http')) {
      final base = Uri.parse(baseUrl!);
      url = base.resolve(urlNoOption).toString();
    } else {
      url = urlNoOption;
    }
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
