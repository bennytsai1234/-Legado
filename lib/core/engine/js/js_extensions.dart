import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'js_encode_utils.dart';
import 'package:legado_reader/core/models/base_source.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'package:legado_reader/core/services/encoding_detect.dart';
import 'package:fast_gbk/fast_gbk.dart';

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'query_ttf.dart';

// 導入拆分後的擴展
import 'extensions/js_network_extensions.dart';
import 'extensions/js_crypto_extensions.dart';
import 'extensions/js_string_extensions.dart';

/// JsExtensions - JS 橋接擴展
/// 對應 Android: help/JsExtensions.kt
class JsExtensions {
  final JavascriptRuntime runtime;
  final BaseSource? source;
  final CookieStore cookieStore = CookieStore();
  final CacheManager cacheManager = CacheManager();
  static final Map<String, QueryTTF> ttfCache = {};
  static final Map<String, String> fontReplaceCache = {};
  
  // 全域 JS 作用域 (模擬 Android SharedJsScope)
  static final Map<String, dynamic> sharedScope = {};

  JsExtensions(this.runtime, {this.source});

  /// 注入 java 物件及函式
  void inject() {
    // 1. 注入基礎核心功能
    _injectCoreExtensions();

    // 2. 注入拆分後的擴展功能
    injectNetworkExtensions();
    injectCryptoExtensions();
    injectStringExtensions();

    // 3. 注入 java 物件及其屬性 (JS 端的封裝層)
    _injectJavaObjectJs();
  }

  void _injectCoreExtensions() {
    // 實作 java.put
    runtime.onMessage('put', (dynamic args) {
      if (args is List && args.length >= 2) {
        sharedScope[args[0].toString()] = args[1];
      }
    });

    // 實作 java.get
    runtime.onMessage('get', (dynamic args) {
      return sharedScope[args.toString()];
    });

    // 實作 java.log
    runtime.onMessage('log', (dynamic args) {
      debugPrint('JS_LOG: $args');
    });

    // 實作 java.toast
    runtime.onMessage('toast', (dynamic args) {
      debugPrint('JS_TOAST: $args');
    });

    // 實作 java.downloadFile
    runtime.onMessage('downloadFile', (dynamic args) async {
      final url = args.toString();
      try {
        final key = JsEncodeUtils.md5Encode16(url);
        final tempDir = await getTemporaryDirectory();
        final savePath = p.join(tempDir.path, "downloads", key);
        final file = File(savePath);
        if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
        }
        final HttpClient client = HttpClient(); // Ensure this is available or use dio directly
        await client.client.download(url, savePath);
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
          if (ttfCache.containsKey(key)) {
            return key;
          }
        }
        
        Uint8List? buffer;
        if (dataStr.startsWith('http')) {
          // This would ideally use a network extension method, but keeping here for core logic
          final client = HttpClient().client;
          final response = await client.get<List<int>>(dataStr, options: Options(responseType: ResponseType.bytes));
          buffer = response.data != null ? Uint8List.fromList(response.data!) : null;
        } else {
          buffer = base64Decode(dataStr);
        }
        
        if (buffer != null) {
          final qTTF = QueryTTF(buffer);
          final cacheKey = key.isNotEmpty ? key : md5.convert(buffer).toString();
          ttfCache[cacheKey] = qTTF;
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
        
        final cacheKey = "${errorKey}_${correctKey}_${text.hashCode}";
        if (fontReplaceCache.containsKey(cacheKey)) {
          return fontReplaceCache[cacheKey];
        }

        final errorTTF = errorKey != null ? ttfCache[errorKey] : null;
        final correctTTF = correctKey != null ? ttfCache[correctKey] : null;

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
        if (fontReplaceCache.length > 500) fontReplaceCache.clear();
        fontReplaceCache[cacheKey] = finalResult;
        
        return finalResult;
      } catch (e) {
        debugPrint('replaceFont error: $e');
        return args[0]?.toString() ?? "";
      }
    });

    runtime.onMessage('importScript', (dynamic args) async {
      final path = args.toString();
      if (path.startsWith('http')) {
        return await cacheFile(path, 0);
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
      return await cacheFile(url, saveTime);
    });
  }

  void _injectJavaObjectJs() {
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
  }

  Future<String> cacheFile(String url, int saveTime) async {
    final key = JsEncodeUtils.md5Encode16(url);
    final cached = await cacheManager.get(key);
    if (cached != null) return cached;

    try {
      // Use core logic or network extensions
      final HttpClient client = HttpClient();
      final response = await client.client.get(url);
      final content = response.data.toString();
      if (content.isNotEmpty) {
        await cacheManager.put(key, content);
      }
      return content;
    } catch (e) {
      return "";
    }
  }

  static String getUtilsJs() {
    return "";
  }
}
