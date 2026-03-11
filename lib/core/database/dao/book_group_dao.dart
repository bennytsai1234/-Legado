import 'package:sqflite/sqflite.dart';
import '../../models/book_group.dart';
import '../app_database.dart';

/// BookGroupDao - 書籍群組資料表操作
/// 對應 Android: data/dao/BookGroupDao.kt
class BookGroupDao {
  static const String tableName = 'book_groups';

  /// 建立表格
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        groupId INTEGER PRIMARY KEY,
        groupName TEXT NOT NULL,
        "order" INTEGER DEFAULT 0,
        "show" INTEGER DEFAULT 1,
        cover TEXT,
        background TEXT
      )
    ''';
  }

  Future<BookGroup?> getByID(int id) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'groupId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BookGroup.fromJson(maps.first);
    }
    return null;
  }

  Future<BookGroup?> getByName(String groupName) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'groupName = ?',
      whereArgs: [groupName],
    );
    if (maps.isNotEmpty) {
      return BookGroup.fromJson(maps.first);
    }
    return null;
  }

  Future<List<BookGroup>> getAll() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: '"order"',
    );
    return List.generate(maps.length, (i) => BookGroup.fromJson(maps[i]));
  }

  Future<int> getIdsSum() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(groupId) FROM $tableName WHERE groupId >= 0',
    );
    if (maps.isNotEmpty && maps.first.values.first != null) {
      return (maps.first.values.first as num).toInt();
    }
    return 0;
  }

  Future<int> getMaxOrder() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT MAX("order") FROM $tableName WHERE groupId >= 0',
    );
    if (maps.isNotEmpty && maps.first.values.first != null) {
      return (maps.first.values.first as num).toInt();
    }
    return 0;
  }

  Future<bool> getCanAddGroup() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT count(*) < 64 as canAdd FROM $tableName WHERE groupId >= 0 OR groupId = -9223372036854775808',
    ); // Long.MIN_VALUE in SQLite
    if (maps.isNotEmpty) {
      return (maps.first['canAdd'] as int) > 0;
    }
    return false;
  }

  Future<void> enableGroup(int groupId) async {
    final db = await AppDatabase.database;
    await db.rawUpdate('UPDATE $tableName SET "show" = 1 WHERE groupId = ?', [
      groupId,
    ]);
  }

  Future<List<String>> getGroupNames(int id) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT groupName FROM $tableName WHERE groupId > 0 AND (groupId & ?) > 0',
      [id],
    );
    return List.generate(maps.length, (i) => maps[i]['groupName'] as String);
  }

  Future<void> insert(BookGroup bookGroup) async {
    final db = await AppDatabase.database;
    final map = bookGroup.toJson();
    map['enableRefresh'] = (map['enableRefresh'] == true) ? 1 : 0;
    map['show'] = (map['show'] == true) ? 1 : 0;
    
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(BookGroup bookGroup) async {
    final db = await AppDatabase.database;
    final map = bookGroup.toJson();
    map['enableRefresh'] = (map['enableRefresh'] == true) ? 1 : 0;
    map['show'] = (map['show'] == true) ? 1 : 0;

    await db.update(
      tableName,
      map,
      where: 'groupId = ?',
      whereArgs: [bookGroup.groupId],
    );
  }

  Future<void> delete(BookGroup bookGroup) async {
    final db = await AppDatabase.database;
    await db.delete(
      tableName,
      where: 'groupId = ?',
      whereArgs: [bookGroup.groupId],
    );
  }

  bool isInRules(int id) {
    if (id < 0) {
      return true;
    }
    return id & (id - 1) == 0;
  }

  Future<int> getUnusedId() async {
    int id = 1;
    final idsSum = await getIdsSum();
    while ((id & idsSum) != 0) {
      id = id << 1;
    }
    return id;
  }
}
