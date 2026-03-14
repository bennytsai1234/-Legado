import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/database/app_database.dart';
import 'package:legado_reader/core/models/book_source.dart';

/// BookSourceDao - 書源資料存取對象
/// 對應 Android: data/dao/BookSourceDao.kt
class BookSourceDao {
  static final BookSourceDao _instance = BookSourceDao._internal();
  factory BookSourceDao() => _instance;
  BookSourceDao._internal();

  Future<Database> get _db async => await AppDatabase.database;

  /// 獲取所有書源 (完整數據，謹慎使用)
  Future<List<BookSource>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('book_sources', orderBy: 'customOrder ASC');
    return List.generate(maps.length, (i) => BookSource.fromJson(maps[i]));
  }

  /// 獲取書源部分資訊 (僅用於列表顯示，防止 CursorWindow 溢出)
  Future<List<BookSource>> getAllPart() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'book_sources',
      columns: ['bookSourceUrl', 'bookSourceName', 'bookSourceGroup', 'bookSourceType', 'enabled', 'customOrder'],
      orderBy: 'customOrder ASC',
    );
    return List.generate(maps.length, (i) {
      // 僅填充部分欄位的 BookSource 物件
      return BookSource(
        bookSourceUrl: maps[i]['bookSourceUrl'],
        bookSourceName: maps[i]['bookSourceName'],
        bookSourceGroup: maps[i]['bookSourceGroup'],
        bookSourceType: maps[i]['bookSourceType'],
        enabled: maps[i]['enabled'] == 1,
        customOrder: maps[i]['customOrder'],
      );
    });
  }

  /// 獲取所有已啟用的書源 (精簡版，降低記憶體消耗)
  Future<List<BookSource>> getEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'book_sources',
      where: 'enabled = 1',
      columns: ['bookSourceUrl', 'bookSourceName', 'bookSourceGroup', 'bookSourceType', 'enabled', 'customOrder'],
      orderBy: 'customOrder ASC',
    );
    return List.generate(maps.length, (i) {
      return BookSource(
        bookSourceUrl: maps[i]['bookSourceUrl'],
        bookSourceName: maps[i]['bookSourceName'],
        bookSourceGroup: maps[i]['bookSourceGroup'],
        bookSourceType: maps[i]['bookSourceType'],
        enabled: maps[i]['enabled'] == 1,
        customOrder: maps[i]['customOrder'],
      );
    });
  }

  Future<BookSource?> getByUrl(String url) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'book_sources',
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );
    if (maps.isEmpty) return null;
    return BookSource.fromJson(maps.first);
  }

  Future<List<String>> getGroups() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT DISTINCT bookSourceGroup FROM book_sources WHERE bookSourceGroup IS NOT NULL');
    final Set<String> groups = {};
    for (var m in maps) {
      final g = m['bookSourceGroup']?.toString();
      if (g != null) groups.addAll(g.split(',').map((e) => e.trim()));
    }
    return groups.toList()..sort();
  }

  Future<int> getMinOrder() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT MIN(customOrder) as minOrder FROM book_sources');
    return maps.first['minOrder'] ?? 0;
  }

  Future<void> adjustSortNumbers() async {
    final db = await _db;
    final sources = await getAll();
    final batch = db.batch();
    for (int i = 0; i < sources.length; i++) {
      batch.update('book_sources', {'customOrder': i}, where: 'bookSourceUrl = ?', whereArgs: [sources[i].bookSourceUrl]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertOrUpdate(BookSource source) async {
    final db = await _db;
    await db.insert('book_sources', source.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertOrUpdateAll(List<BookSource> sources) async {
    final db = await _db;
    final batch = db.batch();
    for (var s in sources) {
      batch.insert('book_sources', s.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(BookSource source) async {
    final db = await _db;
    await db.update(
      'book_sources',
      source.toJson(),
      where: 'bookSourceUrl = ?',
      whereArgs: [source.bookSourceUrl],
    );
  }

  Future<void> delete(String url) async {
    final db = await _db;
    await db.delete('book_sources', where: 'bookSourceUrl = ?', whereArgs: [url]);
  }

  /// 批量刪除 (修正：接收 URL 列表以對標 UI 需求)
  Future<void> deleteSources(List<String> urls) async {
    final db = await _db;
    final batch = db.batch();
    for (var url in urls) {
      batch.delete('book_sources', where: 'bookSourceUrl = ?', whereArgs: [url]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateCustomOrder(List<BookSource> list) async {
    final db = await _db;
    final batch = db.batch();
    for (int i = 0; i < list.length; i++) {
      batch.update('book_sources', {'customOrder': i}, where: 'bookSourceUrl = ?', whereArgs: [list[i].bookSourceUrl]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> renameGroup(String oldName, String newName) async {
    final db = await _db;
    // 獲取所有包含該分組的書源
    final sources = await db.query('book_sources', where: 'bookSourceGroup LIKE ?', whereArgs: ['%$oldName%']);
    final batch = db.batch();
    for (var map in sources) {
      final String groupStr = map['bookSourceGroup']?.toString() ?? "";
      final List<String> groups = groupStr.split(',').map((e) => e.trim()).toList();
      final idx = groups.indexOf(oldName);
      if (idx != -1) {
        groups[idx] = newName;
        batch.update('book_sources', {'bookSourceGroup': groups.join(',')}, where: 'bookSourceUrl = ?', whereArgs: [map['bookSourceUrl']]);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> removeGroupLabel(String name) async {
    final db = await _db;
    final sources = await db.query('book_sources', where: 'bookSourceGroup LIKE ?', whereArgs: ['%$name%']);
    final batch = db.batch();
    for (var map in sources) {
      final String groupStr = map['bookSourceGroup']?.toString() ?? "";
      final List<String> groups = groupStr.split(',').map((e) => e.trim()).toList();
      if (groups.remove(name)) {
        batch.update('book_sources', {'bookSourceGroup': groups.isEmpty ? null : groups.join(',')}, where: 'bookSourceUrl = ?', whereArgs: [map['bookSourceUrl']]);
      }
    }
    await batch.commit(noResult: true);
  }
}

