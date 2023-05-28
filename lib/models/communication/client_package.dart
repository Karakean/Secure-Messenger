import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

class ClientPackage {
  ClientPackage(
    this.sessionKey,
    this.algorithmType,
    this.cipherMode,
    this.keySize,
    this.blockSize,
    this.iv,
  );

  factory ClientPackage.dtoToEntityMapper(Map<String, dynamic> dto) {
    final sessionKeyBase64 = dto['sessionKey'] as String;
    final algorithmType = dto['algorithmType'] as String;
    final cipherMode = dto['cipherMode'] as String;
    final keySize = dto['keySize'] as int;
    final blockSize = dto['blockSize'] as int;
    final ivBase64 = dto['iv'] as String;

    final sessionKeyBytes = encrypt.Key.fromBase64(sessionKeyBase64).bytes;
    if (sessionKeyBytes.length != 16) {
      throw const FormatException('Invalid session key length');
    }
    final sessionKey = encrypt.Key.fromBase64(sessionKeyBase64);

    final ivBytes = encrypt.IV.fromBase64(ivBase64).bytes;
    if (ivBytes.length != 16) {
      throw const FormatException('Invalid IV length');
    }
    final iv = encrypt.IV.fromBase64(ivBase64);

    if (algorithmType != 'AES') {
      throw const FormatException('Invalid algorithm type');
    }

    if (cipherMode != 'CBC' && cipherMode != 'ECB') {
      throw const FormatException('Invalid cipher mode');
    }

    if (keySize != 16) {
      throw const FormatException('Invalid key size');
    }

    if (blockSize != 16) {
      throw const FormatException('Invalid block size');
    }

    return ClientPackage(
      sessionKey,
      algorithmType,
      cipherMode,
      keySize,
      blockSize,
      iv,
    );
  }

  String algorithmType;
  int blockSize; // in bytes
  String cipherMode;
  encrypt.IV iv;
  int keySize; // in bytes
  encrypt.Key sessionKey;

  @override
  String toString() {
    final dto = entityToDtoMapper();
    return json.encode(dto);
  }

  Map<String, dynamic> entityToDtoMapper() {
    return {
      'sessionKey': sessionKey.base64,
      'algorithmType': algorithmType,
      'cipherMode': cipherMode,
      'keySize': keySize,
      'blockSize': blockSize,
      'iv': iv.base64,
    };
  }

  static ClientPackage fromString(String plaintext) {
    final dto = json.decode(plaintext) as Map<String, dynamic>;
    return ClientPackage.dtoToEntityMapper(dto);
  }
}
