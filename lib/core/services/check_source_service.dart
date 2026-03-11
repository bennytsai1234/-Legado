import 'dart:async';
import '../models/book_source.dart';
import 'book_source_service.dart';

enum CheckResult { success, timeout, error, ruleError }

class CheckSourceService {
  final BookSourceService _service = BookSourceService();

  Future<CheckSourceResult> checkSource(BookSource source) async {
    final stopwatch = Stopwatch()..start();
    try {
      // 測試搜尋功能 (通常是檢驗書源最快的方式)
      final results = await _service.searchBooks(
        source,
        "我的",
      ).timeout(const Duration(seconds: 15));

      stopwatch.stop();
      if (results.isNotEmpty) {
        return CheckSourceResult(
          result: CheckResult.success,
          milliseconds: stopwatch.elapsedMilliseconds,
        );
      } else {
        return CheckSourceResult(
          result: CheckResult.ruleError,
          milliseconds: stopwatch.elapsedMilliseconds,
          message: "搜尋結果為空，請檢查搜尋規則",
        );
      }
    } on TimeoutException {
      return CheckSourceResult(
        result: CheckResult.timeout,
        milliseconds: stopwatch.elapsedMilliseconds,
        message: "連線超時",
      );
    } catch (e) {
      stopwatch.stop();
      return CheckSourceResult(
        result: CheckResult.error,
        milliseconds: stopwatch.elapsedMilliseconds,
        message: e.toString(),
      );
    }
  }
}

class CheckSourceResult {
  final CheckResult result;
  final int milliseconds;
  final String? message;

  CheckSourceResult({
    required this.result,
    required this.milliseconds,
    this.message,
  });

  String get summary {
    switch (result) {
      case CheckResult.success:
        return "成功 (${milliseconds}ms)";
      case CheckResult.timeout:
        return "超時";
      case CheckResult.ruleError:
        return "規則錯誤";
      case CheckResult.error:
        return "錯誤: $message";
    }
  }
}
