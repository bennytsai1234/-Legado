import 'package:flutter/material.dart';
import '../../core/database/dao/bookmark_dao.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/bookmark.dart';
import '../../shared/widgets/base_scaffold.dart';
import '../reader/reader_page.dart';
import 'package:intl/intl.dart';

class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});

  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  final BookmarkDao _bookmarkDao = BookmarkDao();
  final BookDao _bookDao = BookDao();
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    _bookmarks = await _bookmarkDao.getAll();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    await _bookmarkDao.delete(bookmark);
    await _loadBookmarks();
  }

  Future<void> _jumpToReader(Bookmark bookmark) async {
    final book = await _bookDao.getByUrl(bookmark.bookUrl);
    if (book != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderPage(
            book: book,
            chapterIndex: bookmark.chapterIndex,
            chapterPos: bookmark.chapterPos,
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到對應書籍')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '書籤與筆記',
      isLoading: _isLoading,
      body: _bookmarks.isEmpty && !_isLoading
          ? const Center(child: Text('暫無書籤'))
          : ListView.builder(
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = _bookmarks[index];
                final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(bookmark.time));

                return Dismissible(
                  key: ValueKey(bookmark.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteBookmark(bookmark),
                  child: ListTile(
                    title: Text(bookmark.bookName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${bookmark.chapterName} - $dateStr', style: const TextStyle(fontSize: 12)),
                        if (bookmark.bookText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '原文: "${bookmark.bookText}"',
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (bookmark.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '筆記: ${bookmark.content}',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _jumpToReader(bookmark),
                  ),
                );
              },
            ),
    );
  }
}
