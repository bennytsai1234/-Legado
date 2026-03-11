import 'package:flutter/material.dart';
import '../../core/models/rss_source.dart';
import '../../core/models/rss_article.dart';
import '../../core/services/rss_parser.dart';
import '../../core/engine/analyze_url.dart';
import '../../core/engine/analyze_rule.dart';

class RssArticleProvider extends ChangeNotifier {
  final RssSource source;
  List<RssArticle> _articles = [];
  bool _isLoading = false;
  int _page = 1;
  String? _nextPageUrl;

  List<RssArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextPageUrl != null || _page == 1;

  RssArticleProvider(this.source) {
    loadArticles();
  }

  Future<void> loadArticles({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _articles = [];
      _nextPageUrl = null;
    }

    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final url = _nextPageUrl ?? source.sourceUrl;
      final analyzer = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        url,
        page: _page,
        baseUrl: source.sourceUrl,
        analyzer: analyzer,
      );

      final body = await analyzeUrl.getResponseBody();
      if (body.isNotEmpty) {
        final newArticles = await RssParser.parseArticles(
          source,
          body,
          analyzeUrl.url,
        );
        _articles.addAll(newArticles);

        // 處理下一頁
        if (source.ruleNextPage != null && source.ruleNextPage!.isNotEmpty) {
          final rule = analyzer.setContent(body, baseUrl: analyzeUrl.url);
          _nextPageUrl = rule.getString(source.ruleNextPage!, isUrl: true);
        } else {
          _nextPageUrl = null;
        }
        _page++;
      }
    } catch (e) {
      debugPrint('加載 RSS 文章失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
