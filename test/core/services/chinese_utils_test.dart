import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/services/chinese_utils.dart';

void main() {
  group('ChineseUtils Tests', () {
    test('Simplified to Traditional conversion', () {
      expect(ChineseUtils.s2t('万与丑专业'), '萬與醜專業');
      expect(ChineseUtils.s2t('书买乱争'), '書買亂爭');
    });

    test('Traditional to Simplified conversion', () {
      expect(ChineseUtils.t2s('萬與醜專業'), '万与丑专业');
      expect(ChineseUtils.t2s('書買亂爭'), '书买乱争');
    });

    test('Handling characters not in table', () {
      expect(ChineseUtils.s2t('你好 abc 123'), '你好 abc 123');
    });
  });
}
