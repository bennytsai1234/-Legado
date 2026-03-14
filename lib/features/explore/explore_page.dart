import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_provider.dart';
import 'package:legado_reader/features/search/search_page.dart';
import 'widgets/explore_dashboard.dart';
import 'widgets/explore_focused_view.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override State<ExplorePage> createState() => _ExplorePageState();
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
                IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearchDialog(context, provider)),
                _buildSourcePicker(context, provider),
              ],
            ),
            body: provider.selectedSource == null 
                ? ExploreDashboard(provider: provider, expandedSourceUrl: _expandedSourceUrl, onExpansionChanged: (v) => setState(() => _expandedSourceUrl = v))
                : ExploreFocusedView(provider: provider),
          );
        },
      ),
    );
  }

  Widget _buildSourcePicker(BuildContext context, ExploreProvider provider) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (ctx) => ListView.builder(
          itemCount: provider.sources.length,
          itemBuilder: (ctx, idx) => ListTile(title: Text(provider.sources[idx].bookSourceName), onTap: () { provider.setSource(provider.sources[idx]); Navigator.pop(ctx); }),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ExploreProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜尋發現'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(hintText: '輸入關鍵字或 group:名稱')),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: provider.groups.map((g) => ActionChip(label: Text(g, style: const TextStyle(fontSize: 12)), onPressed: () { provider.setGroup(g); Navigator.pop(ctx); })).toList()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            final text = controller.text.trim();
            if (text.startsWith('group:')) {
              provider.setGroup(text.replaceFirst('group:', ''));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialQuery: text)));
            }
            Navigator.pop(ctx);
          }, child: const Text('搜尋')),
        ],
      ),
    );
  }
}
