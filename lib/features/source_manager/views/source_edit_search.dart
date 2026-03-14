import 'package:flutter/material.dart';

class SourceEditSearch extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const SourceEditSearch({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildField(controllers['searchUrl']!, '搜尋網址', '使用 {{key}} 作為關鍵字佔位符', maxLines: 2),
        _buildField(controllers['ruleSearchBookList']!, '列表規則', 'JSONPath 或 XPath'),
        _buildField(controllers['ruleSearchName']!, '書名規則', ''),
        _buildField(controllers['ruleSearchAuthor']!, '作者規則', ''),
        _buildField(controllers['ruleSearchKind']!, '分類規則', ''),
        _buildField(controllers['ruleSearchWordCount']!, '字數規則', ''),
        _buildField(controllers['ruleSearchLastChapter']!, '最新章節', ''),
        _buildField(controllers['ruleSearchCoverUrl']!, '封面規則', ''),
        _buildField(controllers['ruleSearchNoteUrl']!, '詳情網址規則', ''),
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
