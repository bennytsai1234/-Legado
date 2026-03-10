import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:uuid/uuid.dart';
import 'package:convert/convert.dart';
import 'js_encode_utils.dart';
import '../analyze_url.dart';
import '../../models/base_source.dart';
import '../../services/http_client.dart';
import '../../services/cookie_store.dart';

/// JsExtensions - JS 橋接擴展
/// 對應 Android: help/JsExtensions.kt
class JsExtensions {
  final JavascriptRuntime runtime;
  final BaseSource? source;
  final CookieStore _cookieStore = CookieStore();

  JsExtensions(this.runtime, {this.source});

  /// 注入 java 物件及函式
  void inject() {
    // 實作 java.log
    runtime.onMessage('log', (dynamic args) {
      debugPrint('JS_LOG: $args');
    });

    // 實作 java.ajax(url) -> 返回 String body
    runtime.onMessage('ajax', (dynamic args) async {
      try {
        final url = _parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url, analyzer: source != null ? null : null); // source logic
        return await analyzeUrl.getResponseBody();
      } catch (e) {
        return e.toString();
      }
    });

    // 實作 java.ajaxAll(urlList)
    runtime.onMessage('ajaxAll', (dynamic args) async {
      try {
        if (args is List) {
          final List<String> urls = args.map((e) => e.toString()).toList();
          final List<Future<String>> futures = urls.map((url) => AnalyzeUrl(url).getResponseBody()).toList();
          return await Future.wait(futures);
        }
        return [];
      } catch (e) {
        return [e.toString()];
      }
    });

    // 實作 java.connect(urlStr) -> 返回物件 {body: "...", url: "...", code: 200}
    runtime.onMessage('connect', (dynamic args) async {
      try {
        final url = _parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url);
        final body = await analyzeUrl.getResponseBody();
        return {'body': body, 'url': analyzeUrl.url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': args.toString(), 'code': 500};
      }
    });

    // 實作 java.get(url, headers)
    runtime.onMessage('get', (dynamic args) async {
      try {
        final url = args[0].toString();
        final Map<String, dynamic> headers = Map<String, dynamic>.from(args[1] ?? {});
        final response = await HttpClient().client.get(url, options: Options(headers: headers));
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map
        };
      } catch (e) {
        return {'body': e.toString(), 'code': 500};
      }
    });

    // 實作 java.post(url, body, headers)
    runtime.onMessage('post', (dynamic args) async {
      try {
        final url = args[0].toString();
        final body = args[1];
        final Map<String, dynamic> headers = Map<String, dynamic>.from(args[2] ?? {});
        final response = await HttpClient().client.post(url, data: body, options: Options(headers: headers));
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map
        };
      } catch (e) {
        return {'body': e.toString(), 'code': 500};
      }
    });

    // 實作 java.getCookie
    runtime.onMessage('getCookie', (dynamic args) async {
      final tag = args[0].toString();
      final key = args.length > 1 ? args[1]?.toString() : null;
      if (key != null) {
        final cookie = await _cookieStore.getCookie(tag);
        return _cookieStore.cookieToMap(cookie)[key] ?? "";
      }
      return await _cookieStore.getCookie(tag);
    });

    // 注入 java 物件及其屬性
    runtime.evaluate('''
      var java = {
        ajax: function(url) { return sendMessage('ajax', JSON.stringify(url)); },
        ajaxAll: function(urlList) { return sendMessage('ajaxAll', JSON.stringify(urlList)); },
        connect: function(url) { return sendMessage('connect', JSON.stringify(url)); },
        get: function(url, headers) { 
          var res = sendMessage('get', JSON.stringify([url, headers]));
          return {
            body: function() { return res.body; },
            url: function() { return res.url; },
            statusCode: function() { return res.code; },
            headers: function() { return res.headers; }
          };
        },
        post: function(url, body, headers) {
          var res = sendMessage('post', JSON.stringify([url, body, headers]));
          return {
            body: function() { return res.body; },
            url: function() { return res.url; },
            statusCode: function() { return res.code; },
            headers: function() { return res.headers; }
          };
        },
        head: function(url, headers) {
          // Simplified as GET for now or implement HEAD specifically if needed
          return this.get(url, headers);
        },
        getCookie: function(tag, key) { return sendMessage('getCookie', JSON.stringify([tag, key])); },
        log: function(msg) { sendMessage('log', JSON.stringify(msg)); },
        md5Encode: function(str) { return _md5Encode(str); },
        md5Encode16: function(str) { return _md5Encode16(str); },
        base64Encode: function(str) { return _base64Encode(str); },
        base64Decode: function(str) { return _base64Decode(str); },
        encodeURI: function(str, enc) { return _encodeURI(str, enc); },
        hexEncode: function(str) { return _hexEncode(str); },
        hexDecode: function(hex) { return _hexDecode(hex); },
        randomUUID: function() { return _randomUUID(); },
        timeFormat: function(time) { return _timeFormat(time); },
        importScript: function(path) { return sendMessage('importScript', JSON.stringify(path)); },
        cacheFile: function(url, saveTime) { return sendMessage('cacheFile', JSON.stringify([url, saveTime])); }
      };
    ''');

    // 額外訊息處理
    runtime.onMessage('importScript', (dynamic args) async {
      // TODO: 實作下載並評估 JS
      return "";
    });

    runtime.onMessage('cacheFile', (dynamic args) async {
      // TODO: 實作檔案快取
      return "";
    });

    // 注入同步輔助函式
    _injectSyncFunctions();
  }

  String _parseUrlArg(dynamic args) {
    if (args is List && args.isNotEmpty) return args[0].toString();
    return args.toString();
  }

  void _injectSyncFunctions() {
    runtime.setVariable('_md5Encode', (String str) => JsEncodeUtils.md5Encode(str));
    runtime.setVariable('_md5Encode16', (String str) => JsEncodeUtils.md5Encode16(str));
    runtime.setVariable('_base64Encode', (String str) => JsEncodeUtils.base64Encode(str));
    runtime.setVariable('_base64Decode', (String str) => JsEncodeUtils.base64Decode(str));
    runtime.setVariable('_hexEncode', (String str) => hex.encode(utf8.encode(str)));
    runtime.setVariable('_hexDecode', (String h) => utf8.decode(hex.decode(h)));
    runtime.setVariable('_randomUUID', () => const Uuid().v4());
    runtime.setVariable('_encodeURI', (String str, [String? enc]) {
      // Dart's Uri.encodeComponent is similar to encodeURIComponent
      return Uri.encodeComponent(str);
    });
    runtime.setVariable('_timeFormat', (dynamic time) {
      final t = time is int ? time : int.tryParse(time.toString()) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(t).toIso8601String();
    });
  }

  // 靜態輔助方法，供其它地方獲取通用 JS
  static String getUtilsJs() {
    return ""; // 目前主要透過 inject() 動態注入
  }
}

// 修正 debugPrint 缺失問題
void debugPrint(String message) {
  print(message);
}
