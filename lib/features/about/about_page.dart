import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/database/dao/read_record_dao.dart';
import '../../core/database/dao/book_dao.dart';
import '../../core/models/search_book.dart';
import '../../core/services/crash_handler.dart';
import '../search/search_page.dart';
import '../book_detail/book_detail_page.dart';
import '../settings/settings_provider.dart';

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
    try {
      final response = await Dio().get(
        'https://api.github.com/repos/gedoor/legado/releases/latest',
      );
      final latest = response.data['tag_name'] as String? ?? 'unknown';
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('版本資訊'),
            content: Text('目前版本：0.1.0\nLegado 最新版本：$latest\n\n本 App 為 Flutter 移植版本，版本號獨立管理。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('確定'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchUrl('https://github.com/gedoor/legado/releases');
                },
                child: const Text('查看 Releases'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('檢查更新失敗: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }
}

// ----------------------------------------------------------------
// ReadRecordPage - 閱讀統計頁
// 對應 Android: ui/about/ReadRecordActivity.kt
// ----------------------------------------------------------------

enum _SortMode { byName, byReadTime, byLastRead }

class ReadRecordPage extends StatefulWidget {
  const ReadRecordPage({super.key});

  @override
  State<ReadRecordPage> createState() => _ReadRecordPageState();
}

class _ReadRecordPageState extends State<ReadRecordPage> {
  final ReadRecordDao _dao = ReadRecordDao();
  final BookDao _bookDao = BookDao();
  final TextEditingController _searchController = TextEditingController();

  List<ReadRecordShow> _records = [];
  int _allTime = 0;
  _SortMode _sortMode = _SortMode.byName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSortMode().then((_) => _loadData());
    _loadAllTime();
  }

  Future<void> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('read_record_sort') ?? 0;
    if (mounted) {
      setState(() {
        _sortMode = _SortMode.values[index];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTime() async {
    final t = await _dao.getAllTime();
    if (mounted) setState(() => _allTime = t);
  }

  Future<void> _loadData([String searchKey = '']) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    List<ReadRecordShow> records;
    if (searchKey.isEmpty) {
      records = await _dao.getAllShow();
    } else {
      records = await _dao.search(searchKey);
    }

    // 依照排序模式排序
    switch (_sortMode) {
      case _SortMode.byName:
        records.sort((a, b) => a.bookName.compareTo(b.bookName));
        break;
      case _SortMode.byReadTime:
        records.sort((a, b) => b.readTime.compareTo(a.readTime));
        break;
      case _SortMode.byLastRead:
        records.sort((a, b) => b.lastRead.compareTo(a.lastRead));
        break;
    }

    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除全部'),
        content: const Text('確定要刪除所有閱讀記錄嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dao.clear();
      await _loadAllTime();
      await _loadData(_searchController.text);
    }
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '0 秒';
    final days = ms ~/ (1000 * 60 * 60 * 24);
    final hours = (ms % (1000 * 60 * 60 * 24)) ~/ (1000 * 60 * 60);
    final minutes = (ms % (1000 * 60 * 60)) ~/ (1000 * 60);
    final seconds = (ms % (1000 * 60)) ~/ 1000;
    final buf = StringBuffer();
    if (days > 0) buf.write('$days 天 ');
    if (hours > 0) buf.write('$hours 小時 ');
    if (minutes > 0) buf.write('$minutes 分鐘 ');
    if (seconds > 0 && days == 0) buf.write('$seconds 秒');
    return buf.toString().trim();
  }

  String _formatDate(int ms) {
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('閱讀統計'),
        actions: [
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.sort),
            tooltip: '更多設定',
            initialValue: _sortMode,
            onSelected: (val) {
              if (val is _SortMode) {
                setState(() => _sortMode = val);
                _loadData(_searchController.text);
              } else if (val == 'toggle_record') {
                settings.setEnableReadRecord(!settings.enableReadRecord);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SortMode.byName,
                child: Text('依書名排序'),
              ),
              const PopupMenuItem(
                value: _SortMode.byReadTime,
                child: Text('依閱讀時長排序'),
              ),
              const PopupMenuItem(
                value: _SortMode.byLastRead,
                child: Text('依最後閱讀時間排序'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'toggle_record',
                child: Row(
                  children: [
                    Icon(settings.enableReadRecord ? Icons.check_box : Icons.check_box_outline_blank, size: 20),
                    const SizedBox(width: 8),
                    const Text('啟用閱讀記錄'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清除全部記錄',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text('累計閱讀時長：', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                Text(_formatDuration(_allTime), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋書名...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _loadData(); }) : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                filled: true,
              ),
              onChanged: (val) => _loadData(val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_toggle_off, size: 72, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)), const SizedBox(height: 16), Text('暫無閱讀記錄', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)))]))
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 4, bottom: 24),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), child: Text(record.bookName.isNotEmpty ? record.bookName[0] : '？', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
                            title: Text(record.bookName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Row(children: [const Icon(Icons.timer_outlined, size: 13, color: Colors.grey), const SizedBox(width: 4), Text(_formatDuration(record.readTime), style: const TextStyle(fontSize: 12))]),
                            trailing: record.lastRead > 0 ? Text(_formatDate(record.lastRead), style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
                            onTap: () async {
                              final bookList = await _bookDao.findByName(record.bookName);
                              if (!context.mounted) return;
                              if (bookList.isEmpty) { Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialQuery: record.bookName))); }
                              else { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(searchBook: AggregatedSearchBook(book: SearchBook(bookUrl: bookList.first.bookUrl, name: bookList.first.name, author: bookList.first.author, origin: bookList.first.origin, originName: bookList.first.originName), sources: [bookList.first.originName])))); }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// AppLog - 全域記憶體日誌管理
// ----------------------------------------------------------------

class AppLog {
  static final List<AppLogEntry> _logs = [];
  static List<AppLogEntry> get logs => List.unmodifiable(_logs);

  static void put(String message, [Object? error]) {
    _logs.add(AppLogEntry(time: DateTime.now(), message: message, error: error));
    if (_logs.length > 500) _logs.removeAt(0);
    debugPrint('[AppLog] $message');
  }

  static void clear() => _logs.clear();

  static Future<void> exportLogs() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('=== RUNTIME LOGS ===');
      for (var log in _logs) {
        buffer.writeln('[${log.time}] ${log.message}');
        if (log.error != null) buffer.writeln('Error: ${log.error}');
      }
      buffer.writeln('\n=== PERSISTENT CRASH LOGS ===\n');
      buffer.writeln(await CrashHandler.readLogs());
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/logs.txt');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], subject: 'Reader Logs');
    } catch (e) { debugPrint('導出日誌失敗: $e'); }
  }
}

class AppLogEntry {
  final DateTime time;
  final String message;
  final Object? error;
  AppLogEntry({required this.time, required this.message, this.error});
}

class AppLogPage extends StatefulWidget {
  const AppLogPage({super.key});
  @override
  State<AppLogPage> createState() => _AppLogPageState();
}

class _AppLogPageState extends State<AppLogPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AppLogEntry> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    _filteredLogs = AppLog.logs.toList().reversed.toList();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _filterLogs(String query) {
    setState(() {
      if (query.isEmpty) { _filteredLogs = AppLog.logs.toList().reversed.toList(); }
      else {
        _filteredLogs = AppLog.logs.where((log) => log.message.toLowerCase().contains(query.toLowerCase()) || (log.error?.toString().toLowerCase().contains(query.toLowerCase()) ?? false)).toList().reversed.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('應用程式日誌'),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => AppLog.exportLogs()),
          IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: () { AppLog.clear(); setState(() => _filteredLogs = []); }),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: '搜尋日誌內容...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), filled: true),
              onChanged: _filterLogs,
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(child: Text('目前沒有日誌記錄'))
                : ListView.separated(
                    itemCount: _filteredLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return ListTile(
                        dense: true,
                        title: Text(log.message, style: TextStyle(fontSize: 13, color: log.error != null ? Colors.red : null)),
                        subtitle: Text(log.time.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CrashLogPage extends StatefulWidget {
  const CrashLogPage({super.key});
  @override
  State<CrashLogPage> createState() => _CrashLogPageState();
}

class _CrashLogPageState extends State<CrashLogPage> {
  String _logs = "載入中...";

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final l = await CrashHandler.readLogs();
    if (mounted) setState(() => _logs = l);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('崩潰日誌 (持久化)'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () => Share.share(_logs)),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: () async { await CrashHandler.clearLogs(); _load(); }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(_logs, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      ),
    );
  }
}
