import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_json_path.dart';

void main() {
  group('AnalyzeByJsonPath Tests', () {
    const jsonStr = '''
    {
      "store": {
        "book": [
          { "category": "reference", "author": "Nigel Rees", "title": "Sayings of the Century", "price": 8.95 },
          { "category": "fiction", "author": "Evelyn Waugh", "title": "Sword of Honour", "price": 12.99 },
          { "category": "fiction", "author": "Herman Melville", "title": "Moby Dick", "isbn": "0-553-21311-3", "price": 8.99 },
          { "category": "fiction", "author": "J. R. R. Tolkien", "title": "The Lord of the Rings", "isbn": "0-395-19395-8", "price": 22.99 }
        ],
        "bicycle": { "color": "red", "price": 19.95 }
      }
    }
    ''';

    test('Basic getString', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      expect(analyzer.getString(r'$.store.bicycle.color'), 'red');
    });

    test('getList books', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      final books = analyzer.getList(r'$.store.book[*]');
      expect(books.length, 4);
      expect(books[0]['author'], 'Nigel Rees');
    });

    test('getStringList authors', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      final authors = analyzer.getStringList(r'$.store.book[*].author');
      expect(authors.length, 4);
      expect(authors, contains('Nigel Rees'));
      expect(authors, contains('J. R. R. Tolkien'));
    });

    test('Logical && operator', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      final result = analyzer.getString(r'$.store.bicycle.color && $.store.bicycle.price');
      expect(result, 'red\n19.95');
    });

    test('Logical || operator', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      // first one exists
      expect(analyzer.getString(r'$.store.bicycle.color || $.store.bicycle.price'), 'red');
      // first one doesn't exist
      expect(analyzer.getString(r'$.store.bicycle.none || $.store.bicycle.price'), '19.95');
    });

    test(r'Nested rules {$.}', () {
      final analyzer = AnalyzeByJsonPath(jsonStr);
      // This is a bit contrived but tests the innerRule logic
      // In Legado, {$.rule} is often used to compose strings
      final result = analyzer.getString(r'Color: {$.store.bicycle.color}');
      expect(result, 'Color: red');
    });
  });
}
