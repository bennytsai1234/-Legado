import 'package:flutter/material.dart';

/// BaseScaffold - 全域頁面封裝
/// 對應 Android UI 基類封裝，支援統一的 Loading 顯示與主題適配
class BaseScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool isLoading;
  final bool centeredTitle;

  const BaseScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.isLoading = false,
    this.centeredTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? (appBar ??
              AppBar(
                title: title != null ? Text(title!) : null,
                actions: actions,
                centerTitle: centeredTitle,
              ))
          : null,
      body: Stack(
        children: [
          body,
          if (isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
