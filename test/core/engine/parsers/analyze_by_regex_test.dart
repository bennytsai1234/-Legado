import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_regex.dart';

void main() {
  group('AnalyzeByRegex Tests', () {
    const content = 'Author: Nigel Rees, Book: Sayings of the Century, Price: 8.95; Author: Evelyn Waugh, Book: Sword of Honour, Price: 12.99';

    test('1. Single regex extraction', () {
      final elements = AnalyzeByRegex.getElements(content, [r'Author: ([^,]+)']);
      expect(elements.length, 2);
      expect(elements[0][1], 'Nigel Rees');
      expect(elements[1][1], 'Evelyn Waugh');
    });

    test('2. Chained regex extraction', () {
      // First extract segments, then extract author from each segment
      final elements = AnalyzeByRegex.getElements(content, [r'Author: [^;]+', r'Author: ([^,]+)']);
      expect(elements.length, 2);
      expect(elements[0][1], 'Nigel Rees');
      expect(elements[1][1], 'Evelyn Waugh');
    });

    test('3. getString merges results', () {
      final result = AnalyzeByRegex.getString(content, [r'Author: ([^,]+)']);
      expect(result, 'Author: Nigel Rees\nAuthor: Evelyn Waugh');
    });

    test('4. Grouping extraction (multiple groups)', () {
      final elements = AnalyzeByRegex.getElements(content, [r'Author: ([^,]+), Book: ([^,]+)']);
      expect(elements.length, 2);
      expect(elements[0][1], 'Nigel Rees');
      expect(elements[0][2], 'Sayings of the Century');
    });

    test('5. DotAll and MultiLine support', () {
      const multiLineContent = 'Line 1\nLine 2\nLine 3';
      final result = AnalyzeByRegex.getString(multiLineContent, [r'Line.*']);
      expect(result, 'Line 1\nLine 2\nLine 3');
    });

    test('6. No match returns empty', () {
      final elements = AnalyzeByRegex.getElements(content, [r'NonExistent']);
      expect(elements, isEmpty);
      
      final result = AnalyzeByRegex.getString(content, [r'NonExistent']);
      expect(result, isEmpty);
    });
  });
}
