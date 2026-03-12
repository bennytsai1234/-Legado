import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../source_manager/source_manager_provider.dart';
import '../rss/rss_source_provider.dart';
import '../replace_rule/replace_rule_provider.dart';
import '../bookshelf/bookshelf_provider.dart';

class IntentHandlerService {
  static final IntentHandlerService _instance = IntentHandlerService._internal();
  factory IntentHandlerService() => _instance;
  IntentHandlerService._internal();

  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  StreamSubscription? _sharedMediaSubscription;

  void init(BuildContext context) {
    _appLinks = AppLinks();

    // 1. 處理 Deep Link (legado://)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(context, uri);
    });

    // 2. 處理外部分享 (File/Text)
    _sharedMediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _handleSharedMedia(context, value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // 檢查啟動時的 Intent
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(context, value);
      }
    });
    
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(context, uri);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
    _sharedMediaSubscription?.cancel();
  }

  void _handleUri(BuildContext context, Uri uri) {
    debugPrint("處理 Deep Link: $uri");
    // 深度還原：處理更多 legado:// 協議路徑 (對標 Android OnLineImportActivity)
    if (uri.scheme == 'legado') {
      if (uri.host == 'import') {
        final type = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'auto';
        final src = uri.queryParameters['src'];
        if (src != null) {
          _showImportDialog(context, type, src);
        }
      } else if (uri.host == 'addBook') {
        final url = uri.queryParameters['url'];
        if (url != null) {
          _showImportDialog(context, 'book', url);
        }
      }
    }
  }

  void _handleSharedMedia(BuildContext context, List<SharedMediaFile> media) async {
    for (var file in media) {
      debugPrint("收到分享檔案: ${file.path}");
      final ext = p.extension(file.path).toLowerCase();
      if (ext == '.json') {
        await _handleSharedFile(context, file.path);
      } else if (ext == '.txt' || ext == '.epub') {
        await _handleSharedBook(context, file.path);
      }
    }
  }

  Future<void> _handleSharedBook(BuildContext context, String path) async {
    try {
      // 1. 確定預設存放目錄 (對應 Android defaultBookTreeUri)
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDocDir.path, 'LegadoBooks'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 2. 複製檔案到該目錄
      final fileName = p.basename(path);
      final targetPath = p.join(targetDir.path, fileName);
      final sourceFile = File(path);
      
      final targetFile = File(targetPath);
      if (!await targetFile.exists()) {
        await sourceFile.copy(targetPath);
      }

      // 3. 呼叫匯入邏輯
      if (context.mounted) {
        context.read<BookshelfProvider>().importLocalBookPath(targetPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已將書籍複製並匯入: $fileName')),
        );
      }
    } catch (e) {
      debugPrint("搬移並匯入書籍失敗: $e");
    }
  }

  Future<void> _handleSharedFile(BuildContext context, String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      String type = 'auto';
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          if (first.containsKey('bookSourceUrl')) {
            type = 'bookSource';
          } else if (first.containsKey('sourceUrl')) {
            type = 'rssSource';
          } else if (first.containsKey('pattern')) {
            type = 'replaceRule';
          } else if (first.containsKey('loginUrl')) {
            type = 'httpTts';
          } else if (first.containsKey('themeName')) {
            type = 'theme';
          } else if (first.containsKey('chapterName')) {
            type = 'txtRule';
          }
        }
      } else if (data is Map) {
        if (data.containsKey('bookSourceUrl')) {
          type = 'bookSource';
        } else if (data.containsKey('sourceUrl')) {
          type = 'rssSource';
        } else if (data.containsKey('pattern')) {
          type = 'replaceRule';
        } else if (data.containsKey('loginUrl')) {
          type = 'httpTts';
        } else if (data.containsKey('themeName')) {
          type = 'theme';
        } else if (data.containsKey('chapterName')) {
          type = 'txtRule';
        }
      }

      if (context.mounted) {
        _showImportDialog(context, type, path, isFile: true, jsonData: content);
      }
    } catch (e) {
      debugPrint("解析分享檔案失敗: $e");
      if (context.mounted) {
        _showForceImportDialog(context, path);
      }
    }
  }

  void _showForceImportDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('格式不支援'),
        content: const Text('無法辨識此 JSON 內容，是否嘗試將其作為書籍檔案導入？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSharedBook(context, path);
            },
            child: const Text('嘗試導入書籍'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, String type, String src, {bool isFile = false, String? jsonData}) {
    // 根據內容判斷或使用者選擇匯入類型
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('外部匯入'),
        content: Text('偵測到外部內容：\n${isFile ? src.split('/').last : src}\n\n辨識類型：$type\n請選擇操作：'),
        actions: [
          _buildImportButton(ctx, '書源', () {
            if (isFile && jsonData != null) {
              context.read<SourceManagerProvider>().importFromJson(jsonData);
            } else {
              context.read<SourceManagerProvider>().importFromUrl(src);
            }
          }),
          _buildImportButton(ctx, 'RSS', () {
            if (isFile && jsonData != null) {
              context.read<RssSourceProvider>().importFromJson(jsonData);
            } else {
              context.read<RssSourceProvider>().importFromUrl(src);
            }
          }),
          if (type == 'book' || type == 'auto')
            _buildImportButton(ctx, '書籍', () {
              context.read<BookshelfProvider>().importBookshelfFromUrl(src);
            }),
          if (type == 'replaceRule' || type == 'auto')
            _buildImportButton(ctx, '替換規則', () {
              if (isFile && jsonData != null) context.read<ReplaceRuleProvider>().importFromText(jsonData);
            }),
          if (type == 'httpTts' || type == 'auto')
            _buildImportButton(ctx, 'HTTP TTS', () {
              // TODO: 實作 TtsProvider 匯入
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TTS 匯入功能開發中')));
            }),
          if (type == 'theme' || type == 'auto')
            _buildImportButton(ctx, '主題', () {
              // TODO: 實作 ThemeProvider 匯入
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('主題匯入功能開發中')));
            }),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton(BuildContext context, String label, VoidCallback action) {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
        action();
      },
      child: Text('匯入為 $label'),
    );
  }
}
