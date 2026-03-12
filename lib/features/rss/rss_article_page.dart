import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/rss_source.dart';
import '../../core/models/rss_article.dart';
import 'rss_article_provider.dart';
import 'rss_read_page.dart';

class RssArticlePage extends StatelessWidget {
  final RssSource source;

  const RssArticlePage({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RssArticleProvider(source),
      child: Scaffold(
        appBar: AppBar(title: Text(source.sourceName)),
        body: Consumer<RssArticleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.articles.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadArticles(refresh: true),
              child: source.articleStyle == 2
                  ? _buildGridView(context, provider)
                  : _buildListView(context, provider),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, RssArticleProvider provider) {
    return ListView.builder(
      itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.articles.length) {
          provider.loadArticles();
          return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
        }
        final article = provider.articles[index];
        return source.articleStyle == 1 ? _buildBigImageItem(context, article) : _buildSimpleListItem(context, article);
      },
    );
  }

  Widget _buildGridView(BuildContext context, RssArticleProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.articles.length) {
          provider.loadArticles();
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGridItem(context, provider.articles[index]);
      },
    );
  }

  Widget _buildSimpleListItem(BuildContext context, RssArticle article) {
    return ListTile(
      onTap: () => _navigateToRead(context, article),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(article.pubDate ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: article.image != null && article.image!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(imageUrl: article.image!, width: 60, height: 60, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.rss_feed, size: 20)),
            )
          : null,
    );
  }

  Widget _buildBigImageItem(BuildContext context, RssArticle article) {
    return InkWell(
      onTap: () => _navigateToRead(context, article),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.image != null && article.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.image!,
                  height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            Text(article.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (article.description != null && article.description!.isNotEmpty)
              Text(article.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(article.pubDate ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, RssArticle article) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToRead(context, article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: article.image != null && article.image!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: article.image!, width: double.infinity, fit: BoxFit.cover, errorWidget: (_, __, ___) => _buildPlaceholder())
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(article.pubDate ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.rss_feed, color: Colors.white)));

  void _navigateToRead(BuildContext context, RssArticle article) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => RssReadPage(source: source, article: article)));
  }
}
