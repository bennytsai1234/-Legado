import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:uuid/uuid.dart';
import 'package:convert/convert.dart';
import 'js_encode_utils.dart';
import '../analyze_url.dart';
import '../../models/base_source.dart';

/// JsExtensions - JS 橋接擴展
/// 對應 Android: help/JsExtensions.kt
class JsExtensions {
  final JavascriptRuntime runtime;
  final BaseSource? source;

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
        final analyzeUrl = AnalyzeUrl(url, source: source);
        return await analyzeUrl.getResponseBody();
      } catch (e) {
        return e.toString();
      }
    });

    // 實作 java.connect(urlStr) -> 返回物件 {body: "...", url: "...", code: 200}
    runtime.onMessage('connect', (dynamic args) async {
      try {
        final url = _parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url, source: source);
        final body = await analyzeUrl.getResponseBody();
        return {'body': body, 'url': analyzeUrl.url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': args.toString(), 'code': 500};
      }
    });

    // 注入 java 物件及其屬性
    runtime.evaluate('''
      var java = {
        ajax: function(url) { return sendMessage('ajax', JSON.stringify(url)); },
        connect: function(url) { return sendMessage('connect', JSON.stringify(url)); },
        log: function(msg) { sendMessage('log', JSON.stringify(msg)); },
        md5Encode: function(str) { return _md5Encode(str); },
        md5Encode16: function(str) { return _md5Encode16(str); },
        base64Encode: function(str) { return _base64Encode(str); },
        base64Decode: function(str) { return _base64Decode(str); },
        encodeURI: function(str, enc) { return _encodeURI(str, enc); },
        hexEncode: function(str) { return _hexEncode(str); },
        hexDecode: function(hex) { return _hexDecode(hex); },
        randomUUID: function() { return _randomUUID(); },
        timeFormat: function(time) { return _timeFormat(time); }
      };
    ''');

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
