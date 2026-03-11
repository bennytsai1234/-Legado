import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/js/query_ttf.dart';

void main() {
  group('QueryTTF Tests', () {
    test('Empty font parsing', () async {
      expect(() => QueryTTF(Uint8List(0)), throwsRangeError);
    });
    
    test('BufferReader basic operations', () {
      final bytes = <int>[0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE];
      final reader = BufferReader(Uint8List.fromList(bytes));
      
      expect(reader.readUInt8(), 0x00);
      expect(reader.readUInt8(), 0x01);
      
      reader.position(2);
      expect(reader.readUInt16(), 0x0203);
      
      expect(reader.readUInt16(), 0xFFFE);
      
      reader.position(0);
      expect(reader.readUInt32(), 0x00010203);
    });
  });
}
