import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

/// ReadRecord 模型
class ReadRecord {
  final String bookName;
  final int readTime;
  final int lastRead;
  final String deviceId;

  ReadRecord({
    required this.bookName,
    required this.readTime,
    required this.lastRead,
    this.deviceId = 'local',
  });

  Map<String, dynamic> toJson() => {
    'bookName': bookName,
    'readTime': readTime,
    'lastRead': lastRead,
    'deviceId': deviceId,
  };

  factory ReadRecord.fromJson(Map<String, dynamic> json) => ReadRecord(
    bookName: json['bookName'],
    readTime: json['readTime'],
    lastRead: json['lastRead'],
    deviceId: json['deviceId'],
  );
}

/// ReadRecordShow 模型 (SQL result)
class ReadRecordShow {
  final String bookName;
  final int readTime;
  final int lastRead;

  ReadRecordShow({
    required this.bookName,
    required this.readTime,
    required this.lastRead,
  });

  factory ReadRecordShow.fromJson(Map<String, dynamic> json) => ReadRecordShow(
    bookName: json['bookName'] as String,
    readTime: json['readTime'] as int,
    lastRead: json['lastRead'] as int,
  );
}

/// ReadRecordDao - 閱讀紀錄資料表操作
/// 對應 Android: data/dao/ReadRecordDao.kt
class ReadRecordDao {
  static const String tableName = 'readRecord';

  /// 建立表格
  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        bookName TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        readTime INTEGER NOT NULL,
        lastRead INTEGER NOT NULL,
        PRIMARY KEY (bookName, deviceId)
      )
    ''';
  }

  Future<List<ReadRecord>> getAll() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => ReadRecord.fromJson(maps[i]));
  }

  Future<List<ReadRecordShow>> getAllShow() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT bookName, SUM(readTime) as readTime, MAX(lastRead) as lastRead 
      FROM $tableName 
      GROUP BY bookName 
      ORDER BY bookName COLLATE NOCASE
    ''');
    return List.generate(maps.length, (i) => ReadRecordShow.fromJson(maps[i]));
  }

  Future<int> getAllTime() async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(readTime) FROM $tableName',
    );
    if (maps.isNotEmpty && maps.first.values.first != null) {
      return (maps.first.values.first as num).toInt();
    }
    return 0;
  }

  Future<List<ReadRecordShow>> search(String searchKey) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT bookName, SUM(readTime) as readTime, MAX(lastRead) as lastRead 
      FROM $tableName 
      WHERE bookName LIKE '%' || ? || '%'
      GROUP BY bookName 
      ORDER BY bookName COLLATE NOCASE
    ''',
      [searchKey],
    );
    return List.generate(maps.length, (i) => ReadRecordShow.fromJson(maps[i]));
  }

  Future<int?> getReadTimeByBookName(String bookName) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(readTime) FROM $tableName WHERE bookName = ?',
      [bookName],
    );
    if (maps.isNotEmpty && maps.first.values.first != null) {
      return (maps.first.values.first as num).toInt();
    }
    return null;
  }

  Future<int?> getReadTime(String deviceId, String bookName) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['readTime'],
      where: 'deviceId = ? AND bookName = ?',
      whereArgs: [deviceId, bookName],
    );
    if (maps.isNotEmpty) {
      return maps.first['readTime'] as int?;
    }
    return null;
  }

  Future<void> insert(ReadRecord record) async {
    final db = await AppDatabase.database;
    await db.insert(
      tableName,
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(ReadRecord record) async {
    final db = await AppDatabase.database;
    await db.update(
      tableName,
      record.toJson(),
      where: 'bookName = ? AND deviceId = ?',
      whereArgs: [record.bookName, record.deviceId],
    );
  }

  Future<void> delete(ReadRecord record) async {
    final db = await AppDatabase.database;
    await db.delete(
      tableName,
      where: 'bookName = ? AND deviceId = ?',
      whereArgs: [record.bookName, record.deviceId],
    );
  }

  Future<void> clear() async {
    final db = await AppDatabase.database;
    await db.delete(tableName);
  }

  Future<void> deleteByName(String bookName) async {
    final db = await AppDatabase.database;
    await db.delete(tableName, where: 'bookName = ?', whereArgs: [bookName]);
  }
}
