import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/cookie_store.dart';

class SourceLoginPage extends StatefulWidget {
  final BookSource source;
  const SourceLoginPage({super.key, required this.source});

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      )
      ..loadRequest(Uri.parse(widget.source.loginUrl ?? widget.source.bookSourceUrl));
  }

  Future<void> _captureCookies(String url) async {
    final cookieString = await _controller.runJavaScriptReturningResult('document.cookie') as String;
    // 去掉引號
    final cleanCookie = cookieString.replaceAll('"', '');
    if (cleanCookie.isNotEmpty) {
      await CookieStore().setCookie(url, cleanCookie);
      debugPrint('Captured Cookies for $url: $cleanCookie');
    }
  }

  Future<void> _checkLoginStatus() async {
    if (widget.source.loginCheckJs == null || widget.source.loginCheckJs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cookie 已保存')));
      return;
    }

    // 這裡本應透過 JS 引擎執行 loginCheckJs，
    // 但為簡化，我們假設保存 Cookie 成功即提示。
    // 在 Legado 中，通常是在 WebView 內執行檢查。
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登入狀態已嘗試擷取')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.bookSourceName} 登入'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _checkLoginStatus();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
