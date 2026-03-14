import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/database/app_database.dart';

/// ChapterDao - 章節與正文資料存取對象
/// 對應 Android: data/dao/BookChapterDao.kt
class ChapterDao {
  static const String chaptersTable = 'chapters';
  static const String contentsTable = 'chapter_contents';

  Future<Database> get _db async => await AppDatabase.database;

  /// 批量插入章節列表
  Future<void> insertChapters(List<BookChapter> chapters) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final chapter in chapters) {
        batch.insert(
          chaptersTable,
          chapter.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 獲取書籍的所有章節
  Future<List<BookChapter>> getChapters(String bookUrl) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      chaptersTable,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
      orderBy: '"index" ASC',
    );

    return List.generate(maps.length, (i) {
      return BookChapter.fromJson(maps[i]);
    });
  }

  /// 獲取章節區間 (高度還原 Android getChapterList)
  Future<List<BookChapter>> getChapterRange(String bookUrl, int start, int end) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      chaptersTable,
      where: 'bookUrl = ? AND "index" >= ? AND "index" <= ?',
      whereArgs: [bookUrl, start, end],
      orderBy: '"index" ASC',
    );
    return List.generate(maps.length, (i) => BookChapter.fromJson(maps[i]));
  }

  /// 搜尋章節 (高度還原 Android search)
  Future<List<BookChapter>> searchChapters(String bookUrl, String keyword) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      chaptersTable,
      where: 'bookUrl = ? AND title LIKE ?',
      whereArgs: [bookUrl, '%$keyword%'],
      orderBy: '"index" ASC',
    );
    return List.generate(maps.length, (i) => BookChapter.fromJson(maps[i]));
  }

  /// 獲取章節總數 (高度還原 Android getChapterCount)
  Future<int> getChapterCount(String bookUrl) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $chaptersTable WHERE bookUrl = ?',
      [bookUrl],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 根據索引獲取單章 (高度還原 Android getChapter)
  Future<BookChapter?> getChapterByIndex(String bookUrl, int index) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      chaptersTable,
      where: 'bookUrl = ? AND "index" = ?',
      whereArgs: [bookUrl, index],
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// 更新章節位置與字數 (高度還原 Android upWordCount 擴展)
  Future<void> updateChapterOffsets(String bookUrl, int index, {int? start, int? end, String? wordCount}) async {
    final db = await _db;
    final Map<String, dynamic> values = {};
    if (start != null) values['start'] = start;
    if (end != null) values['end'] = end;
    if (wordCount != null) values['wordCount'] = wordCount;
    
    if (values.isEmpty) return;

    await db.update(
      chaptersTable,
      values,
      where: 'bookUrl = ? AND "index" = ?',
      whereArgs: [bookUrl, index],
    );
  }

  /// 儲存章節正文
  Future<void> saveContent(String bookUrl, int index, String content) async {
    final db = await _db;
    await db.insert(
      contentsTable,
      {
        'bookUrl': bookUrl,
        'chapterIndex': index,
        'content': content,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入章節正文
  Future<void> insertContents(List<Map<String, dynamic>> contents) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final content in contents) {
        batch.insert(
          contentsTable,
          content,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 獲取章節正文
  Future<String?> getContent(String bookUrl, int index) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      contentsTable,
      columns: ['content'],
      where: 'bookUrl = ? AND chapterIndex = ?',
      whereArgs: [bookUrl, index],
    );

    if (maps.isEmpty) return null;
    return maps.first['content'] as String?;
  }

  /// 檢查是否有正文快取
  Future<bool> hasContent(String bookUrl, int index) async {
    final db = await _db;
    final maps = await db.rawQuery(
      'SELECT 1 FROM $contentsTable WHERE bookUrl = ? AND chapterIndex = ? LIMIT 1',
      [bookUrl, index],
    );
    return maps.isNotEmpty;
  }

  /// 僅刪除指定書籍的正文快取 (保留目錄)
  Future<void> deleteContentByBook(String bookUrl) async {
    final db = await _db;
    await db.delete(
      contentsTable,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 刪除書籍的所有章節與正文 (高度還原 Android delByBook)
  Future<void> deleteByBook(String bookUrl) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        chaptersTable,
        where: 'bookUrl = ?',
        whereArgs: [bookUrl],
      );
      await txn.delete(
        contentsTable,
        where: 'bookUrl = ?',
        whereArgs: [bookUrl],
      );
    });
  }

  /// 清理所有不在書架上的書籍快取內容 (高度還原 Android 清理邏輯)
  Future<void> clearAllExpiredContent() async {
    final db = await _db;
    // 使用子查詢刪除內容表中不屬於當前書架書籍的條目
    await db.rawDelete('''
      DELETE FROM $contentsTable 
      WHERE bookUrl NOT IN (SELECT bookUrl FROM books WHERE isInBookshelf = 1)
    ''');
  }

  /// 獲取所有正文內容的總大小 (預估值)
  Future<int> getTotalContentSize() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(LENGTH(content)) as total FROM $contentsTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 清空所有正文快取
  Future<void> clearAllContent() async {
    final db = await _db;
    await db.delete(contentsTable);
  }
}

