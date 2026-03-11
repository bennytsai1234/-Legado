import 'package:flutter/material.dart';
import '../../core/database/dao/http_tts_dao.dart';
import '../../core/models/http_tts.dart';

class HttpTtsManagerPage extends StatefulWidget {
  const HttpTtsManagerPage({super.key});

  @override
  State<HttpTtsManagerPage> createState() => _HttpTtsManagerPageState();
}

class _HttpTtsManagerPageState extends State<HttpTtsManagerPage> {
  final HttpTtsDao _dao = HttpTtsDao();
  List<HttpTTS> _engines = [];

  @override
  void initState() {
    super.initState();
    _loadEngines();
  }

  Future<void> _loadEngines() async {
    final list = await _dao.getAll();
    setState(() {
      _engines = list;
    });
  }

  void _addEngine() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 HTTP TTS 引擎'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '引擎名稱'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL (包含 {{speakText}})'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final engine = HttpTTS(
                  id: 0, // Auto-increment
                  name: nameController.text,
                  url: urlController.text,
                );
                await _dao.insertOrUpdate(engine);
                Navigator.pop(context);
                _loadEngines();
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP TTS 引擎管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addEngine),
        ],
      ),
      body: _engines.isEmpty
          ? const Center(child: Text('尚未新增任何引擎'))
          : ListView.builder(
              itemCount: _engines.length,
              itemBuilder: (context, index) {
                final engine = _engines[index];
                return ListTile(
                  title: Text(engine.name),
                  subtitle: Text(engine.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Implement edit/delete
                    },
                  ),
                );
              },
            ),
    );
  }
}
