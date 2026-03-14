import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'rule_analyzer.dart';
import 'analyze_rule.dart';
import 'package:legado_reader/core/models/base_source.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/services/backstage_webview.dart';
import 'package:legado_reader/core/services/rate_limiter.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// AnalyzeUrl - URL 構建與請求引擎
/// 對應 Android: model/analyzeRule/AnalyzeUrl.kt (29KB)
class AnalyzeUrl {
  static final RegExp jsPattern = RegExp(
    r'@js:|(<js>([\w\W]*?)</js>)',
    caseSensitive: false,
  );
  static final RegExp pagePattern = RegExp(r'<(.*?)>');
  static final RegExp paramPattern = RegExp(r'\s*,\s*(?=\{)');

  final String mUrl;
  final String? key;
  final int? page;
  final String? speakText;
  final int? speakSpeed;
  final String? voiceName;
  String? baseUrl;
  final AnalyzeRule? analyzer;
  final dynamic source; // BaseSource equivalent

  String ruleUrl = "";
  String url = "";
  String method = "GET";
  Map<String, dynamic> headerMap = {};
  dynamic body;
  String? charset;
  String? type;
  String? proxy;
  int retry = 0;
  bool useWebView = false;
  String? webJs;
  int webViewDelayTime = 0;
  String? encodedQuery;
  String? encodedForm;
  Response? _lastResponse;

  AnalyzeUrl(
    this.mUrl, {
    this.key,
    this.page,
    this.speakText,
    this.speakSpeed,
    this.voiceName,
    this.baseUrl,
    this.analyzer,
    this.source,
    Map<String, dynamic>? initialHeaders,
  }) {
    if (initialHeaders != null) {
      headerMap.addAll(initialHeaders);
    }
    // Ensure baseUrl has scheme
    if (baseUrl != null && !baseUrl!.startsWith('http')) {
      baseUrl = 'http://$baseUrl';
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
      result = ra.innerRuleRange(
        '{{',
        '}}',
        fr: (js) {
          return analyzer!.evalJS(js, null)?.toString() ?? "";
        },
      );
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
            if (k == 'proxy') {
              proxy = v.toString();
            } else {
              headerMap[k] = v.toString();
            }
          });
        }
        if (options.containsKey('body')) {
          body = options['body'];
          if (body is String && analyzer != null) {
            body = _replaceInString(body as String);
          }
        }
        if (options.containsKey('type')) {
          type = options['type'].toString();
        }
        if (options.containsKey('charset')) {
          charset = options['charset'].toString();
        }
        if (options.containsKey('retry')) {
          retry = int.tryParse(options['retry'].toString()) ?? 0;
        }
        if (options.containsKey('webView')) {
          final wv = options['webView'];
          useWebView = wv == true || wv == "true";
        }
        if (options.containsKey('webJs')) {
          webJs = options['webJs'].toString();
        }
        if (options.containsKey('webViewDelayTime')) {
          webViewDelayTime =
              int.tryParse(options['webViewDelayTime'].toString()) ?? 0;
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

    if (method == "GET") {
      final pos = url.indexOf('?');
      if (pos != -1) {
        analyzeQuery(url.substring(pos + 1));
        url = "${url.substring(0, pos)}?$encodedQuery";
        encodedQuery = null;
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
    if (speakText != null) {
      result = result.replaceAll('{{speakText}}', Uri.encodeComponent(speakText!));
    }
    if (speakSpeed != null) {
      result = result.replaceAll('{{speakSpeed}}', speakSpeed.toString());
    }
    if (voiceName != null) {
      result = result.replaceAll('{{voiceName}}', voiceName!);
    }
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

  Future<Uint8List?> getByteArray({CancelToken? cancelToken}) async {
    // 1. 處理 data: 協議 (高度還原 Android)
    if (url.startsWith('data:')) {
      try {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          final data = url.substring(commaIndex + 1);
          return base64Decode(data);
        }
      } catch (e, s) {
        AppLog.put('Unexpected Error', error: e, stackTrace: s);
      }
      return null;
    }

    final dio = HttpClient().client;
    final limiter = ConcurrentRateLimiter(source is BaseSource ? source : null);

    return await limiter.withLimit(() async {
      await _setCookie();

      try {
        final requestUrl = encodedQuery != null ? "$url?$encodedQuery" : url;
        final requestData = encodedForm ?? body;

        final options = Options(
          method: method,
          headers: headerMap.cast<String, dynamic>(),
          responseType: ResponseType.bytes,
          followRedirects: true,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        );

        Response response;
        if (method == 'POST') {
          response = await dio.request(
            requestUrl,
            data: requestData,
            options: options,
            cancelToken: cancelToken,
          );
        } else {
          response = await dio.request(
            requestUrl,
            options: options,
            cancelToken: cancelToken,
          );
        }
        _lastResponse = response;

        if (response.realUri.toString() != requestUrl) {
          setRedirectUrl(response.realUri.toString());
        }

        final List<int> responseBytes = response.data as List<int>;
        return Uint8List.fromList(responseBytes);
      } catch (e) {
        rethrow; // Let caller handle it (e.g. BaseProvider)
      }
    });
  }

  /// Execute the HTTP request and return response body
  Future<String> getResponseBody({CancelToken? cancelToken}) async {
    if (useWebView) {
      final requestUrl = encodedQuery != null ? "$url?$encodedQuery" : url;
      final webView = BackstageWebView(
        url: requestUrl,
        headerMap: headerMap.cast<String, String>(),
        javaScript: webJs,
        delayTime: webViewDelayTime,
      );
      final wvResponse = await webView.getStrResponse();
      return wvResponse['body']?.toString() ?? "";
    }

    final bytes = await getByteArray(cancelToken: cancelToken);
    if (bytes == null) return '';

    try {
      // 1. Check Content-Type and Determine charset
      String effectiveCharset = charset ?? "UTF-8";
      String? contentType = _lastResponse?.headers.value('content-type');
      
      if (contentType != null) {
        contentType = contentType.toLowerCase();
        // If it's an image or other non-text type, throw exception
        if (contentType.contains('image/') || 
            contentType.contains('video/') || 
            contentType.contains('audio/') ||
            contentType.contains('application/octet-stream') ||
            contentType.contains('application/zip') ||
            contentType.contains('application/pdf')) {
          throw Exception('Unsupported Content-Type for text analysis: $contentType');
        }
        
        // Try to extract charset from content-type if not already specified
        if (charset == null) {
          final charsetMatch = RegExp(r'charset=([\w-]+)').firstMatch(contentType);
          if (charsetMatch != null) {
            effectiveCharset = charsetMatch.group(1)!;
          }
        }
      }

      // 2. Decode based on charset
      String result;
      if (effectiveCharset.toUpperCase().contains('GBK') ||
          effectiveCharset.toUpperCase().contains('GB2312') ||
          effectiveCharset.toUpperCase().contains('GB18030')) {
        result = gbk.decode(bytes);
      } else {
        result = utf8.decode(bytes, allowMalformed: true);
      }

      return result;
    } catch (e) {
      return '';
    }
  }
}
