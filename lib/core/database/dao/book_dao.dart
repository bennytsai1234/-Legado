import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/book.dart';
import '../app_database.dart';

/// BookDao - 書籍資料存取對象
/// 對應 Android: data/dao/BookDao.kt
class BookDao {
  static const String tableName = 'books';
  static final StreamController<void> _changeController = StreamController<void>.broadcast();

  Future<Database> get _db async => await AppDatabase.database;

  void _notify() {
    _changeController.add(null);
  }

  /// 監聽數據變化 (高度還原 Android Room Flow)
  Stream<List<Book>> watchBookshelf({int groupId = -1}) {
    return _changeController.stream.asyncMap((_) => getBookshelf(groupId: groupId));
  }

  /// 獲取書架上的書籍，支援分組與過濾 (高度還原 Android flowByGroup)
  Future<List<Book>> getBookshelf({int groupId = -1, String orderBy = 'durChapterTime DESC'}) async {
    final db = await _db;
    
    // 預設排除不在書架上的書籍 (type & notShelf == 0)
    String whereClause = '(type & ?) = 0';
    List<dynamic> whereArgs = [BookType.notShelf];

    if (groupId > 0) {
      // 具體分組過濾
      whereClause += ' AND ("group" & ?) > 0';
      whereArgs.add(groupId);
    } else if (groupId == -2) { // 模擬 flowAudio
      whereClause += ' AND (type & ?) > 0';
      whereArgs.add(BookType.audio);
    } else if (groupId == -3) { // 模擬 flowLocal
      whereClause += ' AND (type & ?) > 0';
      whereArgs.add(BookType.local);
    } else if (groupId == -4) { // 模擬 flowUpdateError
      whereClause += ' AND (type & ?) > 0';
      whereArgs.add(BookType.updateError);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return List.generate(maps.length, (i) {
      return Book.fromJson(maps[i]);
    });
  }

  /// 根據書名與作者獲取書籍 (高度還原 Android getBook)
  Future<Book?> getByNameAndAuthor(String name, String author) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name = ? AND author = ?',
      whereArgs: [name, author],
    );

    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 插入或更新書籍
  Future<void> insertOrUpdate(Book book) async {
    final db = await _db;
    await db.insert(
      tableName,
      book.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  /// 獲取所有書籍 (備份用)
  Future<List<Book>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Book.fromJson(maps[i]);
    });
  }

  /// 根據 URL 獲取書籍
  Future<Book?> getByUrl(String bookUrl) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 根據書名查找書籍 (對應 Android BookDao.findByName)
  Future<List<Book>> findByName(String name) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
    return List.generate(maps.length, (i) => Book.fromJson(maps[i]));
  }

  /// 更新是否在書架上
  Future<void> updateInBookshelf(String bookUrl, bool inBookshelf) async {
    final db = await _db;
    final book = await getByUrl(bookUrl);
    if (book != null) {
      int newType = book.type;
      if (inBookshelf) {
        newType &= ~BookType.notShelf;
      } else {
        newType |= BookType.notShelf;
      }
      await db.update(
        tableName,
        {
          'type': newType,
          'isInBookshelf': inBookshelf ? 1 : 0,
        },
        where: 'bookUrl = ?',
        whereArgs: [bookUrl],
      );
      _notify();
    }
  }

  /// 更新閱讀進度 (高度還原 Android upProgress)
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
        'durChapterTime': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
    _notify();
  }

  /// 更新分組 (高度還原 Android upGroup)
  Future<void> updateGroup(int oldGroupId, int newGroupId) async {
    final db = await _db;
    await db.update(
      tableName,
      {'group': newGroupId},
      where: '"group" = ?',
      whereArgs: [oldGroupId],
    );
    _notify();
  }

  /// 移除特定分組位元 (高度還原 Android removeGroup)
  Future<void> removeGroupBit(int groupId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE $tableName SET "group" = "group" - ? WHERE ("group" & ?) > 0',
      [groupId, groupId],
    );
    _notify();
  }

  /// 刪除不在書架上的書籍 (高度還原 Android deleteNotShelfBook)
  Future<void> deleteNotShelfBook() async {
    final db = await _db;
    await db.delete(tableName, where: '(type & ?) > 0', whereArgs: [BookType.notShelf]);
    _notify();
  }

  /// 更新排序 (高度還原 Android upOrder)
  Future<void> updateOrder(String bookUrl, int order) async {
    final db = await _db;
    await db.update(
      tableName,
      {'order': order},
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
    _notify();
  }

  /// 獲取所有在書架上的書籍 (isInBookshelf = 1)
  Future<List<Book>> getAllInBookshelf() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isInBookshelf = 1',
    );
    return List.generate(maps.length, (i) {
      return Book.fromJson(maps[i]);
    });
  }

  /// 刪除書籍 (Alias for deleteByUrl)
  Future<void> delete(String bookUrl) => deleteByUrl(bookUrl);

  /// 刪除書籍
  Future<void> deleteByUrl(String bookUrl) async {
    final db = await _db;
    await db.delete(tableName, where: 'bookUrl = ?', whereArgs: [bookUrl]);
    _notify();
  }
}
