import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'local_book_provider.dart';

class SmartScanPage extends StatefulWidget {
  const SmartScanPage({super.key});

  @override
  State<SmartScanPage> createState() => _SmartScanPageState();
}

class _SmartScanPageState extends State<SmartScanPage> {
  bool _isScanning = false;
  List<File> _foundFiles = [];
  Set<String> _selectedPaths = {};

  Future<void> _scanDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return;

    setState(() {
      _isScanning = true;
      _foundFiles.clear();
      _selectedPaths.clear();
    });

    try {
      final dir = Directory(selectedDirectory);
      final List<File> files = [];
      
      // 遞迴掃描目錄
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.txt' || ext == '.epub') {
            files.add(entity);
          }
        }
      }

      setState(() {
        _foundFiles = files;
        _selectedPaths = files.map((e) => e.path).toSet(); // 預設全選
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('掃描出錯: $e')));
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _importSelected() async {
    if (_selectedPaths.isEmpty) return;
    
    final provider = context.read<LocalBookProvider>();
    final filesToImport = _foundFiles.where((f) => _selectedPaths.contains(f.path)).toList();
    
    // 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int successCount = 0;
    for (var file in filesToImport) {
      try {
        await provider.importFile(file.path);
        successCount++;
      } catch (e) {
        debugPrint('匯入失敗 ${file.path}: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context); // 關閉 loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $successCount 本書籍')));
      Navigator.pop(context); // 返回上一頁
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智慧掃描'),
        actions: [
          if (_foundFiles.isNotEmpty)
            TextButton(
              onPressed: _importSelected,
              child: Text('匯入 (${_selectedPaths.length})', style: const TextStyle(color: Colors.white)),
            )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('選擇目錄並掃描 (支援 TXT, EPUB)'),
              onPressed: _isScanning ? null : _scanDirectory,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), padding: const EdgeInsets.all(16)),
            ),
          ),
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在深度掃描目錄...'),
                ],
              ),
            ),
          if (!_isScanning && _foundFiles.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _foundFiles.length,
                itemBuilder: (context, index) {
                  final file = _foundFiles[index];
                  final isSelected = _selectedPaths.contains(file.path);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(p.basename(file.path)),
                    subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPaths.add(file.path);
                        } else {
                          _selectedPaths.remove(file.path);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          if (!_isScanning && _foundFiles.isEmpty)
            const Expanded(
              child: Center(
                child: Text('請選擇包含電子書的資料夾'),
              ),
            ),
        ],
      ),
    );
  }
}
