import 'package:sqflite/sqflite.dart';
import '../../models/chapter.dart';
import '../app_database.dart';

/// ChapterDao - 章節與正文資料存取對象
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
        final map = chapter.toJson();
        map['isVolume'] = (map['isVolume'] == true) ? 1 : 0;
        map['isVip'] = (map['isVip'] == true) ? 1 : 0;
        map['isPay'] = (map['isPay'] == true) ? 1 : 0;
        
        // Sqflite 建議在 batch 中使用 insert 而不是 txn.insert
        batch.insert(
          chaptersTable,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 批量保存章節正文
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
      final map = Map<String, dynamic>.from(maps[i]);
      map['isVolume'] = map['isVolume'] == 1;
      map['isVip'] = map['isVip'] == 1;
      map['isPay'] = map['isPay'] == 1;
      return BookChapter.fromJson(map);
    });
  }

  /// 保存章節正文
  Future<void> saveContent(String bookUrl, int index, String content) async {
    final db = await _db;
    await db.insert(contentsTable, {
      'bookUrl': bookUrl,
      'chapterIndex': index,
      'content': content,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 獲取章節正文
  Future<String?> getContent(String bookUrl, int index) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      contentsTable,
      where: 'bookUrl = ? AND chapterIndex = ?',
      whereArgs: [bookUrl, index],
    );

    if (maps.isEmpty) return null;
    return maps.first['content'] as String?;
  }

  /// 刪除書籍的所有章節與正文
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
}
