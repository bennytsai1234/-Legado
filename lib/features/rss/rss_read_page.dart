import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/models/rss_source.dart';
import '../../core/models/rss_article.dart';
import '../../core/services/rss_parser.dart';
import '../../core/engine/analyze_url.dart';

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

  @override
  void initState() {
    super.initState();
    _useWebView = widget.source.ruleContent == null || widget.source.ruleContent!.isEmpty;
    
    if (_useWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.article.link));
      _isLoading = false;
    } else {
      _loadParsedContent();
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
            icon: Icon(_useWebView ? Icons.article : Icons.web),
            onPressed: () {
              setState(() {
                _useWebView = !_useWebView;
                if (_useWebView && !mounted) {
                   // Initialized in initState if needed
                }
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
