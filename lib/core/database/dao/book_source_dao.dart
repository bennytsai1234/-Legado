import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/book_source.dart';

/// BookSourceDao - 書源資料存取對象
/// 對應 Android: data/dao/BookSourceDao.kt
class BookSourceDao {
  static final BookSourceDao _instance = BookSourceDao._internal();
  factory BookSourceDao() => _instance;
  BookSourceDao._internal();

  Future<Database> get _db async => await AppDatabase.database;

  Future<List<BookSource>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('book_sources', orderBy: 'customOrder ASC');
    return List.generate(maps.length, (i) => BookSource.fromJson(maps[i]));
  }

  Future<List<BookSource>> getAllPart() => getAll();

  Future<List<BookSource>> getEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'book_sources',
      where: 'enabled = 1',
      orderBy: 'customOrder ASC',
    );
    return List.generate(maps.length, (i) => BookSource.fromJson(maps[i]));
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
}
