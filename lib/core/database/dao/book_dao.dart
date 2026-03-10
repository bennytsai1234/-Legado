import 'package:sqflite/sqflite.dart';
import '../../models/book.dart';
import '../app_database.dart';

/// BookDao - 書籍資料存取對象
class BookDao {
  static const String tableName = 'books';

  Future<Database> get _db async => await AppDatabase.database;

  /// 插入或更新書籍
  Future<void> insertOrUpdate(Book book) async {
    final db = await _db;
    final map = book.toJson();
    _serialize(map);

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 獲取所有書架上的書籍
  Future<List<Book>> getBookshelf() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isInBookshelf = ?',
      whereArgs: [1],
      orderBy: '"order" ASC, latestChapterTime DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      _deserialize(map);
      return Book.fromJson(map);
    });
  }

  /// 根據 URL 獲取書籍
  Future<Book?> getByUrl(String bookUrl) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );

    if (maps.isEmpty) return null;
    final map = Map<String, dynamic>.from(maps.first);
    _deserialize(map);
    return Book.fromJson(map);
  }

  /// 更新閱讀進度
  Future<void> updateProgress(
    String bookUrl,
    int index,
    int pos,
    String title,
  ) async {
    final db = await _db;
    await db.update(
      tableName,
      {
        'durChapterIndex': index,
        'durChapterPos': pos,
        'durChapterTitle': title,
        'durChapterTime': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 更新書架狀態
  Future<void> updateInBookshelf(String bookUrl, bool isInBookshelf) async {
    final db = await _db;
    await db.update(
      tableName,
      {'isInBookshelf': isInBookshelf ? 1 : 0},
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 刪除書籍
  Future<void> delete(String bookUrl) async {
    final db = await _db;
    await db.delete(tableName, where: 'bookUrl = ?', whereArgs: [bookUrl]);
  }

  void _serialize(Map<String, dynamic> map) {
    map['canUpdate'] = (map['canUpdate'] == true) ? 1 : 0;
    map['isInBookshelf'] = (map['isInBookshelf'] == true) ? 1 : 0;
  }

  void _deserialize(Map<String, dynamic> map) {
    map['canUpdate'] = map['canUpdate'] == 1;
    map['isInBookshelf'] = map['isInBookshelf'] == 1;
  }
}
