import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'dict_provider.dart';

class DictDialog extends StatefulWidget {
  final String word;
  const DictDialog({super.key, required this.word});

  @override
  State<DictDialog> createState() => _DictDialogState();

  static void show(BuildContext context, String word) {
    showDialog(
      context: context,
      builder: (context) => DictDialog(word: word),
    );
  }
}

class _DictDialogState extends State<DictDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictProvider>().search(widget.word);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: Text('查詞: ${widget.word}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: HtmlWidget(
                      provider.result,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }
}
