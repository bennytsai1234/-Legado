import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../../services/chinese_utils.dart';
import '../../services/encoding_detect.dart';
import 'package:fast_gbk/fast_gbk.dart';

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/backstage_webview.dart';
import '../../services/source_verification_service.dart';
import 'query_ttf.dart';

/// JsExtensions - JS 橋接擴展
/// 對應 Android: help/JsExtensions.kt
class JsExtensions {
  final JavascriptRuntime runtime;
  final BaseSource? source;
  final CookieStore _cookieStore = CookieStore();
  final CacheManager _cacheManager = CacheManager();
  static final Map<String, QueryTTF> _ttfCache = {};
  static final Map<String, String> _fontReplaceCache = {};
  
  // 全域 JS 作用域 (模擬 Android SharedJsScope)
  static final Map<String, dynamic> _sharedScope = {};

  JsExtensions(this.runtime, {this.source});

  /// 注入 java 物件及函式
  void inject() {
    // 實作 java.put
    runtime.onMessage('put', (dynamic args) {
      if (args is List && args.length >= 2) {
        _sharedScope[args[0].toString()] = args[1];
      }
    });

    // 實作 java.get
    runtime.onMessage('get', (dynamic args) {
      return _sharedScope[args.toString()];
    });

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
          final List<Future<String>> futures =
              urls.map((url) => AnalyzeUrl(url).getResponseBody()).toList();
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
        final Map<String, dynamic> headers = Map<String, dynamic>.from(
          args[1] ?? {},
        );
        final response = await HttpClient().client.get(
          url,
          options: Options(headers: headers),
        );
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map,
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
        final Map<String, dynamic> headers = Map<String, dynamic>.from(
          args[2] ?? {},
        );
        final response = await HttpClient().client.post(
          url,
          data: body,
          options: Options(headers: headers),
        );
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map,
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
        action,
        transformation,
        key,
        iv,
        data,
        outputFormat: outputFormat,
      );
    });

    // 實作 java.strToBytes
    runtime.onMessage('strToBytes', (dynamic args) {
      final str = args[0].toString();
      final charset = args.length > 1 ? args[1].toString() : 'UTF-8';
      if (charset.toUpperCase().contains('GBK') ||
          charset.toUpperCase().contains('GB2312')) {
        return gbk.encode(str);
      }
      return utf8.encode(str);
    });

    // 實作 java.bytesToStr
    runtime.onMessage('bytesToStr', (dynamic args) {
      final List<int> bytes = List<int>.from(args[0]);
      final charset = args.length > 1 ? args[1].toString() : 'UTF-8';
      if (charset.toUpperCase().contains('GBK') ||
          charset.toUpperCase().contains('GB2312')) {
        return gbk.decode(bytes);
      }
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
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
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
      final charset =
          args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (charset.toUpperCase().contains('GBK') ||
            charset.toUpperCase().contains('GB2312')) {
          return gbk.decode(bytes);
        }
        return utf8.decode(bytes, allowMalformed: true);
      }
      return "";
    });

    // 注入輔助函式
    runtime.onMessage(
      '_md5Encode',
      (dynamic args) => JsEncodeUtils.md5Encode(args.toString()),
    );
    runtime.onMessage(
      '_md5Encode16',
      (dynamic args) => JsEncodeUtils.md5Encode16(args.toString()),
    );
    runtime.onMessage(
      '_base64Encode',
      (dynamic args) => JsEncodeUtils.base64Encode(args.toString()),
    );
    runtime.onMessage('_base64Decode', (dynamic args) {
      final str = args is List ? args[0].toString() : args.toString();
      final charset =
          args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      return JsEncodeUtils.base64Decode(str, charset: charset);
    });
    runtime.onMessage(
      '_hexEncode',
      (dynamic args) => hex.encode(utf8.encode(args.toString())),
    );
    runtime.onMessage(
      '_hexDecode',
      (dynamic args) => utf8.decode(hex.decode(args.toString())),
    );
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

    // 實作 java.webView
    runtime.onMessage('webView', (dynamic args) async {
      try {
        final html = args[0]?.toString();
        final url = args.length > 1 ? args[1]?.toString() : null;
        final js = args.length > 2 ? args[2]?.toString() : null;
        
        final webView = BackstageWebView(
          html: html,
          url: url,
          javaScript: js,
        );
        
        final response = await webView.getStrResponse();
        return response['body']?.toString() ?? "";
      } catch (e) {
        debugPrint('webView error: $e');
        return e.toString();
      }
    });

    // 實作 java.startBrowserAwait (高度還原 Android)
    runtime.onMessage('startBrowserAwait', (dynamic args) async {
      try {
        final url = args[0].toString();
        final title = args.length > 1 ? args[1].toString() : "驗證";
        
        final result = await SourceVerificationService().getVerificationResult(
          sourceKey: source?.getKey() ?? "unknown",
          url: url,
          title: title,
          useBrowser: true,
        );
        
        return {'body': result, 'url': url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': args[0].toString(), 'code': 500};
      }
    });

    // 實作 java.getVerificationCode
    runtime.onMessage('getVerificationCode', (dynamic args) async {
      try {
        final imageUrl = args.toString();
        return await SourceVerificationService().getVerificationResult(
          sourceKey: source?.getKey() ?? "unknown",
          url: imageUrl,
          title: "請輸入驗證碼",
          useBrowser: false,
        );
      } catch (e) {
        return "";
      }
    });

    // 實作 java.unArchiveFile (高度還原 Android)
    runtime.onMessage('unArchiveFile', (dynamic args) async {
      try {
        final relPath = args.toString();
        final file = File(p.join((await getApplicationDocumentsDirectory()).path, relPath));
        if (!await file.exists()) return "";

        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        final tempDir = await getTemporaryDirectory();
        final outPath = p.join(tempDir.path, "ArchiveTemp", md5.convert(utf8.encode(file.path)).toString().substring(0, 16));
        
        for (final entry in archive) {
          if (entry.isFile) {
            final data = entry.content as List<int>;
            File(p.join(outPath, entry.name))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
        return p.relative(outPath, from: tempDir.path);
      } catch (_) {
        return "";
      }
    });

    // 實作 java.getZipByteArrayContent
    runtime.onMessage('getZipByteArrayContent', (dynamic args) async {
      try {
        final url = args[0].toString();
        final innerPath = args[1].toString();
        
        Uint8List? bytes;
        if (url.startsWith('http')) {
          final analyzeUrl = AnalyzeUrl(url, source: source);
          bytes = await analyzeUrl.getByteArray();
        } else {
          bytes = Uint8List.fromList(hex.decode(url));
        }
        
        if (bytes == null) return null;
        final archive = ZipDecoder().decodeBytes(bytes);
        final file = archive.findFile(innerPath);
        return file?.content as List<int>?;
      } catch (_) {
        return null;
      }
    });

    // 實作 java.getTxtInFolder
    runtime.onMessage('getTxtInFolder', (dynamic args) async {
      try {
        final relPath = args.toString();
        final tempDir = await getTemporaryDirectory();
        final folder = Directory(p.join(tempDir.path, relPath));
        if (!await folder.exists()) return "";

        final buffer = StringBuffer();
        final files = folder.listSync().whereType<File>().toList();
        for (var f in files) {
          final bytes = await f.readAsBytes();
          final charset = EncodingDetect.getEncode(bytes);
          String content;
          if (charset == "GBK") {
            content = gbk.decode(bytes);
          } else {
            content = utf8.decode(bytes, allowMalformed: true);
          }
          buffer.writeln(content);
        }
        return buffer.toString();
      } catch (_) {
        return "";
      }
    });

    runtime.onMessage('t2s', (dynamic args) => ChineseUtils.t2s(args.toString()));
    runtime.onMessage('s2t', (dynamic args) => ChineseUtils.s2t(args.toString()));

    // 實作 java.toNumChapter (高度還原 Android)
    runtime.onMessage('_toNumChapter', (dynamic args) {
      final s = args.toString();
      final regex = RegExp(r'(.*?)([〇零一二三四五六七八九十百千萬億壹貳叁肆伍陸柒捌玖拾佰仟]+)(.*)');
      final match = regex.firstMatch(s);
      if (match != null) {
        final intStr = _chineseNumToInt(match.group(2)!);
        return "${match.group(1)}$intStr${match.group(3)}";
      }
      return s;
    });

    // 實作 java.timeFormatUTC
    runtime.onMessage('timeFormatUTC', (dynamic args) {
      try {
        final time = args[0] as int;
        final format = args[1].toString();
        final offsetMs = args[2] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true).add(Duration(milliseconds: offsetMs));
        return DateFormat(format).format(date);
      } catch (_) { return ""; }
    });

    // 實作 java.openUrl
    runtime.onMessage('openUrl', (dynamic args) async {
      try {
        final url = args is List ? args[0].toString() : args.toString();
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return true;
      } catch (_) { return false; }
    });

    runtime.onMessage('queryTTF', (dynamic args) async {
      try {
        final dataStr = args[0].toString();
        final useCache = args.length > 1 ? args[1] as bool : true;
        
        String key = "";
        if (useCache) {
          key = md5.convert(utf8.encode(dataStr)).toString();
          if (_ttfCache.containsKey(key)) {
            return key;
          }
        }
        
        Uint8List? buffer;
        if (dataStr.startsWith('http')) {
          final analyzeUrl = AnalyzeUrl(dataStr);
          buffer = await analyzeUrl.getByteArray();
        } else {
          buffer = base64Decode(dataStr);
        }
        
        if (buffer != null) {
          final qTTF = QueryTTF(buffer);
          final cacheKey = key.isNotEmpty ? key : md5.convert(buffer).toString();
          _ttfCache[cacheKey] = qTTF;
          return cacheKey;
        }
      } catch (e) {
        debugPrint('queryTTF error: $e');
      }
      return null;
    });

    runtime.onMessage('replaceFont', (dynamic args) {
      try {
        final text = args[0]?.toString() ?? "";
        final errorKey = args[1]?.toString();
        final correctKey = args[2]?.toString();
        
        // 增加緩存 key，包含文本與字體 ID
        final cacheKey = "${errorKey}_${correctKey}_${text.hashCode}";
        if (_fontReplaceCache.containsKey(cacheKey)) {
          return _fontReplaceCache[cacheKey];
        }

        final errorTTF = errorKey != null ? _ttfCache[errorKey] : null;
        final correctTTF = correctKey != null ? _ttfCache[correctKey] : null;

        if (errorTTF == null || correctTTF == null) return text;
        
        final StringBuffer result = StringBuffer();
        for (final int codePoint in text.runes) {
          if (errorTTF.isBlankUnicode(codePoint)) {
            result.writeCharCode(codePoint);
            continue;
          }
          String? glyf = errorTTF.getGlyfByUnicode(codePoint);
          if (errorTTF.getGlyfIdByUnicode(codePoint) == 0) glyf = null;
          
          if (glyf == null) {
            result.writeCharCode(codePoint);
            continue;
          }
          
          final int newCode = correctTTF.getUnicodeByGlyf(glyf);
          if (newCode != 0) {
            result.writeCharCode(newCode);
          } else {
            result.writeCharCode(codePoint);
          }
        }
        
        final finalResult = result.toString();
        if (_fontReplaceCache.length > 500) _fontReplaceCache.clear();
        _fontReplaceCache[cacheKey] = finalResult;
        
        return finalResult;
      } catch (e) {
        debugPrint('replaceFont error: $e');
        return args[0]?.toString() ?? "";
      }
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
        t2s: function(text) { return sendMessage('t2s', JSON.stringify(text)); },
        s2t: function(text) { return sendMessage('s2t', JSON.stringify(text)); },
        strToBytes: function(str, charset) { return sendMessage('strToBytes', JSON.stringify([str, charset])); },
        bytesToStr: function(bytes, charset) { return sendMessage('bytesToStr', JSON.stringify([bytes, charset])); },
        readFile: function(path) { return sendMessage('readFile', JSON.stringify(path)); },
        readTxtFile: function(path, charset) { return sendMessage('readTxtFile', JSON.stringify([path, charset])); },
        downloadFile: function(url) { return sendMessage('downloadFile', JSON.stringify(url)); },
        toNumChapter: function(s) { return sendMessage('_toNumChapter', JSON.stringify(s)); },
        importScript: function(path) { return sendMessage('importScript', JSON.stringify(path)); },
        cacheFile: function(url, saveTime) { return sendMessage('cacheFile', JSON.stringify([url, saveTime])); },
        queryTTF: function(data, useCache) {
          if (useCache === undefined) useCache = true;
          var ttfId = sendMessage('queryTTF', JSON.stringify([data, useCache]));
          if (!ttfId) return null;
          return { _ttfId: ttfId };
        },
        replaceFont: function(text, errTTF, correctTTF) {
          var eId = errTTF ? errTTF._ttfId : null;
          var cId = correctTTF ? correctTTF._ttfId : null;
          return sendMessage('replaceFont', JSON.stringify([text, eId, cId]));
        },
        startBrowserAwait: function(url, title) {
          return sendMessage('startBrowserAwait', JSON.stringify([url, title]));
        },
        getVerificationCode: function(imageUrl) {
          return sendMessage('getVerificationCode', JSON.stringify(imageUrl));
        },
        unArchiveFile: function(zipPath) {
          return sendMessage('unArchiveFile', JSON.stringify(zipPath));
        },
        getZipByteArrayContent: function(url, path) {
          return sendMessage('getZipByteArrayContent', JSON.stringify([url, path]));
        },
        getTxtInFolder: function(path) {
          return sendMessage('getTxtInFolder', JSON.stringify(path));
        },
        webView: function(html, url, js) {
          return sendMessage('webView', JSON.stringify([html, url, js]));
        }
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

  /// 中文數字轉整數 (深度還原 Android chineseNumToInt)
  int _chineseNumToInt(String chNum) {
    final chnMap = {
      '零': 0, '〇': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10,
      '壹': 1, '貳': 2, '叁': 3, '肆': 4, '伍': 5, '陸': 6, '柒': 7, '捌': 8, '玖': 9, '拾': 10,
      '百': 100, '佰': 100, '千': 1000, '仟': 1000, '萬': 10000, '億': 100000000,
    };

    if (chNum.length > 1 && RegExp(r'^[〇零一二三四五六七八九壹貳叁肆伍陸柒捌玖]+$').hasMatch(chNum)) {
      String res = "";
      for (var i = 0; i < chNum.length; i++) {
        res += (chnMap[chNum[i]] ?? 0).toString();
      }
      return int.tryParse(res) ?? -1;
    }

    int result = 0;
    int tmp = 0;
    int billion = 0;

    try {
      for (var i = 0; i < chNum.length; i++) {
        final val = chnMap[chNum[i]] ?? 0;
        if (val == 100000000) {
          result += tmp;
          result *= val;
          billion = billion * 100000000 + result;
          result = 0; tmp = 0;
        } else if (val == 10000) {
          result += tmp;
          result *= val;
          tmp = 0;
        } else if (val >= 10) {
          if (tmp == 0) tmp = 1;
          result += val * tmp;
          tmp = 0;
        } else {
          tmp = (i >= 2 && i == chNum.length - 1 && (chnMap[chNum[i - 1]] ?? 0) > 10)
              ? val * (chnMap[chNum[i - 1]] ?? 0) ~/ 10
              : tmp * 10 + val;
        }
      }
      return result + tmp + billion;
    } catch (_) {
      return -1;
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
