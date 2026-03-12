import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'bookshelf_provider.dart';
import '../search/search_page.dart';
import '../book_detail/book_detail_page.dart';
import '../local_book/smart_scan_page.dart';
import '../local_book/local_book_provider.dart';
import 'group_manage_page.dart';
import '../../core/models/book.dart';
import '../../core/models/search_book.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> with SingleTickerProviderStateMixin {
  final Map<String, GlobalKey> _itemKeys = {};
  String? _dragStartUrl;
  Set<String> _initialSelected = {};

  void _handleDragUpdate(Offset localPosition, List<Book> groupBooks, BookshelfProvider provider) {
    if (!provider.isBatchMode) return;

    String? hoveredUrl;
    for (var book in groupBooks) {
      final key = _itemKeys[book.bookUrl];
      if (key == null || key.currentContext == null) continue;

      final box = key.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final size = box.size;
      final rect = Rect.fromLTWH(position.dx, position.globalToLocal(Offset.zero).dy + position.dy, size.width, size.height);
      
      // 使用更簡單的 hitTest 方式
      final globalPos = (context.findRenderObject() as RenderBox).localToGlobal(localPosition);
      final localInBox = box.globalToLocal(globalPos);
      if (localInBox.dx >= 0 && localInBox.dx <= size.width && localInBox.dy >= 0 && localInBox.dy <= size.height) {
        hoveredUrl = book.bookUrl;
        break;
      }
    }

    if (hoveredUrl != null && _dragStartUrl != null) {
      final startIndex = groupBooks.indexWhere((b) => b.bookUrl == _dragStartUrl);
      final currentIndex = groupBooks.indexWhere((b) => b.bookUrl == hoveredUrl);
      
      if (startIndex != -1 && currentIndex != -1) {
        final start = startIndex < currentIndex ? startIndex : currentIndex;
        final end = startIndex < currentIndex ? currentIndex : startIndex;
        
        final bool shouldSelect = !_initialSelected.contains(_dragStartUrl);
        
        for (int i = 0; i < groupBooks.length; i++) {
          final url = groupBooks[i].bookUrl;
          if (i >= start && i <= end) {
            provider.setSelected(url, shouldSelect);
          } else {
            // 恢復至拖拽前的狀態
            provider.setSelected(url, _initialSelected.contains(url));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookshelfProvider>(
      builder: (context, provider, child) {
        return DefaultTabController(
          length: provider.groups.isEmpty ? 1 : provider.groups.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('書架', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
                ),
                _buildMoreMenu(context, provider),
              ],
              bottom: provider.groups.isEmpty ? null : TabBar(
                isScrollable: true,
                tabs: provider.groups.map((g) => Tab(text: g.groupName)).toList(),
                onTap: (index) {
                  provider.setGroup(provider.groups[index].groupId);
                },
              ),
            ),
            body: Column(
              children: [
                if (provider.isBatchMode) _buildBatchToolbar(provider),
                Expanded(
                  child: provider.groups.isEmpty 
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: provider.groups.map((group) {
                          final groupBooks = provider.books.where((b) {
                            if (group.groupId == -1) return true; // 全選
                            if (group.groupId == 0) return b.group == 0; // 未分組
                            return b.group == group.groupId;
                          }).toList();

                          if (groupBooks.isEmpty) {
                            return const Center(child: Text('書架空空如也，去搜書吧'));
                          }

                          return RefreshIndicator(
                            onRefresh: () => provider.refreshBookshelf(),
                            child: GestureDetector(
                              onPanStart: (details) {
                                if (provider.isBatchMode) {
                                  _initialSelected = Set.from(provider.selectedBookUrls);
                                  // 這裡簡單處理：透過觸發位置找 startUrl 邏輯較複雜，
                                  // 我們在 GridItem/ListItem 的 LongPress 中已經開啟了 BatchMode。
                                }
                              },
                              onPanUpdate: (details) => _handleDragUpdate(details.localPosition, groupBooks, provider),
                              child: provider.isGridLayout
                                  ? _buildGridView(provider, groupBooks)
                                  : _buildListView(provider, groupBooks),
                            ),
                          );
                        }).toList(),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreMenu(BuildContext context, BookshelfProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'import_local':
            provider.importLocalBook();
            break;
          case 'smart_scan':
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
              create: (_) => LocalBookProvider(),
              child: const SmartScanPage(),
            )));
            break;
          case 'import_url':
            _showImportUrlDialog(context, provider);
            break;
          case 'export':
            provider.exportBookshelf();
            break;
          case 'layout_config':
            _showLayoutConfigDialog(context, provider);
            break;
          case 'manage_groups':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupManagePage()));
            break;
          case 'toggle_layout':
            provider.toggleLayout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle_layout', 
          child: Row(children: [
            Icon(provider.isGridLayout ? Icons.list : Icons.grid_view, size: 20),
            const SizedBox(width: 10),
            Text(provider.isGridLayout ? '切換列表' : '切換網格')
          ])
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'import_local', child: Text('匯入本機書籍')),
        const PopupMenuItem(value: 'smart_scan', child: Text('智慧掃描目錄')),
        const PopupMenuItem(value: 'import_url', child: Text('從 URL 匯入')),
        const PopupMenuItem(value: 'export', child: Text('導出書架 (JSON)')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'manage_groups', child: Text('管理分組')),
        const PopupMenuItem(value: 'layout_config', child: Text('版面設定')),
      ],
    );
  }

  Widget _buildBatchToolbar(BookshelfProvider provider) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('已選擇 ${provider.selectedBookUrls.length} 本'),
          Row(
            children: [
              TextButton(onPressed: provider.clearSelected, child: const Text('取消')),
              TextButton(onPressed: () => _showMoveGroupDialog(context, provider), child: const Text('移動')),
              TextButton(
                onPressed: provider.deleteSelected, 
                child: const Text('刪除', style: TextStyle(color: Colors.red))
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BookshelfProvider provider, List<Book> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _buildGridItem(provider, books[index]),
    );
  }

  Widget _buildGridItem(BookshelfProvider provider, Book book) {
    final isSelected = provider.selectedBookUrls.contains(book.bookUrl);
    _itemKeys.putIfAbsent(book.bookUrl, () => GlobalKey());
    
    return GestureDetector(
      key: _itemKeys[book.bookUrl],
      onLongPress: () => provider.toggleBatchMode(book.bookUrl),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(book.bookUrl);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(searchBook: AggregatedSearchBook(book: SearchBook(bookUrl: book.bookUrl, name: book.name, author: book.author, coverUrl: book.coverUrl, intro: book.intro, origin: book.origin, originName: book.originName, type: book.type), sources: [book.originName ?? '本地']))));
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => _buildCoverPlaceholder(book),
                          )
                        : _buildCoverPlaceholder(book),
                  ),
                ),
                if (provider.isBatchMode)
                  Positioned(
                    right: 4, top: 4,
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.white70,
                    ),
                  ),
                if (book.lastCheckCount > 0 && !provider.isBatchMode && provider.showUnread)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4))),
                      child: Text('${book.lastCheckCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BookshelfProvider provider, List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
      itemBuilder: (context, index) => _buildListItem(provider, books[index]),
    );
  }

  Widget _buildListItem(BookshelfProvider provider, Book book) {
    final isSelected = provider.selectedBookUrls.contains(book.bookUrl);
    _itemKeys.putIfAbsent(book.bookUrl, () => GlobalKey());

    return ListTile(
      key: _itemKeys[book.bookUrl],
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: 50, height: 70,
          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? CachedNetworkImage(imageUrl: book.coverUrl!, fit: BoxFit.cover, errorWidget: (context, url, error) => _buildCoverPlaceholder(book))
              : _buildCoverPlaceholder(book),
        ),
      ),
      title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${book.author} · ${book.originName}', style: const TextStyle(fontSize: 12)),
          Text(book.latestChapterTitle ?? '暫無目錄', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      trailing: provider.isBatchMode 
          ? Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.blue : null)
          : (book.lastCheckCount > 0 && provider.showUnread ? const Icon(Icons.fiber_new, color: Colors.red) : null),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(book.bookUrl);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(searchBook: AggregatedSearchBook(book: SearchBook(bookUrl: book.bookUrl, name: book.name, author: book.author, coverUrl: book.coverUrl, intro: book.intro, origin: book.origin, originName: book.originName, type: book.type), sources: [book.originName ?? '本地']))));
        }
      },
      onLongPress: () => provider.toggleBatchMode(book.bookUrl),
    );
  }

  Widget _buildCoverPlaceholder(Book book) {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(child: Text(book.name.isNotEmpty ? book.name[0] : '書', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
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
            children: provider.groups.where((g) => g.groupId >= 0).map((group) {
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
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupManagePage())); }, child: const Text('管理分組')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ],
      ),
    );
  }

  void _showImportUrlDialog(BuildContext context, BookshelfProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('從 URL 匯入'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '輸入 JSON 檔案 URL'), maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () { if (controller.text.isNotEmpty) provider.importBookshelfFromUrl(controller.text); Navigator.pop(context); }, child: const Text('確定')),
        ],
      ),
    );
  }

  void _showLayoutConfigDialog(BuildContext context, BookshelfProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('版面設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(builder: (context, setState) => SwitchListTile(title: const Text('顯示未讀標記'), value: provider.showUnread, onChanged: (val) { provider.toggleShowUnread(); setState(() {}); })),
            StatefulBuilder(builder: (context, setState) => SwitchListTile(title: const Text('顯示最後更新時間'), value: provider.showLastUpdate, onChanged: (val) { provider.toggleShowLastUpdate(); setState(() {}); })),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉'))],
      ),
    );
  }
}
