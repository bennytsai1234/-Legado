import 'webdav/webdav_base.dart';
import 'webdav/webdav_backup.dart';
import 'webdav/webdav_sync.dart';

export 'webdav/webdav_base.dart';
export 'webdav/webdav_backup.dart';
export 'webdav/webdav_sync.dart';

/// WebDAVService - WebDAV 備份與還原服務 (重構後)
/// 對應 Android: help/AppWebDav.kt
class WebDAVService extends WebDAVBase with WebDAVBackup, WebDAVSync {
  static final WebDAVService _instance = WebDAVService._internal();
  factory WebDAVService() => _instance;
  WebDAVService._internal();

  /// 從 WebDAV 預設路徑還原資料
  Future<bool> restore() async {
    return restoreFromFile('/legado/legado_backup.zip');
  }
}
