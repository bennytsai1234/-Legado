import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:archive/archive_io.dart';

import '../database/dao/book_dao.dart';
import '../models/book.dart';
import '../models/book_progress.dart';
import '../constant/prefer_key.dart';
import 'backup_aes_service.dart';
import 'restore_service.dart';

/// WebDAVService - WebDAV 備份與還原服務
/// 對應 Android: help/AppWebDav.kt
class WebDAVService extends ChangeNotifier {
  static final WebDAVService _instance = WebDAVService._internal();
  factory WebDAVService() => _instance;
  WebDAVService._internal();

  final BookDao _bookDao = BookDao();
  final BackupAESService _aesService = BackupAESService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<webdav.Client> _getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(PreferKey.webDavUrl) ?? '';
    final user = prefs.getString(PreferKey.webDavAccount) ?? '';
    final pwdEnc = prefs.getString(PreferKey.webDavPassword) ?? '';
    
    if (url.isEmpty || user.isEmpty || pwdEnc.isEmpty) {
      throw Exception('WebDAV not configured');
    }

    final password = await _aesService.decrypt(pwdEnc);
    
    final client = webdav.newClient(url, user: user, password: password);
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);
    return client;
  }

  /// 獲取最新備份檔案資訊 (對標 Android lastBackUp)
  Future<webdav.File?> lastBackUp() async {
    try {
      final client = await _getClient();
      final files = await client.readDir('/legado');
      final backupFiles = files.cast<webdav.File>().where((f) => f.name != null && f.name!.startsWith('backup_') && f.name!.endsWith('.zip')).toList();
      if (backupFiles.isEmpty) return null;
      
      // 按修改時間排序 (最晚的在前)
      backupFiles.sort((a, b) {
        final String timeA = a.mTime?.toString() ?? "";
        final String timeB = b.mTime?.toString() ?? "";
        return timeB.compareTo(timeA);
      });
      return backupFiles.first;
    } catch (e) {
      debugPrint('Get last backup failed: $e');
      return null;
    }
  }

  /// 備份所有資料至 WebDAV
  Future<bool> backup() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      await client.mkdir('/legado');

      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      // 1. 匯集所有資料
      final books = await _bookDao.getAll();
      _addJsonToZip(encoder, 'bookshelf.json', books.map((e) => e.toJson()).toList(), dir);
      
      // ... 其他 DAO 資料備份邏輯 (目前略過以簡化)

      encoder.close();

      // 2. 上傳
      await client.writeFromFile(zipPath, '/legado/legado_backup.zip');
      
      // 3. 備份成功後更新時間戳
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_backup', DateTime.now().millisecondsSinceEpoch);

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Backup Failed: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  void _addJsonToZip(
    ZipFileEncoder encoder,
    String fileName,
    List<dynamic> data,
    Directory dir,
  ) {
    if (data.isEmpty) return;
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(jsonEncode(data));
    encoder.addFile(file);
    file.deleteSync();
  }

  /// 從特定檔案還原資料
  Future<bool> restoreFromFile(String remotePath) async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_restore_temp.zip';
      final localFile = File(zipPath);

      await client.read2File(remotePath, localFile.path);
      final success = await RestoreService().restoreFromZip(localFile);

      if (await localFile.exists()) await localFile.delete();
      _isSyncing = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Restore from file failed: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// 從 WebDAV 還原資料
  Future<bool> restore() async {
    return restoreFromFile('/legado/legado_backup.zip');
  }

  /// 上傳書籍進度 (對應 Android WebService / syncProgress)
  Future<void> uploadBookProgress(Book book) async {
    try {
      final client = await _getClient();
      await client.mkdir('/legado/progress');
      
      final progress = BookProgress(
        name: book.name,
        author: book.author,
        durChapterIndex: book.durChapterIndex,
        durChapterPos: book.durChapterPos,
        durChapterTime: DateTime.now().millisecondsSinceEpoch,
      );
      
      final data = jsonEncode(progress.toJson());
      final fileName = '${book.name.hashCode}.json';
      
      // 這裡簡化為直接寫入，實際應使用緩存
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(data);
      await client.writeFromFile(file.path, '/legado/progress/$fileName');
    } catch (e) {
      debugPrint('Upload progress failed: $e');
    }
  }
}
