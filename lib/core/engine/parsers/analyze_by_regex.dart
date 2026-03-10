/// AnalyzeByRegex - 正則表達式解析器
/// 對應 Android: model/analyzeRule/AnalyzeByRegex.kt (2KB)
///
/// 支援 Legado 的 ##pattern## 格式
class AnalyzeByRegex {
  /// 獲取單個匹配項及其分組
  static List<String>? getElement(String res, List<String> regs, {int index = 0}) {
    if (index >= regs.length) return null;

    final regExp = RegExp(regs[index], multiLine: true, dotAll: true);
    final match = regExp.firstMatch(res);
    if (match == null) return null;

    if (index + 1 == regs.length) {
      final info = <String>[];
      for (int i = 0; i <= match.groupCount; i++) {
        info.add(match.group(i) ?? "");
      }
      return info;
    } else {
      final result = StringBuffer();
      final allMatches = regExp.allMatches(res);
      for (final m in allMatches) {
        result.write(m.group(0) ?? "");
      }
      return getElement(result.toString(), regs, index: index + 1);
    }
  }

  /// 獲取所有匹配項列表及其分組
  static List<List<String>> getElements(String res, List<String> regs, {int index = 0}) {
    if (index >= regs.length) return [];

    final regExp = RegExp(regs[index], multiLine: true, dotAll: true);
    final allMatches = regExp.allMatches(res);
    if (allMatches.isEmpty) return [];

    if (index + 1 == regs.length) {
      final books = <List<String>>[];
      for (final match in allMatches) {
        final info = <String>[];
        for (int i = 0; i <= match.groupCount; i++) {
          info.add(match.group(i) ?? "");
        }
        books.add(info);
      }
      return books;
    } else {
      final result = StringBuffer();
      for (final match in allMatches) {
        result.write(match.group(0) ?? "");
      }
      return getElements(result.toString(), regs, index: index + 1);
    }
  }

  /// 獲取單個合併字串
  static String getString(String res, List<String> regs) {
    final elements = getElements(res, regs);
    if (elements.isEmpty) return "";
    return elements.map((e) => e[0]).join('\n');
  }
}
