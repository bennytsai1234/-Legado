import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/block/des_base.dart';
import 'package:pointycastle/block/desede_engine.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:archive/archive.dart';

/// JsEncodeUtils - JS 加解密工具類
/// 對應 Android: help/JsEncodeUtils.kt
class JsEncodeUtils {
  // --- Android Base64 Flags ---
  static const int base64Default = 0;
  static const int base64NoPadding = 1;
  static const int base64NoWrap = 2;
  static const int base64Crlf = 4;
  static const int base64UrlSafe = 8;

  /// MD5 加密 (32位)
  static String md5Encode(String str) {
    return md5.convert(utf8.encode(str)).toString();
  }

  /// MD5 加密 (16位)
  static String md5Encode16(String str) {
    return md5Encode(str).substring(8, 24);
  }

  /// Base64 編碼 (支援 Flags)
  static String base64Encode(dynamic data, {int flags = 0}) {
    final bytes = _toBytes(data);
    String result;
    
    if ((flags & base64UrlSafe) != 0) {
      result = base64Url.encode(bytes);
    } else {
      result = base64.encode(bytes);
    }

    if ((flags & base64NoPadding) != 0) {
      result = result.replaceAll('=', '');
    }
    
    // Dart base64.encode doesn't wrap by default, so NO_WRAP is implicit.
    // CRLF is not typically used in JS book sources, skipping for now.
    
    return result;
  }

  /// Base64 解碼
  static String base64Decode(String str, {String charset = 'UTF-8', int flags = 0}) {
    final cleanStr = str.replaceAll(RegExp(r'\s+'), '');
    // 補齊 Padding
    String paddedStr = cleanStr;
    if (cleanStr.length % 4 != 0) {
      paddedStr = cleanStr.padRight(cleanStr.length + (4 - cleanStr.length % 4), '=');
    }

    final bytes = (flags & base64UrlSafe) != 0 
        ? base64Url.decode(paddedStr)
        : base64.decode(paddedStr);

    if (charset.toUpperCase() == 'UTF-8') {
      return utf8.decode(bytes);
    } else if (charset.toUpperCase().contains('GBK') ||
        charset.toUpperCase().contains('GB2312')) {
      return gbk.decode(bytes);
    } else {
      return utf8.decode(bytes);
    }
  }

  static Uint8List base64DecodeToBytes(String str, {int flags = 0}) {
    final cleanStr = str.replaceAll(RegExp(r'\s+'), '');
    String paddedStr = cleanStr;
    if (cleanStr.length % 4 != 0) {
      paddedStr = cleanStr.padRight(cleanStr.length + (4 - cleanStr.length % 4), '=');
    }
    return (flags & base64UrlSafe) != 0 
        ? base64Url.decode(paddedStr)
        : base64.decode(paddedStr);
  }

  /// CRC32 校驗 (高度還原 java.util.zip.CRC32)
  static String crc32(dynamic data) {
    final bytes = _toBytes(data);
    final crcValue = getCrc32(bytes);
    return crcValue.toRadixString(16);
  }

  /// 十六進位解碼為位元組陣列
  static Uint8List hexDecodeToByteArray(String hexStr) {
    return Uint8List.fromList(hex.decode(hexStr));
  }

  /// 十六進位解碼為字串
  static String hexDecodeToString(String hexStr, {String charset = 'UTF-8'}) {
    final bytes = hex.decode(hexStr);
    if (charset.toUpperCase() == 'UTF-8') {
      return utf8.decode(bytes);
    } else {
      return gbk.decode(bytes);
    }
  }

  /// 字串轉十六進位
  static String hexEncodeToString(String str) {
    return hex.encode(utf8.encode(str));
  }

  /// 對稱加密/解密 (底層方法)
  /// transformation 格式: "Algorithm/Mode/Padding" (例如 "AES/CBC/PKCS7Padding")
  static dynamic symmetricCrypto(
    String action, // "encrypt" or "decrypt"
    String transformation,
    dynamic key,
    dynamic iv,
    dynamic data, {
    String outputFormat = "base64", // "base64", "hex", "bytes", "string"
  }) {
    final parts = transformation.split('/');
    final algorithmName = parts[0].toUpperCase();
    final modeName = parts.length > 1 ? parts[1].toUpperCase() : 'ECB';

    final keyBytes = _toBytes(key);
    final ivBytes = iv != null ? _toBytes(iv) : null;

    Key k = Key(Uint8List.fromList(keyBytes));
    IV? v = ivBytes != null ? IV(Uint8List.fromList(ivBytes)) : null;

    late Encrypter encrypter;

    if (algorithmName == 'AES') {
      encrypter = Encrypter(AES(k, mode: _getAESMode(modeName)));
    } else if (algorithmName == 'DES' ||
        algorithmName == 'DESEDE' ||
        algorithmName == 'TRIPLEDES') {
      return _pointycastleSymmetricCrypto(
        action,
        algorithmName,
        modeName,
        keyBytes,
        ivBytes,
        data,
        outputFormat,
      );
    } else {
      throw UnsupportedError("Unsupported algorithm: \$algorithmName");
    }

    if (action == "encrypt") {
      final encrypted = encrypter.encryptBytes(_toBytes(data), iv: v);
      if (outputFormat == "hex") return hex.encode(encrypted.bytes);
      if (outputFormat == "bytes") return encrypted.bytes;
      return encrypted.base64;
    } else {
      Uint8List decrypted;
      if (data is String) {
        decrypted = Uint8List.fromList(
          encrypter.decryptBytes(Encrypted.fromBase64(data), iv: v),
        );
      } else {
        decrypted = Uint8List.fromList(
          encrypter.decryptBytes(
            Encrypted(Uint8List.fromList(_toBytes(data))),
            iv: v,
          ),
        );
      }

      if (outputFormat == "string") return utf8.decode(decrypted);
      if (outputFormat == "bytes") return decrypted;
      if (outputFormat == "hex") return hex.encode(decrypted);
      return base64.encode(decrypted);
    }
  }

  static AESMode _getAESMode(String mode) {
    switch (mode) {
      case 'CBC':
        return AESMode.cbc;
      case 'CFB':
        return AESMode.cfb64;
      case 'CTR':
        return AESMode.ctr;
      case 'ECB':
        return AESMode.ecb;
      case 'OFB':
        return AESMode.ofb64;
      case 'GCM':
        return AESMode.gcm;
      default:
        return AESMode.sic;
    }
  }

  static List<int> _toBytes(dynamic data) {
    if (data is Uint8List) return data.toList();
    if (data is List<int>) return data;
    if (data is String) return utf8.encode(data);
    throw ArgumentError("Unsupported data type: ${data.runtimeType}");
  }

  static dynamic _pointycastleSymmetricCrypto(
    String action,
    String algorithmName,
    String modeName,
    List<int> keyBytes,
    List<int>? ivBytes,
    dynamic data,
    String outputFormat,
  ) {
    pc.BlockCipher engine;
    if (algorithmName == 'DES') {
      engine = DESEngine();
    } else {
      // DESEDE or TRIPLEDES
      engine = DESedeEngine();
    }

    pc.BlockCipher cipher;
    if (modeName == 'ECB') {
      cipher = engine;
    } else {
      cipher = pc.CBCBlockCipher(engine);
    }

    final pc.PaddedBlockCipher padder = pc.PaddedBlockCipherImpl(
      pc.PKCS7Padding(),
      cipher,
    )..init(
      action == 'encrypt',
      modeName == 'ECB'
          ? pc.PaddedBlockCipherParameters(
            pc.KeyParameter(Uint8List.fromList(keyBytes)),
            null,
          )
          : pc.PaddedBlockCipherParameters(
            pc.ParametersWithIV(
              pc.KeyParameter(Uint8List.fromList(keyBytes)),
              Uint8List.fromList(ivBytes ?? List.filled(engine.blockSize, 0)),
            ),
            null,
          ),
    );

    if (action == 'encrypt') {
      final inputBytes = Uint8List.fromList(_toBytes(data));
      final encryptedBytes = padder.process(inputBytes);
      if (outputFormat == "hex") return hex.encode(encryptedBytes);
      if (outputFormat == "bytes") return encryptedBytes;
      return base64.encode(encryptedBytes);
    } else {
      Uint8List inputBytes;
      if (data is String) {
        inputBytes = base64DecodeToBytes(data);
      } else {
        inputBytes = Uint8List.fromList(_toBytes(data));
      }
      final decryptedBytes = padder.process(inputBytes);

      if (outputFormat == "string") return utf8.decode(decryptedBytes);
      if (outputFormat == "bytes") return decryptedBytes;
      if (outputFormat == "hex") return hex.encode(decryptedBytes);
      return base64.encode(decryptedBytes);
    }
  }

  // === AES Variants ===

  static dynamic aesEncode(
    String data,
    String key,
    String transformation,
    String iv, {
    String format = "base64",
  }) {
    return symmetricCrypto(
      "encrypt",
      transformation,
      key,
      iv,
      data,
      outputFormat: format,
    );
  }

  static dynamic aesDecode(
    String data,
    String key,
    String transformation,
    String iv, {
    String format = "string",
  }) {
    return symmetricCrypto(
      "decrypt",
      transformation,
      key,
      iv,
      data,
      outputFormat: format,
    );
  }

  static String? aesDecodeArgsBase64Str(
    String data,
    String keyBase64,
    String mode,
    String padding,
    String ivBase64,
  ) {
    final key = base64.decode(keyBase64);
    final iv = base64.decode(ivBase64);
    return symmetricCrypto(
      "decrypt",
      "AES/$mode/$padding",
      key,
      iv,
      data,
      outputFormat: "string",
    );
  }

  // === HMAC ===

  static String hmacHex(String data, String algorithm, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    Hmac hmac;
    switch (algorithm.toUpperCase()) {
      case 'HMACMD5':
        hmac = Hmac(md5, keyBytes);
        break;
      case 'HMACSHA1':
        hmac = Hmac(sha1, keyBytes);
        break;
      case 'HMACSHA256':
        hmac = Hmac(sha256, keyBytes);
        break;
      default:
        throw UnsupportedError("Unsupported HMAC algorithm: $algorithm");
    }
    return hmac.convert(dataBytes).toString();
  }

  static String hmacBase64(String data, String algorithm, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    Hmac hmac;
    switch (algorithm.toUpperCase()) {
      case 'HMACMD5':
        hmac = Hmac(md5, keyBytes);
        break;
      case 'HMACSHA1':
        hmac = Hmac(sha1, keyBytes);
        break;
      case 'HMACSHA256':
        hmac = Hmac(sha256, keyBytes);
        break;
      default:
        throw UnsupportedError("Unsupported HMAC algorithm: $algorithm");
    }
    return base64.encode(hmac.convert(dataBytes).bytes);
  }

  /// 摘要算法 (SHA-1, SHA-256 等)
  static String digest(String data, String algorithm, {bool hexFormat = true}) {
    Hash hasher;
    switch (algorithm.toUpperCase()) {
      case 'SHA-1':
      case 'SHA1':
        hasher = sha1;
        break;
      case 'SHA-256':
      case 'SHA256':
        hasher = sha256;
        break;
      case 'MD5':
        hasher = md5;
        break;
      default:
        throw UnsupportedError("Unsupported digest algorithm: $algorithm");
    }

    final result = hasher.convert(utf8.encode(data));
    return hexFormat ? result.toString() : base64.encode(result.bytes);
  }
}

/// 補償 PointyCastle 3.9.1 移除的單層 DESEngine 實作
class DESEngine extends DesBase implements pc.BlockCipher {
  static const int _blockSize = 8;
  List<int>? workingKey;
  bool forEncryption = false;

  @override
  String get algorithmName => 'DES';

  @override
  int get blockSize => _blockSize;

  @override
  void init(bool forEncryption, covariant pc.CipherParameters? params) {
    if (params is pc.KeyParameter) {
      this.forEncryption = forEncryption;
      var key = params.key;
      if (key.length != 8) {
        throw ArgumentError('DES key size must be 8 bytes.');
      }
      workingKey = generateWorkingKey(forEncryption, key);
    } else if (params is pc.ParametersWithIV) {
      this.forEncryption = forEncryption;
      var key = (params.parameters as pc.KeyParameter).key;
      if (key.length != 8) {
        throw ArgumentError('DES key size must be 8 bytes.');
      }
      workingKey = generateWorkingKey(forEncryption, key);
    }
  }

  @override
  Uint8List process(Uint8List data) {
    var out = Uint8List(_blockSize);
    var len = processBlock(data, 0, out, 0);
    return out.sublist(0, len);
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (workingKey == null) throw StateError('DES engine not initialised');
    desFunc(workingKey!, inp, inpOff, out, outOff);
    return _blockSize;
  }

  @override
  void reset() {}
}
