import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_xpath.dart';

void main() {
  group('AnalyzeByXPath Tests', () {
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

    test('Standard XPath query', () {
      final analyzer = AnalyzeByXPath(htmlStr);
      final elements = analyzer.getElements('//li[@class="item"]');
      expect(elements.length, 3);
    });

    test('XPath attribute extraction', () {
      final analyzer = AnalyzeByXPath(htmlStr);
      final hrefs = analyzer.getStringList('//li/a/@href');
      expect(hrefs, ['book1.html', 'book2.html', 'book3.html']);
    });

    test('XPath text extraction', () {
      final analyzer = AnalyzeByXPath(htmlStr);
      final titles = analyzer.getStringList('//li/a/text()');
      expect(titles, ['Chapter 1', 'Chapter 2', 'Chapter 3']);
    });

    test('Logical && operator', () {
      final analyzer = AnalyzeByXPath(htmlStr);
      final result = analyzer.getString('//li[1]/a/text() && //li[2]/a/text()');
      expect(result, 'Chapter 1\nChapter 2');
    });

    test('Logical || operator', () {
      final analyzer = AnalyzeByXPath(htmlStr);
      expect(analyzer.getString('//li[@class="none"]/text() || //div[@class="footer"]/text()'), 'Footer Text');
    });
  });
}
