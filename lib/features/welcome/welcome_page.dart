import 'package:flutter/material.dart';
import 'dart:async';
import '../bookshelf/bookshelf_page.dart';
import '../settings/settings_provider.dart';
import 'package:provider/provider.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookshelfPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 啟動圖 (未來可從 SettingsProvider 讀取使用者設定的圖片)
          Image.asset(
            'assets/welcome_bg.png', // 需確保 assets 目錄有此檔案，若無則顯示純色
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.blue.shade800,
              child: const Center(
                child: Icon(Icons.library_books, size: 100, color: Colors.white24),
              ),
            ),
          ),
          // 遮罩與文字
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Legado Reader',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                SizedBox(height: 8),
                Text(
                  '「 讀萬卷書，行萬里路 」',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
