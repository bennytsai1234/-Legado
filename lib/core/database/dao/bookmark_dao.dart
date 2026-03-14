import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/database/app_database.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';

/// BookmarkDao - 書籤資料表操作
/// 對應 Android: data/dao/BookmarkDao.kt
class BookmarkDao {
  static const String tableName = 'bookmarks';

  /// 建立表格 (由 [AppDatabase] 調用)
  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookName TEXT NOT NULL,
        bookAuthor TEXT NOT NULL,
        chapterIndex INTEGER NOT NULL,
        chapterPos INTEGER NOT NULL,
        chapterName TEXT NOT NULL,
        bookUrl TEXT NOT NULL,
        bookText TEXT,
        content TEXT,
        time INTEGER NOT NULL
      )
    ''';
  }

  /// 獲取所有書籤並依照書名、作者、章節與位置排序
  Future<List<Bookmark>> getAll() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy:
          'bookName COLLATE NOCASE, bookAuthor COLLATE NOCASE, chapterIndex, chapterPos',
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }

  /// 根據書名與作者獲取書籤
  Future<List<Bookmark>> getByBook(String bookName, String bookAuthor) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'bookName = ? AND bookAuthor = ?',
      whereArgs: [bookName, bookAuthor],
      orderBy: 'chapterIndex',
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }

  /// 搜尋特定書籍的書籤
  Future<List<Bookmark>> searchInBook(
    String bookName,
    String bookAuthor,
    String key,
  ) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
        SELECT * FROM $tableName 
        WHERE bookName = ? AND bookAuthor = ? 
        AND (chapterName LIKE '%' || ? || '%' OR content LIKE '%' || ? || '%')
        ORDER BY chapterIndex
      ''',
      [bookName, bookAuthor, key, key],
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }

  /// 新增書籤，衝突時覆蓋
  Future<void> insert(Bookmark bookmark) async {
    final db = await AppDatabase.database;
    await db.insert(
      tableName,
      bookmark.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppEventBus().fire("up_bookmark");
  }

  /// 更新書籤
  Future<void> update(Bookmark bookmark) async {
    final db = await AppDatabase.database;
    await db.update(
      tableName,
      bookmark.toJson(),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
    AppEventBus().fire("up_bookmark");
  }

  /// 刪除書籤
  Future<void> delete(Bookmark bookmark) async {
    final db = await AppDatabase.database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [bookmark.id]);
    AppEventBus().fire("up_bookmark");
  }

  /// 清除所有書籤
  Future<void> clearAll() async {
    final db = await AppDatabase.database;
    await db.delete(tableName);
    AppEventBus().fire("up_bookmark");
  }

  /// 全域搜尋書籤（跨所有書籍）
  Future<List<Bookmark>> search(String key) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
        SELECT * FROM $tableName 
        WHERE bookName LIKE '%' || ? || '%' 
        OR chapterName LIKE '%' || ? || '%' 
        OR content LIKE '%' || ? || '%'
        OR bookText LIKE '%' || ? || '%'
        ORDER BY bookName COLLATE NOCASE, chapterIndex
      ''',
      [key, key, key, key],
    );
    return List.generate(maps.length, (i) => Bookmark.fromJson(maps[i]));
  }
}

