import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CrashHandler {
  static Future<void> init() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _saveLog(details.exceptionAsString(), details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _saveLog(error.toString(), stack);
      return true;
    };
  }

  static Future<void> _saveLog(String error, StackTrace? stack) async {
    try {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/crash_log.txt');
      
      final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final buffer = StringBuffer();
      buffer.writeln('========================================');
      buffer.writeln('Crash Time: $now');
      buffer.writeln('Error: $error');
      if (stack != null) {
        buffer.writeln('StackTrace:');
        buffer.writeln(stack.toString());
      }
      buffer.writeln('========================================\n');

      await file.writeAsString(buffer.toString(), mode: FileMode.append, flush: true);
      debugPrint('Crash log saved to: ${file.path}');
    } catch (e) {
      debugPrint('Failed to save crash log: $e');
    }
  }

  static Future<String> getLogPath() async {
    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    return '${directory.path}/crash_log.txt';
  }

  static Future<String> readLogs() async {
    try {
      final file = File(await getLogPath());
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return "尚無日誌記錄";
  }

  static Future<void> clearLogs() async {
    try {
      final file = File(await getLogPath());
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
