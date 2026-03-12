import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'bookshelf_provider.dart';
import '../search/search_page.dart';
import '../../core/models/book_group.dart';
import '../reader/reader_page.dart';

class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookshelfProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.isBatchMode 
              ? '已選擇 ${provider.selectedBookUrls.length} 本' 
              : '我的書架'),
            actions: provider.isBatchMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: '全選',
                      onPressed: provider.selectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '取消',
                      onPressed: provider.toggleBatchMode,
                    ),
                  ]
                : [
                    PopupMenuButton<int>(
                      icon: const Icon(Icons.sort),
                      onSelected: provider.setSortType,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0, 
                          child: Row(
                            children: [
                              Icon(Icons.reorder, color: provider.sortType == 0 ? Colors.blue : null, size: 18),
                              const SizedBox(width: 8),
                              const Text('自訂排序'),
                            ],
                          )
                        ),
                        const PopupMenuItem(value: 1, child: Text('最近更新')),
                        const PopupMenuItem(value: 2, child: Text('最近閱讀')),
                      ],
                    ),
                    IconButton(
                      icon: Icon(provider.isGridLayout ? Icons.view_list : Icons.grid_view),
                      tooltip: '切換佈局',
                      onPressed: provider.toggleLayout,
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload),
                      tooltip: '匯入本地書籍',
                      onPressed: provider.importLocalBook,
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: '搜尋',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage()),
                        );
                      },
                    ),
                  ],
          ),
          body: Column(
            children: [
              if (!provider.isBatchMode) _buildGroupTabs(context, provider),
              Expanded(
                child: _buildBody(context, provider),
              ),
            ],
          ),
          bottomNavigationBar: provider.isBatchMode ? _buildBatchBottomBar(context, provider) : null,
        );
      },
    );
  }

  Widget _buildGroupTabs(BuildContext context, BookshelfProvider provider) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildGroupChip(context, provider, BookGroup.idAll, '全部'),
          _buildGroupChip(context, provider, BookGroup.idLocal, '本地'),
          _buildGroupChip(context, provider, BookGroup.idAudio, '音訊'),
          _buildGroupChip(context, provider, BookGroup.idError, '更新錯誤'),
          ...provider.groups.map((g) => _buildGroupChip(context, provider, g.groupId, g.groupName)),
          ActionChip(
            label: const Icon(Icons.add, size: 18),
            onPressed: () => _showAddGroupDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChip(BuildContext context, BookshelfProvider provider, int id, String name) {
    final isSelected = provider.currentGroupId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) provider.setGroup(id);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookshelfProvider provider) {
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.books.isEmpty) {
      return _buildEmptyView(context, provider);
    }

    if (!provider.isGridLayout && provider.sortType == 0 && !provider.isBatchMode) {
      // 僅在清單模式且自訂排序時支援拖曳排序 (Flutter 限制)
      return RefreshIndicator(
        onRefresh: provider.refreshBookshelf,
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.books.length,
          onReorder: provider.reorderBook,
          itemBuilder: (context, index) {
            final book = provider.books[index];
            return _buildBookListItem(context, provider, book, key: ValueKey(book.bookUrl));
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refreshBookshelf,
      child: provider.isGridLayout 
        ? GridView.builder(
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
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.books.length,
            itemBuilder: (context, index) {
              final book = provider.books[index];
              return _buildBookListItem(context, provider, book);
            },
          ),
    );
  }

  Widget _buildBookListItem(BuildContext context, BookshelfProvider provider, dynamic book, {Key? key}) {
    bool isSelected = provider.selectedBookUrls.contains(book.bookUrl);
    return ListTile(
      key: key,
      leading: SizedBox(
        width: 40,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: book.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildCoverPlaceholder(),
                )
              : _buildCoverPlaceholder(),
        ),
      ),
      title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(book.durChapterTitle ?? '未開始閱讀', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: provider.isBatchMode 
          ? Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.blue : null)
          : (book.lastCheckCount > 0 ? const Icon(Icons.fiber_new, color: Colors.red) : null),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(book.bookUrl);
        } else {
          Navigator.push(
            context, MaterialPageRoute(builder: (context) => ReaderPage(book: book, chapterIndex: book.durChapterIndex)),
          );
        }
      },
      onLongPress: () {
        if (!provider.isBatchMode) {
          provider.toggleBatchMode();
          provider.toggleSelect(book.bookUrl);
        }
      },
    );
  }

  Widget _buildEmptyView(BuildContext context, BookshelfProvider provider) {
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
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: provider.importLocalBook,
            child: const Text('匯入本地書籍'),
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
    bool isSelected = provider.selectedBookUrls.contains(book.bookUrl);

    return GestureDetector(
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(book.bookUrl);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ReaderPage(book: book, chapterIndex: book.durChapterIndex),
            ),
          );
        }
      },
      onLongPress: () {
        if (!provider.isBatchMode) {
          provider.toggleBatchMode();
          provider.toggleSelect(book.bookUrl);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (context, url, error) => _buildCoverPlaceholder(),
                        )
                      : _buildCoverPlaceholder(),
                ),
                if (book.lastCheckCount > 0 && !provider.isBatchMode)
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
                if (provider.isBatchMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.white70,
                    ),
                  )
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

  Widget _buildBatchBottomBar(BuildContext context, BookshelfProvider provider) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.drive_file_move),
            label: const Text('移動'),
            onPressed: provider.selectedBookUrls.isEmpty ? null : () {
              _showMoveGroupDialog(context, provider);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('刪除', style: TextStyle(color: Colors.red)),
            onPressed: provider.selectedBookUrls.isEmpty ? null : () {
              provider.deleteSelected();
            },
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, BookshelfProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增分組'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '輸入分組名稱'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createGroup(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showMoveGroupDialog(BuildContext context, BookshelfProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇分組'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.groups.map((group) {
              return ListTile(
                title: Text(group.groupName),
                onTap: () {
                  provider.moveSelectedToGroup(group.groupId);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
