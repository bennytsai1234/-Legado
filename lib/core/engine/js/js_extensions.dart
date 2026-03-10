import 'package:flutter_js/flutter_js.dart';
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
      // Log implementation if needed
    });

    // 實作 java.ajax(url) -> 返回 String body
    runtime.onMessage('ajax', (dynamic args) async {
      final url = args is List ? args[0].toString() : args.toString();
      try {
        final analyzeUrl = AnalyzeUrl(url);
        return await analyzeUrl.getResponseBody();
      } catch (e) {
        return e.toString();
      }
    });

    // 實作 java.connect(urlStr) -> 返回物件 {body: "...", url: "...", code: 200}
    runtime.onMessage('connect', (dynamic args) async {
      final url = args is List ? args[0].toString() : args.toString();
      try {
        final analyzeUrl = AnalyzeUrl(url);
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
        md5Encode: function(str) { return _md5Encode(str); },
        md5Encode16: function(str) { return _md5Encode16(str); },
        base64Encode: function(str) { return _base64Encode(str); },
        base64Decode: function(str) { return _base64Decode(str); },
        timeFormat: function(time) { return _timeFormat(time); }
      };
    ''');

    // 註冊同步小函式
    // 注意: 這裡使用 evaluate 注入，因為原本的 setVariable 在當前 runtime 類型中可能不支援 Function
    // 為了保險起見，我們在 JsEngine.evaluate 之前手動處理這些內建變數或是透過 JS wrapper
  }

  // 靜態方法供 JsEngine 使用來初始化上下文
  static String getUtilsJs() {
    return '''
      function _timeFormat(time) {
        // 簡單的 JS 實現，如果需要精確對齊 Dart，則需要透過 sendMessage
        return new Date(time).toISOString();
      }
    ''';
  }
}
