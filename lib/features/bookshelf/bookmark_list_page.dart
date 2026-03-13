import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/dao/bookmark_dao.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/bookmark.dart';
import '../reader/reader_page.dart';
import 'package:intl/intl.dart';
import '../../core/engine/app_event_bus.dart';

/// BookmarkListPage - 全域書籤管理
/// 對應 Android: ui/book/bookmark/AllBookmarkActivity.kt
class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});

  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  final BookmarkDao _bookmarkDao = BookmarkDao();
  final BookDao _bookDao = BookDao();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _eventSub;

  List<Bookmark> _allBookmarks = [];
  Map<String, List<Bookmark>> _groupedBookmarks = {};
  bool _isLoading = true;
  bool _groupByBook = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _eventSub = AppEventBus().onName("up_bookmark").listen((_) {
      _loadBookmarks(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBookmarks([String searchKey = '']) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    List<Bookmark> bookmarks;
    if (searchKey.isEmpty) {
      bookmarks = await _bookmarkDao.getAll();
    } else {
      bookmarks = await _bookmarkDao.search(searchKey);
    }

    final Map<String, List<Bookmark>> grouped = {};
    for (final bm in bookmarks) {
      grouped.putIfAbsent(bm.bookName, () => []).add(bm);
    }

    if (mounted) {
      setState(() {
        _allBookmarks = bookmarks;
        _groupedBookmarks = grouped;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportBookmarks({bool asJson = false}) async {
    if (_allBookmarks.isEmpty) return;
    
    if (asJson) {
      try {
        final List<Map<String, dynamic>> jsonList = _allBookmarks.map((e) => e.toJson()).toList();
        final String jsonStr = JsonEncoder.withIndent('  ').convert(jsonList);
        await Share.share(jsonStr, subject: 'Legado 書籤 JSON 導出');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON 導出失敗: $e')));
        }
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('# Legado Reader 書籤匯出');
    buffer.writeln('導出日期: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln();

    for (final bookName in _groupedBookmarks.keys) {
      buffer.writeln('## 《$bookName》');
      for (final bm in _groupedBookmarks[bookName]!) {
        final time = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(bm.time));
        buffer.writeln('### ${bm.chapterName} ($time)');
        if (bm.bookText.isNotEmpty) buffer.writeln('> ${bm.bookText}');
        if (bm.content.isNotEmpty) buffer.writeln('\n**筆記**: ${bm.content}');
        buffer.writeln('\n---');
      }
      buffer.writeln();
    }

    await Share.share(buffer.toString(), subject: 'Legado 書籤匯出');
  }

  Future<void> _showExportMenu() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('導出為 Markdown (文字版)'),
            onTap: () => Navigator.pop(ctx, 0),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('導出為 JSON (備份版)'),
            onTap: () => Navigator.pop(ctx, 1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (result == 0) _exportBookmarks(asJson: false);
    if (result == 1) _exportBookmarks(asJson: true);
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除書籤'),
        content: Text('確定要刪除「${bookmark.chapterName}」的書籤嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _bookmarkDao.delete(bookmark);
      // 自動刷新會由 EventBus 觸發，這裡不需要手動加載
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除全部'),
        content: const Text('確定要刪除所有書籤嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除全部', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _bookmarkDao.clearAll();
    }
  }

  Future<void> _editBookmark(Bookmark bookmark) async {
    final textController = TextEditingController(text: bookmark.bookText);
    final contentController = TextEditingController(text: bookmark.content);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bookmark.chapterName, style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('原文內容', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(8),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('書籤筆記', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '輸入筆記內容...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(8),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _jumpToReader(bookmark);
                },
                child: const Text('跳轉至正文'),
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              ElevatedButton(
                onPressed: () async {
                  final newBookmark = bookmark.copyWith(
                    bookText: textController.text,
                    content: contentController.text,
                  );
                  await _bookmarkDao.insert(newBookmark);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    _loadBookmarks(_searchController.text);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
    textController.dispose();
    contentController.dispose();
  }

  Future<void> _jumpToReader(Bookmark bookmark) async {
    final book = await _bookDao.getByUrl(bookmark.bookUrl);
    if (!mounted) return;
    if (book != null) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到對應書籍')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('書籤與筆記'),
        actions: [
          IconButton(
            icon: Icon(_groupByBook ? Icons.list : Icons.folder_outlined),
            tooltip: _groupByBook ? '平列顯示' : '依書籍分組',
            onPressed: () => setState(() => _groupByBook = !_groupByBook),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '匯出書籤',
            onPressed: _allBookmarks.isNotEmpty ? _showExportMenu : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清除全部',
            onPressed: _allBookmarks.isNotEmpty ? _clearAll : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋書籤（書名、章節、筆記）...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadBookmarks();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: (val) => _loadBookmarks(val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '共 ${_allBookmarks.length} 條書籤',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (_groupByBook) ...[
                  const Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    '${_groupedBookmarks.keys.length} 本書',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allBookmarks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text(
                              '暫無書籤',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _groupByBook
                        ? _buildGroupedList()
                        : _buildFlatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final bookNames = _groupedBookmarks.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: bookNames.length,
      itemBuilder: (context, index) {
        final bookName = bookNames[index];
        final bookmarks = _groupedBookmarks[bookName]!;
        return ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              bookName.isNotEmpty ? bookName[0] : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(bookName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${bookmarks.length} 條書籤', style: const TextStyle(fontSize: 12)),
          initiallyExpanded: _groupedBookmarks.keys.length == 1,
          children: bookmarks.map((bm) => _buildBookmarkTile(bm)).toList(),
        );
      },
    );
  }

  Widget _buildFlatList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _allBookmarks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) => _buildBookmarkTile(_allBookmarks[index], showBookName: true),
    );
  }

  Widget _buildBookmarkTile(Bookmark bookmark, {bool showBookName = false}) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(bookmark.time));

    return Dismissible(
      key: ValueKey('${bookmark.bookUrl}_${bookmark.chapterIndex}_${bookmark.chapterPos}'),
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteBookmark(bookmark);
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          showBookName ? '${bookmark.bookName} · ${bookmark.chapterName}' : bookmark.chapterName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            if (bookmark.bookText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '「${bookmark.bookText}」',
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (bookmark.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '📝 ${bookmark.content}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        isThreeLine: bookmark.bookText.isNotEmpty || bookmark.content.isNotEmpty,
        onTap: () => _editBookmark(bookmark),
        onLongPress: () => _deleteBookmark(bookmark),
      ),
    );
  }
}
