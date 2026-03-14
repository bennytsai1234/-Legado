import 'package:flutter/foundation.dart';
import 'web/web_service_base.dart';
import 'web/web_service_handlers.dart';
import 'web/web_service_utils.dart';

export 'web/web_service_utils.dart';

/// WebService - 本地 Web 伺服器 (重構後)
/// 對應 Android: service/WebService.kt 與 web/HttpServer.kt
/// 透過繼承與 Extension 將邏輯拆分至各個子檔案
class WebService extends WebServiceBase {
  static final WebService _instance = WebService._internal();
  factory WebService() => _instance;

  WebService._internal();

  /// 啟動 Web 服務器
  Future<void> start({int port = 8659}) async {
    await startServer(
      port: port,
      handler: handleRequest,
      getIp: getLocalIpAddress,
    );
  }

  /// 停止 Web 伺服器
  Future<void> stop() async {
    await stopServer();
  }
}
