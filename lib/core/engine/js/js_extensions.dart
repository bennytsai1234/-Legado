import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:intl/intl.dart';
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
    // 注入基礎 log
    runtime.onMessage('log', (dynamic args) {
      print('JS_LOG: $args');
    });

    // 實作 java.ajax(url) -> 返回 String body
    runtime.setupFunction('ajax', (dynamic args) async {
      final url = args is List ? args[0].toString() : args.toString();
      try {
        final analyzeUrl = AnalyzeUrl(url, source: source);
        return await analyzeUrl.getResponseBody();
      } catch (e) {
        return e.toString();
      }
    });

    // 實作 java.connect(urlStr) -> 返回物件 {body: "...", url: "...", code: 200}
    runtime.setupFunction('connect', (dynamic args) async {
      final url = args is List ? args[0].toString() : args.toString();
      try {
        final analyzeUrl = AnalyzeUrl(url, source: source);
        // TODO: Create a response object matching Android StrResponse
        final body = await analyzeUrl.getResponseBody();
        return {'body': body, 'url': analyzeUrl.url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': url, 'code': 500};
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
        timeFormat: function(time) { return _timeFormat(time); }
      };
    ''');

    // 註冊同步小函式 (直接透過 evaluate 註冊簡單的 Dart 到 JS 映射)
    // 注意: flutter_js 支援透過 setVariable 注入 Dart 閉包作為同步函式 (取決於 runtime 類型)
    
    runtime.setVariable('_md5Encode', (String str) => JsEncodeUtils.md5Encode(str));
    runtime.setVariable('_md5Encode16', (String str) => JsEncodeUtils.md5Encode16(str));
    runtime.setVariable('_base64Encode', (String str) => JsEncodeUtils.base64Encode(str));
    runtime.setVariable('_base64Decode', (String str) => JsEncodeUtils.base64Decode(str));
    runtime.setVariable('_timeFormat', (dynamic time) {
      final dt = DateTime.fromMillisecondsSinceEpoch(time is int ? time : int.parse(time.toString()));
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    });
  }
}
