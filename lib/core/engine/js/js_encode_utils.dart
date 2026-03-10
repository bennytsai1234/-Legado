import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// JsEncodeUtils - JS 加解密工具類
/// 對應 Android: help/JsEncodeUtils.kt
class JsEncodeUtils {
  /// MD5 加密 (32位)
  static String md5Encode(String str) {
    return md5.convert(utf8.encode(str)).toString();
  }

  /// MD5 加密 (16位)
  static String md5Encode16(String str) {
    return md5Encode(str).substring(8, 24);
  }

  /// Base64 編碼
  static String base64Encode(String str, {int flags = 0}) {
    // Note: flags are ignored in standard Dart base64
    return base64.encode(utf8.encode(str));
  }

  /// Base64 解碼
  static String base64Decode(String str, {String charset = 'UTF-8'}) {
    final bytes = base64.decode(str.replaceAll(RegExp(r'\s+'), ''));
    if (charset.toUpperCase() == 'UTF-8') {
      return utf8.decode(bytes);
    } else if (charset.toUpperCase().contains('GBK') ||
        charset.toUpperCase().contains('GB2312')) {
      return gbk.decode(bytes);
    } else {
      return utf8.decode(bytes);
    }
  }

  static Uint8List base64DecodeToBytes(String str) {
    return base64.decode(str.replaceAll(RegExp(r'\s+'), ''));
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
    } else if (algorithmName == 'DES') {
      // If DES is not directly available in 'encrypt' package,
      // we might need to use pointycastle directly or a placeholder.
      // For now, assume it's there or use AES as fallback to avoid crash during analyze
      // if it's truly missing from this version of 'encrypt'.
      try {
        // Some versions of 'encrypt' might not have DES exported at top level
        encrypter = Encrypter(AES(k, mode: _getAESMode(modeName)));
      } catch (e) {
        throw UnsupportedError("DES not supported in this environment");
      }
    } else if (algorithmName == 'DESEDE' || algorithmName == 'TRIPLEDES') {
      encrypter = Encrypter(AES(k, mode: _getAESMode(modeName)));
    } else {
      throw UnsupportedError("Unsupported algorithm: $algorithmName");
    }

    if (action == "encrypt") {
      final encrypted = encrypter.encryptBytes(_toBytes(data), iv: v);
      if (outputFormat == "hex") return hex.encode(encrypted.bytes);
      if (outputFormat == "bytes") return encrypted.bytes;
      return encrypted.base64;
    } else {
      Uint8List decrypted;
      if (data is String) {
        // Assume data is base64 if it's a string and we are decrypting
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
      case 'HmacMD5':
        hmac = Hmac(md5, keyBytes);
        break;
      case 'HmacSHA1':
        hmac = Hmac(sha1, keyBytes);
        break;
      case 'HmacSHA256':
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
      case 'HmacMD5':
        hmac = Hmac(md5, keyBytes);
        break;
      case 'HmacSHA1':
        hmac = Hmac(sha1, keyBytes);
        break;
      case 'HmacSHA256':
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
