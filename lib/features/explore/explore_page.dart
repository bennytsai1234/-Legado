import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';
import 'explore_provider.dart';
import '../book_detail/book_detail_page.dart';
import '../search/search_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? _expandedSourceUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: Consumer<ExploreProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('發現'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context, provider),
                ),
                _buildSourcePicker(context, provider),
              ],
            ),
            body: provider.selectedSource == null 
                ? _buildDashboard(provider)
                : _buildFocusedExplore(provider),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(ExploreProvider provider) {
    if (provider.sources.isEmpty) {
      return const Center(child: Text('目前無可用發現規則的書源'));
    }

    return ListView.builder(
      itemCount: provider.sources.length,
      itemBuilder: (context, index) {
        final source = provider.sources[index];
        final isExpanded = _expandedSourceUrl == source.bookSourceUrl;

        return ExpansionTile(
          key: PageStorageKey(source.bookSourceUrl),
          title: Text(source.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(source.bookSourceGroup ?? '未分組', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedSourceUrl = expanded ? source.bookSourceUrl : null;
            });
            if (expanded) {
              provider.setSource(source);
            }
          },
          children: [
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.exploreConfigs.map((config) {
                    return ActionChip(
                      label: Text(config['title'] ?? '', style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        provider.setConfig(config);
                        // 自動進入專注模式
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFocusedExplore(ExploreProvider provider) {
    return Column(
      children: [
        _buildExploreHeader(provider),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildExploreResults(provider),
        ),
      ],
    );
  }

  Widget _buildExploreHeader(ExploreProvider provider) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            title: Text(provider.selectedSource!.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => provider.setSource(null),
            ),
          ),
          _buildExploreConfig(provider),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ExploreProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('發現搜尋'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '輸入關鍵字或 group:分組名',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (val) {
            Navigator.pop(ctx);
            _handleSearch(context, provider, val);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSearch(context, provider, controller.text);
            },
            child: const Text('搜尋'),
          ),
        ],
      ),
    );
  }

  void _handleSearch(BuildContext context, ExploreProvider provider, String query) {
    if (query.startsWith('group:')) {
      final group = query.substring(6).trim();
      provider.setGroup(group);
    } else if (query.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialKeyword: query)));
    }
  }

  Widget _buildSourcePicker(BuildContext context, ExploreProvider provider) {
    return Row(
      children: [
        // 分組過濾 (對應 Android upGroupsMenu)
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          tooltip: '過濾分組',
          onSelected: provider.setGroup,
          itemBuilder: (context) => [
            const PopupMenuItem(value: '全部', child: Text('全部')),
            ...provider.groups.map((g) => PopupMenuItem(value: g, child: Text(g))),
          ],
        ),
        // 書源選擇
        Expanded(
          child: PopupMenuButton<BookSource>(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Expanded(child: Text(provider.selectedSource?.bookSourceName ?? '選擇書源', overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            onSelected: provider.setSource,
            itemBuilder: (context) => provider.sources.map((s) => PopupMenuItem(
              value: s,
              child: InkWell(
                onLongPress: () {
                  Navigator.pop(context); // 關閉選單
                  _showSourceManageDialog(context, s, provider);
                },
                child: Text(s.bookSourceName),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showSourceManageDialog(BuildContext context, BookSource source, ExploreProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.vertical_align_top),
            title: const Text('置頂書源'),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: 實作置頂邏輯 (更新 customOrder)
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('編輯書源'),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: 跳轉至書源編輯頁
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('站內搜尋'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialSource: source)));
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExploreConfig(ExploreProvider provider) {
    if (provider.exploreConfigs.isEmpty) return const SizedBox();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.exploreConfigs.length,
        itemBuilder: (context, index) {
          final config = provider.exploreConfigs[index];
          final isSelected = provider.selectedConfig == config;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(config['title'] ?? ''),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) provider.setConfig(config);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreResults(ExploreProvider provider) {
    if (provider.books.isEmpty) {
      return const Center(child: Text('請選擇書源開始探索'));
    }

    // 判斷是否為網格模式 (style: 1 為網格, layout: 1 也是網格)
    final isGrid = provider.selectedConfig?['style'] == 1 || 
                   provider.selectedConfig?['style'] == "1" ||
                   provider.selectedConfig?['layout'] == 1;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: isGrid ? _buildExploreGrid(provider) : _buildExploreList(provider),
    );
  }

  Widget _buildExploreList(ExploreProvider provider) {
    return ListView.builder(
      itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.books.length) {
          provider.loadMore();
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        final book = provider.books[index];
        return ListTile(
          leading: _buildCover(book, width: 45, height: 60),
          title: Text(book.name),
          subtitle: Text('${book.author ?? '未知'} · ${book.kind ?? ''}'),
          onTap: () => _openBookDetail(context, book),
        );
      },
    );
  }

  Widget _buildExploreGrid(ExploreProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.books.length) {
          provider.loadMore();
          return const Center(child: CircularProgressIndicator());
        }
        final book = provider.books[index];
        return GestureDetector(
          onTap: () => _openBookDetail(context, book),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCover(book)),
              const SizedBox(height: 4),
              Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(book.author ?? '未知', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCover(SearchBook book, {double? width, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: book.coverUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.book)),
            )
          : Container(color: Colors.grey[200], child: const Icon(Icons.book)),
    );
  }

  void _openBookDetail(BuildContext context, SearchBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          searchBook: AggregatedSearchBook(
            book: book,
            sources: [book.originName ?? '發現'],
          ),
        ),
      ),
    );
  }
}
