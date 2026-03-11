import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../reader/reader_provider.dart';

class FontManagerPage extends StatefulWidget {
  const FontManagerPage({super.key});

  @override
  State<FontManagerPage> createState() => _FontManagerPageState();
}

class _FontManagerPageState extends State<FontManagerPage> {
  final List<String> _systemFonts = [
    'System Default',
    'PingFang SC',
    'Heiti SC',
    'Kaiti SC',
    'Songti SC',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomFonts();
  }

  Future<void> _loadCustomFonts() async {
    // 這裡通常會從一個本地配置檔案或資料庫讀取已匯入的字體路徑
    // 為簡化，我們先實作匯入功能
  }

  Future<void> _importFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = p.basenameWithoutExtension(path);
      
      // 動態加載字體
      final fontData = await File(path).readAsBytes();
      final fontLoader = FontLoader(name);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();

      if (mounted) {
        context.read<ReaderProvider>().setFontFamily(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加載並套用字體: $name')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFont = context.watch<ReaderProvider>().fontFamily;

    return Scaffold(
      appBar: AppBar(
        title: const Text('字體管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _importFont),
        ],
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('系統字體', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._systemFonts.map((font) => RadioListTile<String?>(
                title: Text(font, style: TextStyle(fontFamily: font == 'System Default' ? null : font)),
                value: font == 'System Default' ? null : font,
                groupValue: currentFont,
                onChanged: (val) {
                  context.read<ReaderProvider>().setFontFamily(val);
                },
              )),
          const Divider(),
          const ListTile(
            title: Text('自訂字體', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('點擊右上角 + 匯入字體檔案 (TTF/OTF)'),
          ),
          // 這裡可以顯示已匯入的自訂字體清單
        ],
      ),
    );
  }
}
