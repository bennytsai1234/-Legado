import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/js/js_encode_utils.dart';

void main() {
  group('JsEncodeUtils Tests', () {
    test('MD5 encoding', () {
      expect(JsEncodeUtils.md5Encode('123456'), 'e10adc3949ba59abbe56e057f20f883e');
      expect(JsEncodeUtils.md5Encode16('123456'), '49ba59abbe56e057');
    });

    test('Base64 encoding/decoding', () {
      const original = 'Hello Legado';
      final encoded = JsEncodeUtils.base64Encode(original);
      expect(encoded, 'SGVsbG8gTGVnYWRv');
      expect(JsEncodeUtils.base64Decode(encoded), original);
    });

    test('AES Encryption/Decryption (CBC)', () {
      const key = '1234567890123456'; // 16 bytes
      const iv = '1234567890123456';  // 16 bytes
      const data = 'Secret Message';
      
      final encrypted = JsEncodeUtils.symmetricCrypto(
        'encrypt', 'AES/CBC/PKCS7Padding', key, iv, data
      );
      
      final decrypted = JsEncodeUtils.symmetricCrypto(
        'decrypt', 'AES/CBC/PKCS7Padding', key, iv, encrypted
      );
      
      expect(decrypted, data);
    });

    test('Digest algorithms', () {
      expect(JsEncodeUtils.digest('test', 'SHA-1'), 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3');
    });
  });
}
