import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:legado_reader/features/book_detail/book_detail_page.dart';
import 'package:legado_reader/features/local_book/smart_scan_page.dart';
import 'package:legado_reader/features/bookshelf/group_manage_page.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/bookshelf/widgets/bookshelf_grid_item.dart';
import 'package:legado_reader/features/bookshelf/widgets/bookshelf_list_item.dart';
import 'package:legado_reader/features/local_book/file_picker_page.dart';
import 'package:legado_reader/features/local_book/local_book_provider.dart';
import 'package:file_picker/file_picker.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> with SingleTickerProviderStateMixin {
  final Map<String, GlobalKey> _itemKeys = {};
  
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookshelfProvider>(
      builder: (context, provider, child) {
        return DefaultTabController(
          length: provider.groups.isEmpty ? 1 : provider.groups.length,
          child: Scaffold(
            appBar: AppBar(
              title: _isSearching 
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '搜尋書架書籍...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : const Text('書架', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _isSearching = false;
                        _searchCtrl.clear();
                        _searchQuery = "";
                      } else {
                        _isSearching = true;
                      }
                    });
                  },
                ),
                if (!_isSearching) _buildMoreMenu(context, provider),
              ],
              bottom: provider.groups.isEmpty ? null : TabBar(
                isScrollable: true,
                tabs: provider.groups.map((g) => Tab(text: g.groupName)).toList(),
              ),
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.groups.isEmpty
                    ? const Center(child: Text('書架空空如也，去發現看看吧'))
                    : TabBarView(
                        children: provider.groups.map((group) {
                          final groupBooks = provider.books.where((b) {
                            bool matchGroup = (group.groupId == -1) || 
                                            (group.groupId == 0 ? b.group == 0 : b.group == group.groupId);
                            if (!matchGroup) return false;
                            if (_searchQuery.isNotEmpty) {
                              final q = _searchQuery.toLowerCase();
                              return b.name.toLowerCase().contains(q) || b.author.toLowerCase().contains(q);
                            }
                            return true;
                          }).toList();

                          return RefreshIndicator(
                            onRefresh: provider.refreshBookshelf,
                            child: provider.isGridView 
                                ? _buildGridView(provider, groupBooks) 
                                : _buildListView(provider, groupBooks),
                          );
                        }).toList(),
                      ),
            bottomNavigationBar: provider.isBatchMode ? _buildBatchToolbar(context, provider) : null,
          ),
        );
      },
    );
  }

  Widget _buildGridView(BookshelfProvider provider, List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final key = _itemKeys.putIfAbsent(book.bookUrl, () => GlobalKey());
        return BookshelfGridItem(
          key: key,
          book: book,
          isBatchMode: provider.isBatchMode,
          isSelected: provider.selectedBookUrls.contains(book.bookUrl),
          showLastUpdate: provider.showLastUpdate,
          onTap: () => _onBookTap(context, provider, book),
          onLongPress: () => provider.toggleBatchMode(initialSelectedUrl: book.bookUrl),
        );
      },
    );
  }

  Widget _buildListView(BookshelfProvider provider, List<Book> books) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return BookshelfListItem(
          book: book,
          isBatchMode: provider.isBatchMode,
          isSelected: provider.selectedBookUrls.contains(book.bookUrl),
          onTap: () => _onBookTap(context, provider, book),
          onLongPress: () => provider.toggleBatchMode(initialSelectedUrl: book.bookUrl),
        );
      },
    );
  }

  void _onBookTap(BuildContext context, BookshelfProvider provider, Book book) {
    if (provider.isBatchMode) {
      provider.toggleSelect(book.bookUrl);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
    }
  }

  Widget _buildBatchToolbar(BuildContext context, BookshelfProvider provider) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.group_add_outlined), onPressed: () => _showMoveGroupDialog(context, provider)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => provider.deleteSelected()),
          IconButton(icon: const Icon(Icons.done_all), onPressed: provider.selectAll),
          IconButton(icon: const Icon(Icons.close), onPressed: provider.toggleBatchMode),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, BookshelfProvider provider) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'grid': provider.toggleViewMode(); break;
          case 'manage_group': Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupManagePage())); break;
          case 'smart_scan': 
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
              create: (_) => LocalBookProvider(),
              child: const SmartScanPage(),
            )));
            break;
          case 'manual_import':
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['txt', 'epub'],
              allowMultiple: true,
            );
            
            if (result != null && result.files.isNotEmpty) {
              for (var file in result.files) {
                if (file.path != null && context.mounted) {
                  await context.read<BookshelfProvider>().importLocalBookPath(file.path!);
                }
              }
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'grid', child: Text(provider.isGridView ? '列表模式' : '網格模式')),
        const PopupMenuItem(value: 'manage_group', child: Text('分組管理')),
        const PopupMenuItem(value: 'smart_scan', child: Text('智能掃描')),
        const PopupMenuItem(value: 'manual_import', child: Text('手動導入')),
      ],
    );
  }

  void _showMoveGroupDialog(BuildContext context, BookshelfProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移動書籍到分組'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              if (group.groupId == -1) return const SizedBox.shrink();
              return ListTile(
                title: Text(group.groupName),
                onTap: () {
                  provider.moveSelectedToGroup(group.groupId);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))],
      ),
    );
  }
}
