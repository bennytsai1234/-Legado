import 'dart:collection';
import 'package:flutter/foundation.dart';

/// AppLog - 全域日誌記錄器 (對標 Android constant/AppLog.kt)
class AppLog {
  AppLog._();

  static final _logs = Queue<LogEntry>();
  static const int _maxLogs = 100;

  static List<LogEntry> get logs => _logs.toList();

  /// 記錄日誌 (AI_PORT: derived from AppLog.kt)
  static void put(String message, {Object? error, StackTrace? stackTrace, bool toast = false}) {
    if (_logs.length >= _maxLogs) {
      _logs.removeLast();
    }
    
    final entry = LogEntry(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    _logs.addFirst(entry);

    if (kDebugMode) {
      print("[AppLog] $message");
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }

    // TODO: Implement toast injection if needed, 
    // technically requires a global context or a specific service.
  }

  static void clear() {
    _logs.clear();
  }
}

class LogEntry {
  final int timestamp;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.message,
    this.error,
    this.stackTrace,
  });
}
