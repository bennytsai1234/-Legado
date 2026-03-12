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
        )
        ..loadRequest(Uri.parse(widget.source.loginUrl ?? widget.source.bookSourceUrl));
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
    final cookieString = await _controller.runJavaScriptReturningResult('document.cookie') as String;
    // 去掉引號
    final cleanCookie = cookieString.replaceAll('"', '');
    if (cleanCookie.isNotEmpty) {
      await CookieStore().setCookie(url, cleanCookie);
      debugPrint('Captured Cookies for $url: $cleanCookie');
    }
  }

  void _handleDynamicAction(String action, Map<String, String> data) {
    debugPrint("Dynamic Action: $action, Data: $data");
    // 在 Legado 中，這裡通常會執行 JS 腳本來處理登入
    // 目前我們先模擬成功
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已執行動作: $action，資料: ${data.keys.join(', ')}'))
    );
  }

  Future<void> _checkLoginStatus() async {
    if (widget.source.loginCheckJs == null || widget.source.loginCheckJs!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cookie 已保存')));
      return;
    }
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
