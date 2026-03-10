import 'dart:convert';
import 'dart:io';
import 'package:flutter_js/flutter_js.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:convert/convert.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'js_encode_utils.dart';
import '../analyze_url.dart';
import '../../models/base_source.dart';
import '../../services/http_client.dart';
import '../../services/cookie_store.dart';
import '../../services/cache_manager.dart';

/// JsExtensions - JS 橋接擴展
/// 對應 Android: help/JsExtensions.kt
class JsExtensions {
  final JavascriptRuntime runtime;
  final BaseSource? source;
  final CookieStore _cookieStore = CookieStore();
  final CacheManager _cacheManager = CacheManager();

  JsExtensions(this.runtime, {this.source});

  /// 注入 java 物件及函式
  void inject() {
    // 實作 java.log
    runtime.onMessage('log', (dynamic args) {
      debugPrint('JS_LOG: $args');
    });

    // 實作 java.toast
    runtime.onMessage('toast', (dynamic args) {
      debugPrint('JS_TOAST: $args');
    });

    // 實作 java.ajax(url) -> 返回 String body
    runtime.onMessage('ajax', (dynamic args) async {
      try {
        final url = _parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url);
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

    // 實作 java.createSymmetricCrypto
    runtime.onMessage('symmetricCrypto', (dynamic args) {
      final action = args[0].toString();
      final transformation = args[1].toString();
      final key = args[2];
      final iv = args[3];
      final data = args[4];
      final outputFormat = args[5].toString();
      
      return JsEncodeUtils.symmetricCrypto(
        action, transformation, key, iv, data, outputFormat: outputFormat
      );
    });

    // 實作 java.strToBytes
    runtime.onMessage('strToBytes', (dynamic args) {
      final str = args[0].toString();
      // ignore: unused_local_variable
      final charset = args.length > 1 ? args[1].toString() : 'UTF-8';
      // TODO: Handle other charsets
      return utf8.encode(str);
    });

    // 實作 java.bytesToStr
    runtime.onMessage('bytesToStr', (dynamic args) {
      final List<int> bytes = List<int>.from(args[0]);
      // ignore: unused_local_variable
      final charset = args.length > 1 ? args[1].toString() : 'UTF-8';
      // TODO: Handle other charsets
      return utf8.decode(bytes);
    });

    // 實作 java.downloadFile
    runtime.onMessage('downloadFile', (dynamic args) async {
      final url = args.toString();
      try {
        final dio = HttpClient().client;
        final key = JsEncodeUtils.md5Encode16(url);
        final tempDir = await getTemporaryDirectory();
        final savePath = p.join(tempDir.path, "downloads", key);
        final file = File(savePath);
        if (!await file.parent.exists()) await file.parent.create(recursive: true);
        await dio.download(url, savePath);
        return savePath;
      } catch (e) {
        return "";
      }
    });

    // 實作 java.readFile / readTxtFile
    runtime.onMessage('readFile', (dynamic args) async {
      final path = args.toString();
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    });

    runtime.onMessage('readTxtFile', (dynamic args) async {
      final path = args.toString();
      // ignore: unused_local_variable
      final charset = args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      final file = File(path);
      if (await file.exists()) {
        // TODO: Handle charset
        return await file.readAsString();
      }
      return "";
    });

    // 注入輔助函式
    runtime.onMessage('_md5Encode', (dynamic args) => JsEncodeUtils.md5Encode(args.toString()));
    runtime.onMessage('_md5Encode16', (dynamic args) => JsEncodeUtils.md5Encode16(args.toString()));
    runtime.onMessage('_base64Encode', (dynamic args) => JsEncodeUtils.base64Encode(args.toString()));
    runtime.onMessage('_base64Decode', (dynamic args) {
      final str = args is List ? args[0].toString() : args.toString();
      final charset = args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      return JsEncodeUtils.base64Decode(str, charset: charset);
    });
    runtime.onMessage('_hexEncode', (dynamic args) => hex.encode(utf8.encode(args.toString())));
    runtime.onMessage('_hexDecode', (dynamic args) => utf8.decode(hex.decode(args.toString())));
    runtime.onMessage('_randomUUID', (dynamic args) => const Uuid().v4());
    runtime.onMessage('_timeFormat', (dynamic args) {
      final time = args;
      final t = time is int ? time : int.tryParse(time.toString()) ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(t).toIso8601String();
    });

    runtime.onMessage('_htmlFormat', (dynamic args) {
      final doc = html_parser.parse(args.toString());
      return doc.body?.text ?? "";
    });

    runtime.onMessage('_toNumChapter', (dynamic args) {
      return _toNumChapter(args.toString());
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
          return this.get(url, headers);
        },
        getCookie: function(tag, key) { return sendMessage('getCookie', JSON.stringify([tag, key])); },
        createSymmetricCrypto: function(transformation, key, iv) {
          return {
            decrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'bytes'])); },
            decryptStr: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['decrypt', transformation, key, iv, data, 'string'])); },
            encrypt: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'bytes'])); },
            encryptBase64: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'base64'])); },
            encryptHex: function(data) { return sendMessage('symmetricCrypto', JSON.stringify(['encrypt', transformation, key, iv, data, 'hex'])); }
          };
        },
        log: function(msg) { sendMessage('log', JSON.stringify(msg)); },
        toast: function(msg) { sendMessage('toast', JSON.stringify(msg)); },
        longToast: function(msg) { sendMessage('toast', JSON.stringify(msg)); },
        md5Encode: function(str) { return sendMessage('_md5Encode', JSON.stringify(str)); },
        md5Encode16: function(str) { return sendMessage('_md5Encode16', JSON.stringify(str)); },
        base64Encode: function(str) { return sendMessage('_base64Encode', JSON.stringify(str)); },
        base64Decode: function(str, charset) { return sendMessage('_base64Decode', JSON.stringify([str, charset])); },
        encodeURI: function(str, enc) { return encodeURIComponent(str); },
        hexEncode: function(str) { return sendMessage('_hexEncode', JSON.stringify(str)); },
        hexDecode: function(hex) { return sendMessage('_hexDecode', JSON.stringify(hex)); },
        randomUUID: function() { return sendMessage('_randomUUID', null); },
        timeFormat: function(time) { return sendMessage('_timeFormat', JSON.stringify(time)); },
        htmlFormat: function(str) { return sendMessage('_htmlFormat', JSON.stringify(str)); },
        t2s: function(text) { return text; }, // Placeholder
        s2t: function(text) { return text; }, // Placeholder
        strToBytes: function(str, charset) { return sendMessage('strToBytes', JSON.stringify([str, charset])); },
        bytesToStr: function(bytes, charset) { return sendMessage('bytesToStr', JSON.stringify([bytes, charset])); },
        readFile: function(path) { return sendMessage('readFile', JSON.stringify(path)); },
        readTxtFile: function(path, charset) { return sendMessage('readTxtFile', JSON.stringify([path, charset])); },
        downloadFile: function(url) { return sendMessage('downloadFile', JSON.stringify(url)); },
        toNumChapter: function(s) { return sendMessage('_toNumChapter', JSON.stringify(s)); },
        importScript: function(path) { return sendMessage('importScript', JSON.stringify(path)); },
        cacheFile: function(url, saveTime) { return sendMessage('cacheFile', JSON.stringify([url, saveTime])); }
      };
    ''');

    // 額外訊息處理
    runtime.onMessage('importScript', (dynamic args) async {
      final path = args.toString();
      if (path.startsWith('http')) {
        return await _cacheFile(path, 0);
      } else {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsString();
        }
      }
      return "";
    });

    runtime.onMessage('cacheFile', (dynamic args) async {
      final url = args[0].toString();
      final saveTime = args.length > 1 ? args[1] as int : 0;
      return await _cacheFile(url, saveTime);
    });
  }

  String _toNumChapter(String s) {
    // Basic implementation of converting Chinese numbers to Arabic in chapter titles
    final chnMap = {'零': 0, '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10};
    return s.replaceAllMapped(RegExp(r'[零一二三四五六七八九十]+'), (match) {
      final chn = match.group(0)!;
      int res = 0;
      if (chn.length == 1) return chnMap[chn]?.toString() ?? chn;
      if (chn.length == 2 && chn.startsWith('十')) {
        res = 10 + (chnMap[chn[1]] ?? 0);
      } else if (chn.length == 2 && chn.endsWith('十')) {
        res = (chnMap[chn[0]] ?? 0) * 10;
      } else if (chn.length == 3 && chn[1] == '十') {
        res = (chnMap[chn[0]] ?? 0) * 10 + (chnMap[chn[2]] ?? 0);
      } else {
        // Fallback for long numbers like "一百二十三" - not fully implemented here
        return chn;
      }
      return res.toString();
    });
  }

  Future<String> _cacheFile(String url, int saveTime) async {
    final key = JsEncodeUtils.md5Encode16(url);
    final cached = await _cacheManager.get(key);
    if (cached != null) return cached;

    try {
      final analyzeUrl = AnalyzeUrl(url);
      final content = await analyzeUrl.getResponseBody();
      if (content.isNotEmpty) {
        await _cacheManager.put(key, content);
      }
      return content;
    } catch (e) {
      return "";
    }
  }

  String _parseUrlArg(dynamic args) {
    if (args is List && args.isNotEmpty) return args[0].toString();
    return args.toString();
  }

  // 靜態輔助方法，供其它地方獲取通用 JS
  static String getUtilsJs() {
    return ""; // 目前主要透過 inject() 動態注入
  }
}

// 修正 debugPrint 缺失問題
void debugPrint(String message) {
  // Use a proper logger or just ignore if it's too noisy
}
