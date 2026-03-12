import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail_provider.dart';
import 'change_cover_sheet.dart';
import '../../core/models/search_book.dart';
import '../../core/models/book.dart';

import '../reader/reader_page.dart';
import '../../core/services/export_book_service.dart';

class BookDetailPage extends StatelessWidget {
  final AggregatedSearchBook searchBook;

  const BookDetailPage({super.key, required this.searchBook});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider(searchBook),
      child: Consumer<BookDetailProvider>(
        builder: (context, provider, child) {
          final book = provider.book;
          return Scaffold(
            appBar: AppBar(
              title: const Text('書籍詳情'),
              actions: [
                IconButton(
                  icon: Icon(provider.isInBookshelf ? Icons.library_add_check : Icons.library_add),
                  onPressed: () => provider.toggleInBookshelf(),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'export') {
                      ExportBookService().exportToTxt(book);
                    } else if (val == 'clear_cache') {
                      provider.clearCache();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清理正文快取')));
                    } else if (val == 'preload') {
                      _showPreloadDialog(context, provider);
                    } else if (val == 'edit') {
                      _showEditBookInfoDialog(context, provider);
                    } else if (val == 'change_cover') {
                      _showChangeCoverSheet(context, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'change_cover', child: Text('換封面')),
                    const PopupMenuItem(value: 'export', child: Text('匯出全書 (TXT)')),
                    const PopupMenuItem(value: 'clear_cache', child: Text('清理正文快取')),
                    const PopupMenuItem(value: 'preload', child: Text('預加載後續章節')),
                    const PopupMenuItem(value: 'edit', child: Text('編輯書籍資訊')),
                  ],
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context, provider, book)),
                      SliverToBoxAdapter(child: _buildIntro(book)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('目錄 (${provider.filteredChapters.length} 章)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearchTocDialog(context, provider)),
                                  IconButton(icon: Icon(provider.isReversed ? Icons.vertical_align_top : Icons.vertical_align_bottom), onPressed: provider.toggleSort),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final chapter = provider.filteredChapters[index];
                          return ListTile(
                            title: Text(chapter.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _navigateToReader(context, book, chapter.index),
                          );
                        }, childCount: provider.filteredChapters.length),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  void _showPhotoView(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: 'book_cover',
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 100),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BookDetailProvider provider, Book book) {
    final coverUrl = book.getDisplayCover();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showChangeCoverSheet(context, provider),
            onLongPress: () {
              if (coverUrl != null && coverUrl.isNotEmpty) {
                _showPhotoView(context, coverUrl);
              }
            },
            child: Hero(
              tag: 'book_cover',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: coverUrl != null && coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl, 
                        width: 100, height: 140, 
                        fit: BoxFit.cover, 
                        errorWidget: (context, url, error) => _buildCoverPlaceholder(),
                      )
                    : _buildCoverPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditBookInfoDialog(context, provider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('作者：${book.author}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('來源：${book.originName}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _navigateToReader(context, book, book.durChapterIndex),
                        child: Text(book.durChapterIndex == 0 && book.durChapterPos == 0 ? '開始閱讀' : '繼續閱讀'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => _showChangeSourceDialog(context, provider), child: const Text('換源', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(width: 100, height: 140, color: Colors.grey.shade200, child: const Icon(Icons.book, size: 50, color: Colors.grey));
  }

  Widget _buildIntro(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text('簡介', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(book.intro ?? '暫無簡介', style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _navigateToReader(BuildContext context, Book book, int index) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ReaderPage(book: book, chapterIndex: index)));
  }

  void _showChangeSourceDialog(BuildContext context, BookDetailProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('搜尋可用書源...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSearchTocDialog(BuildContext context, BookDetailProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜尋目錄'),
        content: TextField(
          decoration: const InputDecoration(hintText: '輸入章節名稱...'),
          autofocus: true,
          onChanged: provider.setSearchQuery,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
      ),
    );
  }

  void _showPreloadDialog(BuildContext context, BookDetailProvider provider) {
    final ctrl = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('預加載章節'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '輸入加載數量'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              int count = int.tryParse(ctrl.text) ?? 50;
              provider.preloadChapters(provider.book.durChapterIndex, count);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('開始預加載 $count 章...')));
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showEditBookInfoDialog(BuildContext context, BookDetailProvider provider) {
    final nameCtrl = TextEditingController(text: provider.book.name);
    final authorCtrl = TextEditingController(text: provider.book.author);
    final introCtrl = TextEditingController(text: provider.book.intro);
    final coverCtrl = TextEditingController(text: provider.book.coverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯書籍資訊'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '書名')),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: '作者')),
              TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: '封面 URL')),
              TextField(controller: introCtrl, decoration: const InputDecoration(labelText: '簡介'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.updateBookInfo(nameCtrl.text, authorCtrl.text, introCtrl.text, coverCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
  void _showChangeCoverSheet(BuildContext context, BookDetailProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeCoverSheet(
        bookName: provider.book.name,
        author: provider.book.author,
      ),
    );
  }
}
