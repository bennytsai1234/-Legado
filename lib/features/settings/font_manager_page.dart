import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  List<String> _customFonts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomFonts();
  }

  Future<void> _loadCustomFonts() async {
    setState(() => _isLoading = true);
    try {
      final dir = await _getFontDir();
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().toList();
        final List<String> loadedFonts = [];
        
        for (var file in files) {
          final ext = p.extension(file.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            final name = p.basenameWithoutExtension(file.path);
            try {
              final fontData = await file.readAsBytes();
              final fontLoader = FontLoader(name);
              fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
              await fontLoader.load();
              loadedFonts.add(name);
            } catch (e) {
              debugPrint("Failed to load font $name: $e");
            }
          }
        }
        setState(() {
          _customFonts = loadedFonts;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Directory> _getFontDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontDir = Directory('${appDir.path}/fonts');
    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }
    return fontDir;
  }

  Future<void> _importFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = p.basenameWithoutExtension(path);
      
      try {
        // Copy to app dir
        final fontDir = await _getFontDir();
        final ext = p.extension(path);
        final newPath = '${fontDir.path}/$name$ext';
        await File(path).copy(newPath);

        // 動態加載字體
        final fontData = await File(newPath).readAsBytes();
        final fontLoader = FontLoader(name);
        fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
        await fontLoader.load();

        if (mounted) {
          setState(() {
            if (!_customFonts.contains(name)) _customFonts.add(name);
          });
          context.read<ReaderProvider>().setFontFamily(name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已加載並套用字體: $name')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('匯入字體失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFont(String name) async {
    final fontDir = await _getFontDir();
    final files = fontDir.listSync().whereType<File>();
    for (var file in files) {
      if (p.basenameWithoutExtension(file.path) == name) {
        await file.delete();
        setState(() {
          _customFonts.remove(name);
        });
        
        if (mounted) {
          final provider = context.read<ReaderProvider>();
          if (provider.fontFamily == name) {
            provider.setFontFamily(null); // Reset to default
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已刪除字體: $name')),
          );
        }
        break;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                if (_customFonts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('無自訂字體，請點擊上方按鈕匯入。', style: TextStyle(color: Colors.grey)),
                  ),
                ..._customFonts.map((font) => RadioListTile<String?>(
                      title: Text(font, style: TextStyle(fontFamily: font)),
                      value: font,
                      groupValue: currentFont,
                      onChanged: (val) {
                        context.read<ReaderProvider>().setFontFamily(val);
                      },
                      secondary: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFont(font),
                      ),
                    )),
              ],
            ),
    );
  }
}
