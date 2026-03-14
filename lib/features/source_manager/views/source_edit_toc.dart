import 'package:flutter/material.dart';

class SourceEditToc extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const SourceEditToc({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildField(controllers['ruleTocChapterList']!, '目錄列表規則', 'JSONPath 或 XPath'),
        _buildField(controllers['ruleTocChapterName']!, '章節名稱規則', ''),
        _buildField(controllers['ruleTocChapterUrl']!, '章節網址規則', ''),
        _buildField(controllers['ruleTocNextPage']!, '下一頁規則', '目錄分頁時使用'),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
