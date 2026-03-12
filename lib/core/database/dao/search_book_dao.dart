import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/search_book.dart';

/// SearchBookDao - 搜尋結果快取資料庫
/// 對應 Android: SearchBookDao.kt
class SearchBookDao {
  static final SearchBookDao _instance = SearchBookDao._internal();
  factory SearchBookDao() => _instance;
  SearchBookDao._internal();

  Future<Database> get _db async => await AppDatabase.database;

  /// 建立資料表 (若不存在)
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_books (
        bookUrl TEXT PRIMARY KEY,
        name TEXT,
        author TEXT,
        coverUrl TEXT,
        intro TEXT,
        origin TEXT,
        originName TEXT,
        type INTEGER,
        lastCheckTime INTEGER
      )
    ''');
  }

  /// 獲取符合條件且有封面的搜尋結果 (對標 Android getEnabledHasCover)
  Future<List<AggregatedSearchBook>> getEnabledHasCover(String name, String author) async {
    final d = await _db;
    final List<Map<String, dynamic>> maps = await d.query(
      'search_books',
      where: 'name = ? AND author LIKE ? AND coverUrl IS NOT NULL AND coverUrl != ""',
      whereArgs: [name, '%$author%'],
      orderBy: 'lastCheckTime DESC',
    );

    return List.generate(maps.length, (i) {
      final book = SearchBook.fromJson(maps[i]);
      return AggregatedSearchBook(
        book: book,
        sources: [book.originName ?? '快取'],
      );
    });
  }

  /// 獲取所有快取的搜尋結果 (對標 Android getSearchBooks)
  Future<List<SearchBook>> getSearchBooks(String name, String author) async {
    final d = await _db;
    final List<Map<String, dynamic>> maps = await d.query(
      'search_books',
      where: 'name = ? AND author = ?',
      whereArgs: [name, author],
    );
    return maps.map((e) => SearchBook.fromJson(e)).toList();
  }

  /// 插入或更新搜尋結果
  Future<void> insert(AggregatedSearchBook result) async {
    final d = await _db;
    final json = result.book.toJson();
    json['lastCheckTime'] = DateTime.now().millisecondsSinceEpoch;
    
    await d.insert(
      'search_books',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAll() async {
    final d = await _db;
    await d.delete('search_books');
  }
}
