import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';

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
  static String base64Encode(String str) {
    return base64.encode(utf8.encode(str));
  }

  /// Base64 解碼
  static String base64Decode(String str) {
    return utf8.decode(base64.decode(str));
  }

  /// 對稱加密/解密
  /// transformation 格式: "Algorithm/Mode/Padding" (例如 "AES/CBC/PKCS7Padding")
  static dynamic symmetricCrypto(
    String action, // "encrypt" or "decrypt"
    String transformation,
    dynamic key,
    dynamic iv,
    dynamic data,
    {String outputFormat = "base64"} // "base64", "hex", "bytes"
  ) {
    final parts = transformation.split('/');
    final algorithmName = parts[0].toUpperCase();
    final modeName = parts.length > 1 ? parts[1].toUpperCase() : 'ECB';
    
    final keyBytes = Uint8List.fromList(_toBytes(key));
    final ivBytes = iv != null ? Uint8List.fromList(_toBytes(iv)) : null;
    
    Key k = Key(keyBytes);
    IV? v = ivBytes != null ? IV(ivBytes) : null;

    late Encrypter encrypter;
    
    if (algorithmName == 'AES') {
      encrypter = Encrypter(AES(k, mode: _getAESMode(modeName)));
    } else if (algorithmName == 'DES') {
      throw UnimplementedError("DES not yet implemented in Dart");
    } else {
      throw UnsupportedError("Unsupported algorithm: $algorithmName");
    }

    if (action == "encrypt") {
      final encrypted = encrypter.encrypt(data.toString(), iv: v);
      if (outputFormat == "hex") return hex.encode(encrypted.bytes);
      if (outputFormat == "bytes") return encrypted.bytes;
      return encrypted.base64;
    } else {
      String decrypted;
      if (data is String) {
        decrypted = encrypter.decrypt(Encrypted.fromBase64(data), iv: v);
      } else {
        decrypted = encrypter.decrypt(Encrypted(Uint8List.fromList(data as List<int>)), iv: v);
      }
      return decrypted;
    }
  }

  static AESMode _getAESMode(String mode) {
    switch (mode) {
      case 'CBC': return AESMode.cbc;
      case 'CFB': return AESMode.cfb64;
      case 'CTR': return AESMode.ctr;
      case 'ECB': return AESMode.ecb;
      case 'OFB': return AESMode.ofb64;
      case 'GCM': return AESMode.gcm;
      default: return AESMode.sic;
    }
  }

  static List<int> _toBytes(dynamic data) {
    if (data is List<int>) return data;
    if (data is String) return utf8.encode(data);
    throw ArgumentError("Unsupported data type for conversion to bytes: ${data.runtimeType}");
  }

  /// 摘要算法 (SHA-1, SHA-256 等)
  static String digest(String data, String algorithm, {bool hex = true}) {
    Hash hasher;
    switch (algorithm.toUpperCase()) {
      case 'SHA-1':
      case 'SHA1': hasher = sha1; break;
      case 'SHA-256':
      case 'SHA256': hasher = sha256; break;
      case 'MD5': hasher = md5; break;
      default: throw UnsupportedError("Unsupported digest algorithm: $algorithm");
    }
    
    final result = hasher.convert(utf8.encode(data));
    return hex ? result.toString() : base64.encode(result.bytes);
  }
}
