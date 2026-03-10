import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_css.dart';

void main() {
  group('AnalyzeByCss Tests', () {
    const htmlStr = '''
    <html>
      <body>
        <div id="content">
          <ul class="bookList">
            <li class="item">
              <a href="book1.html" title="Book 1">Chapter 1</a>
              <span class="author">Author A</span>
            </li>
            <li class="item">
              <a href="book2.html" title="Book 2">Chapter 2</a>
              <span class="author">Author B</span>
            </li>
            <li class="item">
              <a href="book3.html" title="Book 3">Chapter 3</a>
              <span class="author">Author C</span>
            </li>
          </ul>
          <div class="footer">Footer Text</div>
        </div>
      </body>
    </html>
    ''';

    test('Standard CSS selector', () {
      final analyzer = AnalyzeByCss(htmlStr);
      final elements = analyzer.getElements('li.item');
      expect(elements.length, 3);
    });

    test('Legado CSS syntax tag.class@attr', () {
      final analyzer = AnalyzeByCss(htmlStr);
      final titles = analyzer.getStringList('li.item@tag.a@text');
      expect(titles, ['Chapter 1', 'Chapter 2', 'Chapter 3']);
      
      final hrefs = analyzer.getStringList('li.item@tag.a@href');
      expect(hrefs, ['book1.html', 'book2.html', 'book3.html']);
    });

    test('Legado CSS syntax with index', () {
      final analyzer = AnalyzeByCss(htmlStr);
      // First item's link - Use .0 for selection
      final firstTitle = analyzer.getString('li.item.0@tag.a@text');
      expect(firstTitle, 'Chapter 1');
      
      // Last item's link
      final lastTitle = analyzer.getString('li.item.-1@tag.a@text');
      expect(lastTitle, 'Chapter 3');
    });

    test('Legado CSS syntax with range index [start:end]', () {
      final analyzer = AnalyzeByCss(htmlStr);
      final titles = analyzer.getStringList('li.item[0:1]@tag.a@text');
      expect(titles, ['Chapter 1', 'Chapter 2']);
    });

    test('Special attributes: text, html, ownText', () {
      final analyzer = AnalyzeByCss(htmlStr);
      expect(analyzer.getString('.footer@text'), 'Footer Text');
      expect(analyzer.getString('.footer@html'), contains('<div class="footer">Footer Text</div>'));
    });

    test('Logical && operator', () {
      final analyzer = AnalyzeByCss(htmlStr);
      final result = analyzer.getString('.author.0@text && .author.1@text');
      expect(result, 'Author A\nAuthor B');
    });

    test('Logical || operator', () {
      final analyzer = AnalyzeByCss(htmlStr);
      expect(analyzer.getString('.none@text || .footer@text'), 'Footer Text');
    });

    test('@CSS prefix', () {
      final analyzer = AnalyzeByCss(htmlStr);
      // @CSS: is more like standard JSoup select
      final result = analyzer.getString('@CSS:.footer@text');
      expect(result, 'Footer Text');
    });
  });
}
