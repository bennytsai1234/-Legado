import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/cookie_store.dart';
import 'dynamic_form_builder.dart';

class SourceLoginPage extends StatefulWidget {
  final BookSource source;
  const SourceLoginPage({super.key, required this.source});

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  late final WebViewController? _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _useDynamicUi = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _useDynamicUi = widget.source.loginUi != null && widget.source.loginUi!.isNotEmpty;
    
    if (!_useDynamicUi) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) => setState(() => _isLoading = true),
            onPageFinished: (url) async {
              setState(() => _isLoading = false);
              await _captureCookies(url);
            },
          ),
        );
      
      // 設置 User-Agent
      if (widget.source.header != null && widget.source.header!.contains("User-Agent")) {
        // 簡單解析 Header 中的 UA (高度對位 Android 邏輯)
        final uaMatch = RegExp(r"User-Agent[:\s]+([^|\n]+)").firstMatch(widget.source.header!);
        if (uaMatch != null) {
          _controller?.setUserAgent(uaMatch.group(1)?.trim());
        }
      }

      _controller?.loadRequest(Uri.parse(widget.source.loginUrl ?? widget.source.bookSourceUrl));
    } else {
      _controller = null;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _captureCookies(String url) async {
    if (_controller == null) return;
    
    // 同時從 JS 和 CookieManager 獲取
    try {
      final jsCookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      final cleanJsCookies = jsCookies.replaceAll('"', '');
      
      // 保存至 CookieStore
      if (cleanJsCookies.isNotEmpty) {
        await CookieStore().replaceCookie(url, cleanJsCookies);
      }
      
      debugPrint('Captured JS Cookies for $url: $cleanJsCookies');
    } catch (e) {
      debugPrint('Capture JS Cookie error: $e');
    }
  }

  Future<void> _clearCookies() async {
    await _cookieManager.clearCookies();
    await CookieStore().removeCookie(widget.source.bookSourceUrl);
    _controller?.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除 Cookie')));
    }
  }

  void _handleDynamicAction(String action, Map<String, String> data) {
    // 這裡應整合 JS 注入
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('執行: $action (功能待進一步 JS 聯動補齊)'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.bookSourceName} 登入'),
        actions: [
          if (!_useDynamicUi)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
              tooltip: '重新整理',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCookies,
            tooltip: '清除 Cookie',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
            tooltip: '完成',
          ),
        ],
      ),
      body: _useDynamicUi 
        ? DynamicFormBuilder(
            loginUiJson: widget.source.loginUi!,
            controllers: _controllers,
            onAction: _handleDynamicAction,
          )
        : Stack(
            children: [
              if (_controller != null) WebViewWidget(controller: _controller),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
    );
  }
}
