import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/dao/read_record_dao.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/search_book.dart';
import '../../core/services/crash_handler.dart';
import '../../core/services/update_service.dart';
import '../search/search_page.dart';
import '../book_detail/book_detail_page.dart';
import '../settings/settings_provider.dart';
import 'app_log_page.dart';
import 'crash_log_page.dart';
import 'read_record_page.dart';

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
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.library_books_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Legado Reader (iOS)',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '版本 0.1.0',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildListTile(
            context,
            icon: Icons.bar_chart_rounded,
            title: '閱讀統計',
            subtitle: '查看各書閱讀時長記錄',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReadRecordPage()),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.bug_report_outlined,
            title: '應用程式日誌',
            subtitle: '查看運行 Debug 日誌',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppLogPage()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.report_problem_outlined,
            title: '崩潰日誌',
            subtitle: '查看硬碟錯誤記錄 (持久化)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CrashLogPage()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.code_rounded,
            title: 'GitHub 開源位址',
            subtitle: 'github.com/gedoor/legado',
            onTap: () => _launchUrl('https://github.com/gedoor/legado'),
          ),
          _buildListTile(
            context,
            icon: Icons.system_update_outlined,
            title: '檢查更新',
            subtitle: '目前為最新版本',
            onTap: () => _checkUpdate(context),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              '本專案基於開源專案 Legado (Android) 進行 Flutter (iOS) 移植開發，僅供學習交流使用。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('無法開啟連結: $url');
    }
  }

  void _checkUpdate(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在檢查更新...'), duration: Duration(seconds: 1)),
    );
    
    final updateInfo = await AppUpdateService().checkUpdate();
    
    if (!context.mounted) return;

    if (updateInfo != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('發現新版本: ${updateInfo.versionName}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(child: Text(updateInfo.updateLog)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _launchUrl(updateInfo.downloadUrl);
              },
              child: const Text('立即下載'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前已是最新版本')),
      );
    }
  }
}
