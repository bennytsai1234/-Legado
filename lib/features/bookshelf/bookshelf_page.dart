import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'bookshelf_provider.dart';
import '../search/search_page.dart';
import '../book_detail/book_detail_page.dart';
import '../../core/models/search_book.dart';
import '../reader/reader_page.dart';

class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的書架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BookshelfProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.books.isEmpty) {
            return _buildEmptyView(context);
          }
          return RefreshIndicator(
            onRefresh: provider.refreshBookshelf,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: provider.books.length,
              itemBuilder: (context, index) {
                final book = provider.books[index];
                return _buildBookItem(context, provider, book);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('書架空空如也', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            child: const Text('去搜尋'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(
    BuildContext context,
    BookshelfProvider provider,
    dynamic book,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ReaderPage(book: book, chapterIndex: book.durChapterIndex),
          ),
        );
      },
      onLongPress: () => _showBookMenu(context, provider, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child:
                      book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget:
                                (context, url, error) =>
                                    _buildCoverPlaceholder(),
                          )
                          : _buildCoverPlaceholder(),
                ),
                if (book.lastCheckCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      child: const Icon(Icons.book, color: Colors.grey),
    );
  }

  void _showBookMenu(
    BuildContext context,
    BookshelfProvider provider,
    dynamic book,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('書籍詳情'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BookDetailPage(
                            searchBook: SearchBook(
                              bookUrl: book.bookUrl,
                              name: book.name,
                              author: book.author,
                              coverUrl: book.coverUrl,
                              intro: book.intro,
                              origin: book.origin,
                              originName: book.originName,
                            ),
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('移出書架', style: TextStyle(color: Colors.red)),
                onTap: () {
                  provider.removeBook(book);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
