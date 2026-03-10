import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:archive/archive_io.dart';

import '../database/dao/book_dao.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/replace_rule_dao.dart';
import '../database/dao/book_group_dao.dart';
import '../database/dao/bookmark_dao.dart';
import '../database/dao/read_record_dao.dart';

import '../models/book.dart';
import '../models/book_source.dart';
import '../models/replace_rule.dart';
import '../models/bookmark.dart';
import '../models/read_record.dart';

/// WebDAVService - WebDAV 備份與還原服務
/// 對應 Android: help/AppWebDav.kt
class WebDAVService extends ChangeNotifier {
  static final WebDAVService _instance = WebDAVService._internal();
  factory WebDAVService() => _instance;

  final BookDao _bookDao = BookDao();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ReplaceRuleDao _ruleDao = ReplaceRuleDao();
  final BookGroupDao _groupDao = BookGroupDao();
  final BookmarkDao _bookmarkDao = BookmarkDao();
  final ReadRecordDao _recordDao = ReadRecordDao();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  WebDAVService._internal();

  Future<webdav.Client> _getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('webdav_url') ?? '';
    final user = prefs.getString('webdav_user') ?? '';
    final pwd = prefs.getString('webdav_password') ?? '';
    if (url.isEmpty || user.isEmpty || pwd.isEmpty) {
      throw Exception('WebDAV 未配置');
    }
    return webdav.newClient(url, user: user, password: pwd, debug: kDebugMode);
  }

  /// 備份資料到 WebDAV
  Future<bool> backup() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      
      // 1. 取得資料庫內容
      final books = await _bookDao.getAll();
      final sources = await _sourceDao.getAll();
      final rules = await _ruleDao.getAll();
      final groups = await _groupDao.getAll();
      final bookmarks = await _bookmarkDao.getAll();
      final records = await _recordDao.getAll();

      // 2. 建立 ZIP 封裝
      final encoder = ZipFileEncoder();
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_backup.zip';
      
      // We encode JSON directly into memory or files
      encoder.create(zipPath);
      
      _addJsonToZip(encoder, 'books.json', books.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookSources.json', sources.map((e) => e?.toJson()).where((e) => e != null).toList(), dir);
      _addJsonToZip(encoder, 'replaceRules.json', rules.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookGroups.json', groups.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookmarks.json', bookmarks.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'readRecords.json', records.map((e) => e.toJson()).toList(), dir);
      
      encoder.close();

      // 3. 確保 WebDAV 目錄存在
      try {
        await client.mkdir('/legado');
      } catch (e) {
        // Ignored, might already exist
      }

      // 4. 上傳
      final localFile = File(zipPath);
      await client.writeFromFile(localFile.path, '/legado/legado_backup.zip');
      
      // 清理暫存檔
      if (await localFile.exists()) await localFile.delete();
      
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

  void _addJsonToZip(ZipFileEncoder encoder, String fileName, List<dynamic> data, Directory dir) {
    if (data.isEmpty) return;
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(jsonEncode(data));
    encoder.addFile(file);
    file.deleteSync();
  }

  /// 從 WebDAV 還原資料
  Future<bool> restore() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_backup_restored.zip';
      final localFile = File(zipPath);
      
      // 1. 下載
      try {
        await client.read2File('/legado/legado_backup.zip', localFile.path);
      } catch (e) {
        throw Exception('Backup file not found on server.');
      }

      // 2. 解開
      final bytes = localFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 3. 匯入資料
      for (final file in archive) {
        if (!file.isFile) continue;
        final data = utf8.decode(file.content as List<int>);
        try {
           final List<dynamic> jsonList = jsonDecode(data);
           await _importData(file.name, jsonList);
        } catch(e) {
           debugPrint('Parse Error for \${file.name}: \$e');
        }
      }

      if (await localFile.exists()) await localFile.delete();
      
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Restore Failed: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _importData(String fileName, List<dynamic> list) async {
    for (var item in list) {
       if (item is Map<String, dynamic>) {
          switch (fileName) {
            case 'books.json':
              await _bookDao.insertOrUpdate(Book.fromJson(item));
              break;
            case 'bookSources.json':
              await _sourceDao.insertOrUpdate(BookSource.fromJson(item));
              break;
            case 'replaceRules.json':
              await _ruleDao.insertOrUpdate(ReplaceRule.fromJson(item));
              break;
            case 'bookGroups.json':
              await _groupDao.insert(BookGroup.fromJson(item));
              break;
            case 'bookmarks.json':
              await _bookmarkDao.insert(Bookmark.fromJson(item));
              break;
            case 'readRecords.json':
              await _recordDao.insert(ReadRecord.fromJson(item));
              break;
             // note: BookGroupDao missing insert, skip for now or add later
          }
       }
    }
  }
}
