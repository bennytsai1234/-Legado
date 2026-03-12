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
import '../models/book_group.dart';
import '../models/book_progress.dart';
import '../constant/prefer_key.dart';
import 'backup_aes_service.dart';

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
  final BackupAESService _aesService = BackupAESService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  WebDAVService._internal();

  Future<webdav.Client> _getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(PreferKey.webDavUrl) ?? '';
    final user = prefs.getString(PreferKey.webDavAccount) ?? '';
    final pwd = prefs.getString(PreferKey.webDavPassword) ?? '';
    if (url.isEmpty || user.isEmpty || pwd.isEmpty) {
      throw Exception('WebDAV 未配置');
    }
    return webdav.newClient(url, user: user, password: pwd, debug: kDebugMode);
  }

  /// 確保基礎目錄存在 (對標 Android upConfig)
  Future<void> _ensureDirs(webdav.Client client) async {
    final dirs = ['/legado', '/legado/bookProgress', '/legado/books', '/legado/background'];
    for (final dir in dirs) {
      try {
        await client.mkdir(dir);
      } catch (_) {}
    }
  }

  /// 備份資料到 WebDAV
  Future<bool> backup() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      await _ensureDirs(client);

      // 1. 取得資料庫內容
      final books = await _bookDao.getAll();
      final sources = await _sourceDao.getAll();
      final rules = await _ruleDao.getAll();
      final groups = await _groupDao.getAll();
      final bookmarks = await _bookmarkDao.getAll();
      final records = await _recordDao.getAll();

      // 2. 取得設定檔內容 (對標 Android SharedPreferences 備份)
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> config = {};
      for (final key in prefs.getKeys()) {
        dynamic val = prefs.get(key);
        // 深度還原：對敏感資訊進行 AES 加密
        if (key == PreferKey.webDavPassword) {
          val = await _aesService.encrypt(val.toString());
        }
        config[key] = val;
      }

      // 3. 建立 ZIP 封裝
      final encoder = ZipFileEncoder();
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_backup.zip';

      encoder.create(zipPath);

      _addJsonToZip(encoder, 'books.json', books.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookSources.json', sources.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'replaceRules.json', rules.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookGroups.json', groups.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookmarks.json', bookmarks.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'readRecords.json', records.map((e) => e.toJson()).toList(), dir);
      // 深度還原：加入設定檔備份
      _addJsonToZip(encoder, 'config.json', [config], dir);

      encoder.close();

      // 4. 上傳
      final localFile = File(zipPath);
      final fileName = "backup_${DateTime.now().millisecondsSinceEpoch}.zip";
      await client.writeFromFile(localFile.path, '/legado/$fileName');

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

  /// 上傳書籍閱讀進度 (對標 Android uploadBookProgress)
  Future<void> uploadBookProgress(Book book) async {
    try {
      final client = await _getClient();
      await _ensureDirs(client);

      final progress = BookProgress(
        name: book.name,
        author: book.author,
        durChapterIndex: book.durChapterIndex,
        durChapterPos: book.durChapterPos,
        durChapterTime: book.durChapterTime,
        durChapterTitle: book.durChapterTitle,
      );

      final jsonStr = jsonEncode(progress.toJson());
      final fileName = "${book.name}_${book.author}.json".replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonStr);

      await client.writeFromFile(tempFile.path, '/legado/bookProgress/$fileName');
      
      // 更新本地同步時間
      book.syncTime = DateTime.now().millisecondsSinceEpoch;
      await _bookDao.insertOrUpdate(book);
      
      await tempFile.delete();
    } catch (e) {
      debugPrint("WebDAV Upload Progress Failed: $e");
    }
  }

  /// 上傳匯出的檔案 (對標 Android exportWebDav)
  Future<void> uploadFile(String localPath, String remoteFileName) async {
    try {
      final client = await _getClient();
      await _ensureDirs(client);
      await client.writeFromFile(localPath, '/legado/books/$remoteFileName');
    } catch (e) {
      debugPrint("WebDAV Upload File Failed: $e");
      rethrow;
    }
  }

  /// 下載並同步所有書籍進度 (對標 Android downloadAllBookProgress)
  Future<void> syncAllBookProgress() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final client = await _getClient();
      final files = await client.readDir('/legado/bookProgress');
      
      final books = await _bookDao.getAll();
      for (final book in books) {
        final fileName = "${book.name}_${book.author}.json".replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final match = files.cast<webdav.File?>().firstWhere((f) => f?.name == fileName, orElse: () => null);
        
        if (match != null) {
          // 如果雲端更新時間晚於本地同步時間，則下載
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/temp_progress.json';
          await client.read2File('/legado/bookProgress/$fileName', tempPath);
          
          final jsonStr = await File(tempPath).readAsString();
          final progress = BookProgress.fromJson(jsonDecode(jsonStr));
          
          if (progress.durChapterTime > book.durChapterTime) {
            book.durChapterIndex = progress.durChapterIndex;
            book.durChapterPos = progress.durChapterPos;
            book.durChapterTitle = progress.durChapterTitle ?? "";
            book.durChapterTime = progress.durChapterTime;
            book.syncTime = DateTime.now().millisecondsSinceEpoch;
            await _bookDao.insertOrUpdate(book);
          }
          await File(tempPath).delete();
        }
      }
    } catch (e) {
      debugPrint("WebDAV Sync Progress Failed: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
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
        } catch (e) {
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
          case 'config.json':
            // 深度還原：還原設定檔並解密敏感資訊
            final prefs = await SharedPreferences.getInstance();
            for (final key in item.keys) {
              dynamic val = item[key];
              if (key == PreferKey.webDavPassword) {
                val = await _aesService.decrypt(val.toString());
              }
              if (val is String) await prefs.setString(key, val);
              if (val is int) await prefs.setInt(key, val);
              if (val is bool) await prefs.setBool(key, val);
              if (val is double) await prefs.setDouble(key, val);
            }
            break;
          // note: BookGroupDao missing insert, skip for now or add later
        }
      }
    }
  }
}
