import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ArchiveUtils - 壓縮檔工具 (對標 Android utils/ArchiveUtils.kt)
/// 目前主要支援 ZIP 格式 (使用 archive 插件)
class ArchiveUtils {
  ArchiveUtils._();

  static const String tempFolderName = "ArchiveTemp";

  /// 獲取暫存目錄
  static Future<String> getTempPath() async {
    final cache = await getTemporaryDirectory();
    final dir = Directory(p.join(cache.path, tempFolderName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  /// 解壓縮檔案 (目前僅支援 ZIP)
  static Future<List<File>> deCompress(
    File archiveFile, {
    String? destPath,
    bool Function(String)? filter,
  }) async {
    final path = destPath ?? await getTempPath();
    final bytes = await archiveFile.readAsBytes();
    
    // 目前僅支援 ZIP，7z/RAR 需額外插件或原生支援
    if (!archiveFile.path.toLowerCase().endsWith('.zip')) {
      throw Exception("Currently only ZIP is supported. Suffix: ${p.extension(archiveFile.path)}");
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    final List<File> files = [];

    for (final file in archive) {
      if (file.isFile) {
        if (filter != null && !filter(file.name)) continue;
        
        final data = file.content as List<int>;
        final outFile = File(p.join(path, file.name));
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
        files.add(outFile);
      } else {
        await Directory(p.join(path, file.name)).create(recursive: true);
      }
    }
    return files;
  }

  /// 獲取壓縮檔內的文件名列表
  static Future<List<String>> getArchiveFilesName(
    File archiveFile, {
    bool Function(String)? filter,
  }) async {
    final bytes = await archiveFile.readAsBytes();
    if (!archiveFile.path.toLowerCase().endsWith('.zip')) {
      return [];
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    final List<String> names = [];
    for (final file in archive) {
      if (file.isFile) {
        if (filter == null || filter(file.name)) {
          names.add(file.name);
        }
      }
    }
    return names;
  }

  /// 判斷是否為支援的壓縮檔
  static bool isArchive(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.zip') || lower.endsWith('.7z') || lower.endsWith('.rar');
  }
}
