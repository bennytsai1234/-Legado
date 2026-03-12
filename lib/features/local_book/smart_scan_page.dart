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
  String? _rootPath;
  String? _currentPath;
  List<FileSystemEntity> _displayItems = [];
  final Set<String> _selectedPaths = {};
  bool _isScanning = false;
  bool _isHierarchicalMode = false; // 是否為層級導航模式

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _rootPath = selectedDirectory;
        _currentPath = selectedDirectory;
        _isHierarchicalMode = true;
      });
      _loadCurrentDirectory();
    }
  }

  void _loadCurrentDirectory() {
    if (_currentPath == null) return;
    final dir = Directory(_currentPath!);
    try {
      final items = dir.listSync().where((item) {
        if (item is Directory) return !p.basename(item.path).startsWith('.');
        final ext = p.extension(item.path).toLowerCase();
        return ext == '.txt' || ext == '.epub';
      }).toList();
      
      // 排序：資料夾在前，書籍在後
      items.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      setState(() {
        _displayItems = items;
        _isScanning = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('讀取目錄失敗: $e')));
    }
  }

  Future<void> _fullScan() async {
    if (_rootPath == null) return;
    setState(() {
      _isScanning = true;
      _isHierarchicalMode = false;
      _displayItems = [];
    });

    final List<File> found = [];
    try {
      final dir = Directory(_rootPath!);
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.txt' || ext == '.epub') {
            found.add(entity);
          }
        }
      }
      setState(() {
        _displayItems = found;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('掃描出錯: $e')));
    }
  }

  void _navigateUp() {
    if (_currentPath == null || _currentPath == _rootPath) return;
    setState(() {
      _currentPath = p.dirname(_currentPath!);
    });
    _loadCurrentDirectory();
  }

  void _navigateDown(Directory dir) {
    setState(() {
      _currentPath = dir.path;
    });
    _loadCurrentDirectory();
  }

  Future<void> _importSelected() async {
    if (_selectedPaths.isEmpty) return;
    final provider = context.read<LocalBookProvider>();
    
    int count = 0;
    for (var path in _selectedPaths) {
      final success = await provider.importFile(path);
      if (success) count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $count 本書籍')));
      Navigator.pop(context);
    }
  }

  void _showJsSettingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(text: prefs.getString('book_import_file_name_js') ?? '');
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('檔名解析 JS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('使用變數 src (檔名)，賦值給 name 與 author。', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'const p = src.split("_");\\nname = p[0]; author = p[1];',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('book_import_file_name_js', controller.text);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('導入本地書籍'),
        actions: [
          IconButton(
            icon: const Icon(Icons.javascript),
            tooltip: '檔名解析設定',
            onPressed: _showJsSettingDialog,
          ),
          if (_displayItems.isNotEmpty)
            TextButton(
              onPressed: _importSelected,
              child: Text('匯入(${_selectedPaths.length})', style: const TextStyle(color: Colors.blue)),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTopActions(),
          if (_isHierarchicalMode) _buildBreadcrumbs(),
          Expanded(
            child: _isScanning
                ? const Center(child: CircularProgressIndicator())
                : _displayItems.isEmpty
                    ? _buildEmptyState()
                    : _buildFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(_rootPath == null ? '選取路徑' : '更換路徑'),
              onPressed: _selectFolder,
            ),
          ),
          if (_rootPath != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isHierarchicalMode ? Icons.manage_search : Icons.account_tree_outlined),
              tooltip: _isHierarchicalMode ? '切換至全量掃描' : '切換至層級導航',
              onPressed: () {
                if (_isHierarchicalMode) {
                  _fullScan();
                } else {
                  setState(() {
                    _currentPath = _rootPath;
                    _isHierarchicalMode = true;
                  });
                  _loadCurrentDirectory();
                }
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    if (_currentPath == null) return const SizedBox();
    final relative = p.relative(_currentPath!, from: p.dirname(_rootPath!));
    final parts = p.split(relative);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        itemBuilder: (ctx, index) {
          final isLast = index == parts.length - 1;
          return GestureDetector(
            onTap: isLast ? null : () {
              // 深度還原：麵包屑導航點擊跳轉
              String target = _rootPath!;
              // 邏輯需精確計算 target，此處簡化處理回退上級
              _navigateUp(); 
            },
            child: Text(
              parts[index],
              style: TextStyle(
                color: isLast ? Colors.black : Colors.blue,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('請先選取包含電子書的資料夾'),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      itemCount: _displayItems.length,
      itemBuilder: (context, index) {
        final item = _displayItems[index];
        final isDir = item is Directory;
        final name = p.basename(item.path);
        final isSelected = _selectedPaths.contains(item.path);

        return ListTile(
          leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? Colors.orange : Colors.blue),
          title: Text(name),
          subtitle: isDir ? null : Text(_getFileSize(item as File)),
          trailing: isDir 
            ? const Icon(Icons.chevron_right)
            : Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedPaths.add(item.path);
                    } else {
                      _selectedPaths.remove(item.path);
                    }
                  });
                },
              ),
          onTap: () {
            if (isDir) {
              _navigateDown(item as Directory);
            } else {
              setState(() {
                if (isSelected) {
                  _selectedPaths.remove(item.path);
                } else {
                  _selectedPaths.add(item.path);
                }
              });
            }
          },
        );
      },
    );
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
