import 'dart:convert';
import 'package:dio/dio.dart';
import 'rule_analyzer.dart';
import 'analyze_rule.dart';
import '../services/http_client.dart';
import '../services/cookie_store.dart';

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
  final dynamic source; // BaseSource equivalent
  
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
    this.source,
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

  void setRedirectUrl(String redirectUrl) {
    url = redirectUrl;
    final uri = Uri.parse(url);
    baseUrl = "${uri.scheme}://${uri.host}";
  }

  Future<void> _setCookie() async {
    final domain = CookieStore().getSubDomain(url);
    final cookie = await CookieStore().getCookie(domain);
    if (cookie.isNotEmpty) {
      final headerCookie = headerMap['Cookie']?.toString() ?? "";
      if (headerCookie.isNotEmpty) {
        final merged = CookieStore().mapToCookie({
          ...CookieStore().cookieToMap(cookie),
          ...CookieStore().cookieToMap(headerCookie),
        });
        headerMap['Cookie'] = merged;
      } else {
        headerMap['Cookie'] = cookie;
      }
    }
  }
/// Execute the HTTP request and return response body
Future<String> getResponseBody() async {
  final dio = HttpClient().client;

  await _setCookie();

  try {
    final requestUrl = encodedQuery != null ? "$url?$encodedQuery" : url;
    final requestData = encodedForm ?? body;

    final options = Options(
      method: method,
      headers: headerMap.cast<String, dynamic>(),
      responseType: ResponseType.bytes, // Use bytes to handle charset manually
      followRedirects: true,
    );

    Response response;
    if (method == 'POST') {
      response = await dio.request(requestUrl, data: requestData, options: options);
    } else {
      response = await dio.request(requestUrl, options: options);
    }

    // Handle redirect URL update
    if (response.realUri.toString() != requestUrl) {
      setRedirectUrl(response.realUri.toString());
    }

    final List<int> responseBytes = response.data as List<int>;

    // 1. Determine charset
    String effectiveCharset = charset ?? "UTF-8";
    if (charset == null) {
      final contentType = response.headers.value('content-type');
      if (contentType != null) {
        final match = RegExp(r'charset=([\w-]+)', caseSensitive: false).firstMatch(contentType);
        if (match != null) {
          effectiveCharset = match.group(1)!;
        }
      }
    }

    // 2. Decode based on charset
    String result;
    if (effectiveCharset.toUpperCase().contains('GBK') || 
        effectiveCharset.toUpperCase().contains('GB2312') ||
        effectiveCharset.toUpperCase().contains('GB18030')) {
      // TODO: Use gbk_codec if available. For now, try fallback or notify
      // This is a placeholder since we don't have the library yet
      result = utf8.decode(responseBytes, allowMalformed: true);
    } else {
      result = utf8.decode(responseBytes, allowMalformed: true);
    }

    return result;
  } catch (e) {
    return '';
  }
}
}
