import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:legado_reader/features/book_detail/book_detail_page.dart';
import 'package:legado_reader/features/reader/reader_page.dart';
import 'package:legado_reader/features/search/search_page.dart';
import 'package:legado_reader/features/explore/explore_page.dart';
import 'package:legado_reader/features/source_manager/source_manager_page.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/reader/audio_player_page.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookshelfProvider>().refreshBookshelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('書架'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()))),
          IconButton(icon: const Icon(Icons.explore), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage()))),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'source', child: Text('書源管理')),
              const PopupMenuItem(value: 'settings', child: Text('系統設定')),
            ],
            onSelected: (value) {
              if (value == 'source') { Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceManagerPage())); }
              if (value == 'settings') { Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); }
            },
          ),
        ],
      ),
      body: Consumer<BookshelfProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.books.isEmpty) { return const Center(child: CircularProgressIndicator()); }
          if (provider.books.isEmpty) { return const Center(child: Text('書架空空如也，去搜尋看看吧')); }

          return RefreshIndicator(
            onRefresh: () => provider.refreshBookshelf(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.books.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final book = provider.books[index];
                return _buildBookItem(context, book);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookItem(BuildContext context, Book book) {
    return InkWell(
      onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book))),
      onTap: () {
        if (book.type == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AudioPlayerPage(book: book, chapterIndex: book.durChapterIndex)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(book: book, chapterIndex: book.durChapterIndex, chapterPos: book.durChapterPos)));
        }
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl ?? "",
                width: 80, height: 110, fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(book.author, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1),
                    const Spacer(),
                    Text('讀至: ${book.durChapterTitle}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.update, size: 12, color: Colors.orangeAccent),
                        const SizedBox(width: 4),
                        Expanded(child: Text('最新: ${book.latestChapterTitle}', style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
