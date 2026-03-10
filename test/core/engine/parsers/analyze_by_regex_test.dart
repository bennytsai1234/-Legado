import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_regex.dart';

void main() {
  group('AnalyzeByRegex Tests', () {
    const content = 'Author: Nigel Rees, Book: Sayings of the Century, Price: 8.95; Author: Evelyn Waugh, Book: Sword of Honour, Price: 12.99';

    test('Single regex extraction', () {
      final elements = AnalyzeByRegex.getElements(content, [r'Author: ([^,]+)']);
      expect(elements.length, 2);
      expect(elements[0][1], 'Nigel Rees');
      expect(elements[1][1], 'Evelyn Waugh');
    });

    test('Chained regex extraction', () {
      // First extract segments, then extract author from each segment
      final elements = AnalyzeByRegex.getElements(content, [r'Author: [^;]+', r'Author: ([^,]+)']);
      expect(elements.length, 2);
      expect(elements[0][1], 'Nigel Rees');
      expect(elements[1][1], 'Evelyn Waugh');
    });

    test('getString merges results', () {
      final result = AnalyzeByRegex.getString(content, [r'Author: ([^,]+)']);
      expect(result, 'Author: Nigel Rees\nAuthor: Evelyn Waugh');
    });
  });
}
