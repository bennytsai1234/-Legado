import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/book_source.dart';
import '../app_database.dart';

/// BookSourceDao - 書源資料存取對象
class BookSourceDao {
  static const String tableName = 'book_sources';

  Future<Database> get _db async => await AppDatabase.database;

  /// 插入或更新書源
  Future<void> insertOrUpdate(BookSource source) async {
    final db = await _db;
    final map = source.toJson();

    // 處理巢狀規則物件轉換為 JSON 字串存儲
    _serializeRules(map);

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入或更新
  Future<void> insertOrUpdateAll(List<BookSource> sources) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final source in sources) {
        final map = source.toJson();
        _serializeRules(map);
        await txn.insert(
          tableName,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 獲取所有書源
  Future<List<BookSource>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'customOrder ASC, lastUpdateTime DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      _deserializeRules(map);
      return BookSource.fromJson(map);
    });
  }

  /// 根據 URL 獲取書源
  Future<BookSource?> getByUrl(String url) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );

    if (maps.isEmpty) return null;
    final map = Map<String, dynamic>.from(maps.first);
    _deserializeRules(map);
    return BookSource.fromJson(map);
  }

  /// 獲取所有啟用的書源
  Future<List<BookSource>> getEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'customOrder ASC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      _deserializeRules(map);
      return BookSource.fromJson(map);
    });
  }

  /// 更新啟用狀態
  Future<void> updateEnabled(String url, bool enabled) async {
    final db = await _db;
    await db.update(
      tableName,
      {'enabled': enabled ? 1 : 0},
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );
  }

  /// 調整所有書源的排序序號，確保連續性 (對應 Android SourceHelp.adjustSortNumber)
  Future<void> adjustSortNumbers() async {
    final sources = await getAll();
    final db = await _db;
    await db.transaction((txn) async {
      for (int i = 0; i < sources.length; i++) {
        await txn.update(
          tableName,
          {'customOrder': i},
          where: 'bookSourceUrl = ?',
          whereArgs: [sources[i].bookSourceUrl],
        );
      }
    });
  }

  /// 刪除書源
  Future<void> delete(String url) async {
    final db = await _db;
    await db.delete(tableName, where: 'bookSourceUrl = ?', whereArgs: [url]);
  }

  /// 獲取所有分組
  Future<List<String>> getGroups() async {
    final db = await _db;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT bookSourceGroup FROM $tableName WHERE bookSourceGroup IS NOT NULL AND bookSourceGroup != ""',
    );

    final groups = <String>{};
    for (final row in result) {
      final groupStr = row['bookSourceGroup'] as String;
      groups.addAll(groupStr.split(RegExp(r'[,;，；]')).map((e) => e.trim()));
    }
    return groups.toList()..sort();
  }

  // 輔助方法：將 Model 的 Map 轉換為 DB 存儲格式 (String)
  void _serializeRules(Map<String, dynamic> map) {
    if (map['ruleSearch'] != null) {
      map['ruleSearch'] = jsonEncode(map['ruleSearch']);
    }
    if (map['ruleExplore'] != null) {
      map['ruleExplore'] = jsonEncode(map['ruleExplore']);
    }
    if (map['ruleBookInfo'] != null) {
      map['ruleBookInfo'] = jsonEncode(map['ruleBookInfo']);
    }
    if (map['ruleToc'] != null) {
      map['ruleToc'] = jsonEncode(map['ruleToc']);
    }
    if (map['ruleContent'] != null) {
      map['ruleContent'] = jsonEncode(map['ruleContent']);
    }

    // SQLite 不支援 bool，轉換為 0/1
    map['enabled'] = (map['enabled'] == true) ? 1 : 0;
    map['enabledExplore'] = (map['enabledExplore'] == true) ? 1 : 0;
    map['enabledCookieJar'] = (map['enabledCookieJar'] == true) ? 1 : 0;
  }

  // 輔助方法：將 DB 存儲格式 (String) 還原為 Model Map
  void _deserializeRules(Map<String, dynamic> map) {
    if (map['ruleSearch'] != null && map['ruleSearch'] is String) {
      map['ruleSearch'] = jsonDecode(map['ruleSearch']);
    }
    if (map['ruleExplore'] != null && map['ruleExplore'] is String) {
      map['ruleExplore'] = jsonDecode(map['ruleExplore']);
    }
    if (map['ruleBookInfo'] != null && map['ruleBookInfo'] is String) {
      map['ruleBookInfo'] = jsonDecode(map['ruleBookInfo']);
    }
    if (map['ruleToc'] != null && map['ruleToc'] is String) {
      map['ruleToc'] = jsonDecode(map['ruleToc']);
    }
    if (map['ruleContent'] != null && map['ruleContent'] is String) {
      map['ruleContent'] = jsonDecode(map['ruleContent']);
    }

    map['enabled'] = map['enabled'] == 1;
    map['enabledExplore'] = map['enabledExplore'] == 1;
    map['enabledCookieJar'] = map['enabledCookieJar'] == 1;
  }
}
