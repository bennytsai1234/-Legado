import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/models/rss_star.dart';
import 'package:legado_reader/core/database/dao/rss_star_dao.dart';
import 'package:legado_reader/core/services/rss_parser.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';

class RssReadPage extends StatefulWidget {
  final RssSource source;
  final RssArticle article;

  const RssReadPage({super.key, required this.source, required this.article});

  @override
  State<RssReadPage> createState() => _RssReadPageState();
}

class _RssReadPageState extends State<RssReadPage> {
  late final WebViewController _controller;
  bool _useWebView = true;
  String? _parsedContent;
  bool _isLoading = true;
  
  bool _isFavorite = false;
  final RssStarDao _starDao = RssStarDao();
  RssStar? _star;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _useWebView = widget.source.ruleContent == null || widget.source.ruleContent!.isEmpty;
    
    if (_useWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              // 圖片與 WebView 內容優化處理
              _controller.runJavaScript(
                  "var style = document.createElement('style'); style.innerHTML = 'img { max-width: 100%; height: auto; } body { padding: 10px; font-size: 16px; }'; document.head.appendChild(style);"
              );
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.article.link));
      _isLoading = false;
    } else {
      _loadParsedContent();
    }
  }

  Future<void> _checkFavorite() async {
    final stars = await _starDao.getAll();
    try {
      _star = stars.firstWhere((s) => s.link == widget.article.link);
      if (mounted) {
        setState(() {
          _isFavorite = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite && _star != null) {
      await _starDao.delete(_star!.origin, _star!.link);
      setState(() {
        _isFavorite = false;
        _star = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消收藏')));
      }
    } else {
      final newStar = RssStar(
        origin: widget.source.sourceUrl,
        title: widget.article.title,
        link: widget.article.link,
        pubDate: widget.article.pubDate,
        description: widget.article.description,
        image: widget.article.image,
      );
      await _starDao.insert(newStar);
      setState(() {
        _isFavorite = true;
        _star = newStar;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入收藏')));
      }
    }
  }

  Future<void> _loadParsedContent() async {
    try {
      final analyzeUrl = AnalyzeUrl(widget.article.link);
      final body = await analyzeUrl.getResponseBody();
      final content = await RssParser.parseContent(widget.source, body, widget.article.link);
      setState(() {
        _parsedContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _parsedContent = "加載內容失敗: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.yellow : null),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(_useWebView ? Icons.article : Icons.web),
            onPressed: () {
              setState(() {
                _useWebView = !_useWebView;
              });
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _useWebView 
          ? WebViewWidget(controller: _controller)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(_parsedContent ?? ""),
            ),
    );
  }
}
