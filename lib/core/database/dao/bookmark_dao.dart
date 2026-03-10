import 'package:sqflite/sqflite.dart';
import '../../models/bookmark.dart';
import '../app_database.dart';

/// BookmarkDao - 書籤資料表操作
/// 對應 Android: data/dao/BookmarkDao.kt
class BookmarkDao {
  static const String tableName = 'bookmarks';

  /// 建立表格 (由 [AppDatabase] 調用)
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookName TEXT NOT NULL,
        bookAuthor TEXT NOT NULL,
        chapterIndex INTEGER NOT NULL,
        chapterPos INTEGER NOT NULL,
        chapterName TEXT NOT NULL,
        bookUrl TEXT NOT NULL,
        content TEXT NOT NULL,
        time INTEGER NOT NULL
      )
    ''';
  }

  /// 獲取所有書籤並依照書名、作者、章節與位置排序
  Future<List<Bookmark>> getAll() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'bookName COLLATE NOCASE, bookAuthor COLLATE NOCASE, chapterIndex, chapterPos',
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

  /// 搜尋書籤
  Future<List<Bookmark>> search(String bookName, String bookAuthor, String key) async {
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
  }

  /// 刪除書籤
  Future<void> delete(Bookmark bookmark) async {
    final db = await AppDatabase.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }
}
