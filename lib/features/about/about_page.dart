import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('關於')),
      body: ListView(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Icon(Icons.library_books, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Legado Reader (iOS)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('版本 0.1.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildListTile(
            context,
            icon: Icons.history,
            title: '閱讀統計',
            onTap: () {
              // 導向閱讀紀錄統計頁
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReadRecordPage()));
            },
          ),
          _buildListTile(
            context,
            icon: Icons.bug_report_outlined,
            title: '應用程式日誌',
            onTap: () => _showComingSoon(context),
          ),
          _buildListTile(
            context,
            icon: Icons.code,
            title: 'GitHub 開源位址',
            onTap: () => _launchUrl('https://github.com/gedoor/legado'),
          ),
          _buildListTile(
            context,
            icon: Icons.update,
            title: '檢查更新',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '本專案基於開源專案 Legado (Android) 進行 Flutter (iOS) 移植開發，僅供學習交流使用。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('無法開啟連結: $url');
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能開發中')));
  }
}

class ReadRecordPage extends StatelessWidget {
  const ReadRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('閱讀統計')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text('目前暫無詳細統計數據', style: TextStyle(color: Colors.grey)),
            Text('需整合 ReadRecordDao 進行累計', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
