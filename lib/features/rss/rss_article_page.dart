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
              child: ListView.builder(
                itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.articles.length) {
                    provider.loadArticles();
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final article = provider.articles[index];
                  return _buildArticleItem(context, article);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildArticleItem(BuildContext context, RssArticle article) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RssReadPage(source: source, article: article),
          ),
        );
      },
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
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (article.description != null && article.description!.isNotEmpty)
              Text(
                article.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  article.pubDate ?? "",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
