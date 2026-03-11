import 'dart:convert';
import 'dart:io';
import 'lib/core/models/book_source.dart';

void main() async {
  try {
    final req = await HttpClient().getUrl(Uri.parse('https://shuyuan.nyasama.net/shuyuan/ee8f2d3034c416874fbe233a536088e1.json'));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    final data = jsonDecode(text);
    
    int count = 0;
    for (var item in data) {
      count++;
      try {
        BookSource.fromJson(item as Map<String, dynamic>);
      } catch (e, st) {
        print('Error at index $count, name: ${item["bookSourceName"]}');
        print('Error: $e');
        print('Stack: $st');
        return;
      }
    }
    print("All $count parsed successfully!");
  } catch (e) {
    print("Request failed: $e");
  }
}
