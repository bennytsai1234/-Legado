import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/local_book/txt_parser.dart';
import 'package:fast_gbk/fast_gbk.dart';

void main() {
  group('TxtParser Tests', () {
    late File utf8File;
    late File gbkFile;
    late File noChapterFile;

    setUp(() async {
      final tempDir = Directory.systemTemp;
      
      // UTF-8 Test File
      utf8File = File('${tempDir.path}/test_utf8.txt');
      await utf8File.writeAsString('''
前言內容
第一章 第一章標題
這是第一章的正文內容。
第二章 第二章標題
這是第二章的正文內容。
      ''', encoding: utf8);

      // GBK Test File
      gbkFile = File('${tempDir.path}/test_gbk.txt');
      final gbkBytes = gbk.encode('''
第一章 GBK標題
GBK正文測試
      ''');
      await gbkFile.writeAsBytes(gbkBytes);

      // No Chapter Test File
      noChapterFile = File('${tempDir.path}/test_no_chapter.txt');
      await noChapterFile.writeAsString('這是一本沒有任何章節標題的短篇小說。');
    });

    tearDown(() async {
      if (await utf8File.exists()) await utf8File.delete();
      if (await gbkFile.exists()) await gbkFile.delete();
      if (await noChapterFile.exists()) await noChapterFile.delete();
    });

    test('UTF-8 parsing and chapter splitting', () async {
      final parser = TxtParser(utf8File);
      await parser.load();
      
      expect(parser.charset, 'UTF-8');
      expect(parser.fullContent.isNotEmpty, true);

      final chapters = parser.splitChapters();
      expect(chapters.isNotEmpty, true); // 至少能切分出前言和正文
      
      // 驗證是否包含第一章
      final hasChapter1 = chapters.any((c) => c['title']!.contains('第一章'));
      expect(hasChapter1, true);

      // 驗證是否包含第二章
      final hasChapter2 = chapters.any((c) => c['title']!.contains('第二章'));
      expect(hasChapter2, true);
    });

    test('GBK parsing', () async {
      final parser = TxtParser(gbkFile);
      await parser.load();
      
      expect(parser.charset, 'GBK');
      final chapters = parser.splitChapters();
      
      expect(chapters.length, 1);
      expect(chapters[0]['title']!.contains('第一章'), true);
      expect(chapters[0]['content']!.contains('GBK正文測試'), true);
    });

    test('No chapter splitting', () async {
      final parser = TxtParser(noChapterFile);
      await parser.load();
      
      final chapters = parser.splitChapters();
      expect(chapters.length, 1);
      expect(chapters[0]['title'], '正文');
      expect(chapters[0]['content'], '這是一本沒有任何章節標題的短篇小說。');
    });
  });
}
