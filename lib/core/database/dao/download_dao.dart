import 'package:sqflite/sqflite.dart';
import '../../models/download_task.dart';
import '../app_database.dart';

/// DownloadDao - 下載任務資料存取對象
class DownloadDao {
  static const String tableName = 'download_tasks';

  Future<Database> get _db async => await AppDatabase.database;

  /// 插入或更新任務
  Future<void> insertOrUpdate(DownloadTask task) async {
    final db = await _db;
    await db.insert(
      tableName,
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 獲取所有未完成的任務
  Future<List<DownloadTask>> getUnfinishedTasks() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'status IN (?, ?, ?)',
      whereArgs: [0, 1, 2], // 等待中, 下載中, 已暫停
      orderBy: 'lastUpdateTime ASC',
    );

    return List.generate(maps.length, (i) {
      return DownloadTask.fromJson(maps[i]);
    });
  }

  /// 更新任務狀態與進度
  Future<void> updateProgress(String bookUrl, {
    int? currentChapterIndex,
    int? status,
    int? successCount,
    int? errorCount,
  }) async {
    final db = await _db;
    final Map<String, dynamic> values = {
      'lastUpdateTime': DateTime.now().millisecondsSinceEpoch,
    };
    if (currentChapterIndex != null) values['currentChapterIndex'] = currentChapterIndex;
    if (status != null) values['status'] = status;
    if (successCount != null) values['successCount'] = successCount;
    if (errorCount != null) values['errorCount'] = errorCount;

    await db.update(
      tableName,
      values,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 刪除任務
  Future<void> delete(String bookUrl) async {
    final db = await _db;
    await db.delete(tableName, where: 'bookUrl = ?', whereArgs: [bookUrl]);
  }

  /// 清空已完成任務
  Future<void> clearFinished() async {
    final db = await _db;
    await db.delete(tableName, where: 'status = ?', whereArgs: [3]);
  }
}
