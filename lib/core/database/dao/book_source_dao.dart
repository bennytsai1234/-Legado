import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/book_source.dart';
import '../app_database.dart';

/// BookSourceDao - 書源資料存取對象
/// 對應 Android: data/dao/BookSourceDao.kt
class BookSourceDao {
  static const String tableName = 'book_sources';
  static final StreamController<void> _changeController = StreamController<void>.broadcast();

  // 輕量化投影欄位 (對標 Android book_sources_part)
  static const List<String> partColumns = [
    'bookSourceUrl',
    'bookSourceName',
    'bookSourceGroup',
    'customOrder',
    'enabled',
    'enabledExplore',
    'lastUpdateTime',
    'respondTime',
    'weight'
  ];

  Future<Database> get _db async => await AppDatabase.database;

  void _notify() {
    _changeController.add(null);
  }

  /// 監聽輕量化書源清單
  Stream<List<BookSource>> watchAllPart() {
    return _changeController.stream.asyncMap((_) => getAllPart());
  }

  /// 獲取所有書源 (輕量化投影)
  Future<List<BookSource>> getAllPart() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: partColumns,
      orderBy: 'customOrder ASC, lastUpdateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return BookSource.fromJson(maps[i]);
    });
  }

  /// 獲取所有啟用的書源 (輕量化投影)
  Future<List<BookSource>> getEnabledPart() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: partColumns,
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'customOrder ASC',
    );

    return List.generate(maps.length, (i) {
      return BookSource.fromJson(maps[i]);
    });
  }

  /// 獲取完整書源 (包含所有規則)
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

  /// 插入或更新書源
  Future<void> insertOrUpdate(BookSource source) async {
    final db = await _db;
    final map = source.toJson();
    _serializeRules(map);

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
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
    _notify();
  }

  /// 批量啟用/禁用
  Future<void> enableSources(List<String> urls, bool enabled) async {
    final db = await _db;
    await db.update(
      tableName,
      {'enabled': enabled ? 1 : 0},
      where: 'bookSourceUrl IN (${urls.map((_) => '?').join(',')})',
      whereArgs: urls,
    );
    _notify();
  }

  /// 批量刪除
  Future<void> deleteSources(List<String> urls) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'bookSourceUrl IN (${urls.map((_) => '?').join(',')})',
      whereArgs: urls,
    );
    _notify();
  }

  /// 調整排序序號 (高度還原 Android SourceHelp.adjustSortNumber)
  Future<void> adjustSortNumbers() async {
    final sources = await getAllPart();
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
    _notify();
  }

  /// 獲取所有處理後的分組 (高度還原 Android dealGroups)
  Future<List<String>> getGroups() async {
    final db = await _db;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT bookSourceGroup FROM $tableName WHERE bookSourceGroup IS NOT NULL AND bookSourceGroup != ""',
    );

    final groups = <String>{};
    for (final row in result) {
      final groupStr = row['bookSourceGroup'] as String;
      // 處理多種分隔符
      groups.addAll(groupStr.split(RegExp(r'[,;，；\s]+')).where((e) => e.trim().isNotEmpty));
    }
    final sortedGroups = groups.toList()..sort();
    return sortedGroups;
  }

  // 輔助方法：處理 JSON 規則字串
  void _serializeRules(Map<String, dynamic> map) {
    final ruleKeys = ['ruleSearch', 'ruleExplore', 'ruleBookInfo', 'ruleToc', 'ruleContent', 'ruleReview'];
    for (var key in ruleKeys) {
      if (map[key] != null && map[key] is! String) {
        map[key] = jsonEncode(map[key]);
      }
    }
  }

  void _deserializeRules(Map<String, dynamic> map) {
    final ruleKeys = ['ruleSearch', 'ruleExplore', 'ruleBookInfo', 'ruleToc', 'ruleContent', 'ruleReview'];
    for (var key in ruleKeys) {
      if (map[key] != null && map[key] is String && (map[key] as String).isNotEmpty) {
        try {
          map[key] = jsonDecode(map[key]);
        } catch (_) {}
      }
    }
  }
}
