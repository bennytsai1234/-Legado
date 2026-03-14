import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'webdav_base.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_progress.dart';

/// WebDAVService 的進度同步與檔案傳輸邏輯擴展
mixin WebDAVSync on WebDAVBase {
  Future<void> uploadBookProgress(Book book) async {
    if (!await isConfigured()) return;
    try {
      final client = await getClient();
      await client.mkdir('/legado/progress');
      final progress = BookProgress(
        name: book.name,
        author: book.author,
        durChapterIndex: book.durChapterIndex,
        durChapterPos: book.durChapterPos,
        durChapterTime: DateTime.now().millisecondsSinceEpoch,
      );
      final data = jsonEncode(progress.toJson());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${book.name.hashCode}.json');
      await file.writeAsString(data);
      await client.writeFromFile(file.path, '/legado/progress/${book.name.hashCode}.json');
    } catch (e) {
      debugPrint('Upload progress failed: $e');
    }
  }

  Future<void> syncAllBookProgress() async {
    if (!await isConfigured()) return;
    debugPrint('Syncing all book progress...');
    // Implementation placeholder for bulk progress sync
  }

  Future<void> uploadLocalBook(Book book, File file) async {
    try {
      final client = await getClient();
      await client.mkdir('/legado/books');
      final fileName = p.basename(file.path);
      await client.writeFromFile(file.path, '/legado/books/$fileName');
    } catch (e) {
      debugPrint('Upload book failed: $e');
    }
  }

  Future<File?> downloadLocalBook(Book book) async {
    try {
      final client = await getClient();
      final fileName = p.basename(book.bookUrl);
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$fileName');
      await client.read2File('/legado/books/$fileName', localFile.path);
      return localFile;
    } catch (e) {
      debugPrint('Download book failed: $e');
      return null;
    }
  }

  Future<void> uploadFile(String localPath, String remoteName) async {
    try {
      final client = await getClient();
      await client.mkdir('/legado/export');
      await client.writeFromFile(localPath, '/legado/export/$remoteName');
    } catch (e) {
      debugPrint('Upload file failed: $e');
    }
  }
}
