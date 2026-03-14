import 'package:flutter/material.dart';

class SourceEditContent extends StatelessWidget {
  final Map<String, TextEditingController> controllers;

  const SourceEditContent({super.key, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildField(controllers['ruleContentContent']!, '正文內容規則', 'JSONPath 或 XPath'),
        _buildField(controllers['ruleContentNextPage']!, '正文分頁規則', ''),
        _buildField(controllers['ruleContentReplace']!, '內容取代規則', '例如: Regex@@Replacement'),
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
