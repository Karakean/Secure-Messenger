import 'dart:convert';
import 'dart:typed_data';

import "package:asn1lib/asn1lib.dart";
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// ignore: implementation_imports
import 'package:pointycastle/src/platform_check/platform_check.dart';
//import 'package:pointycastle/asymmetric/api.dart';
import "package:pointycastle/export.dart";

class RsaKeyHelper {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
    SecureRandom secureRandom, {
    int bitLength = 2048,
  }) {
    // Create an RSA key generator and initialize it
    // final keyGen = KeyGenerator('RSA'); // Get using registry
    final keyGen = RSAKeyGenerator();

    keyGen.init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ),
    );

    // Use the generator

    final pair = keyGen.generateKeyPair();

    // Cast the generated key pair into the RSA key types

    final myPublic = pair.publicKey as RSAPublicKey;
    final myPrivate = pair.privateKey as RSAPrivateKey;

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
  }

  SecureRandom exampleSecureRandom() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(
        KeyParameter(Platform.instance.platformEntropySource().getBytes(32)),
      );
    return secureRandom;
  }

  encodePublicKeyToPem(RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x5, 0x0]),
    );
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    final publicKeySeq = ASN1Sequence();

    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    final publicKeySeqBitString = ASN1BitString(
      Uint8List.fromList(publicKeySeq.encodedBytes),
    );

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    final dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final version = ASN1Integer(BigInt.from(0));

    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]),
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    final privateKeySeq = ASN1Sequence();
    final modulus = ASN1Integer(privateKey.n!);
    final publicExponent = ASN1Integer(BigInt.parse('65537'));
    final privateExponent = ASN1Integer(privateKey.privateExponent!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = privateKey.privateExponent! % (privateKey.p!) - BigInt.from(1);
    final exp1 = ASN1Integer(dP);
    final dQ = privateKey.privateExponent! % (privateKey.q!) - BigInt.from(1);
    final exp2 = ASN1Integer(dQ);
    final iQ = privateKey.q!.modInverse(privateKey.p!);
    final co = ASN1Integer(iQ);

    privateKeySeq.add(version);
    privateKeySeq.add(modulus);
    privateKeySeq.add(publicExponent);
    privateKeySeq.add(privateExponent);
    privateKeySeq.add(p);
    privateKeySeq.add(q);
    privateKeySeq.add(exp1);
    privateKeySeq.add(exp2);
    privateKeySeq.add(co);
    final publicKeySeqOctetString = ASN1OctetString(Uint8List.fromList(privateKeySeq.encodedBytes));

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(version);
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqOctetString);
    final dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
  }

  Uint8List decodePEM(String pem) {
    final startsWith = [
      "-----BEGIN PUBLIC KEY-----",
      "-----BEGIN PRIVATE KEY-----",
      "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
      "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: React-Native-OpenPGP.js 0.1\r\nComment: http://openpgpjs.org\r\n\r\n",
    ];
    final endsWith = [
      "-----END PUBLIC KEY-----",
      "-----END PRIVATE KEY-----",
      "-----END PGP PUBLIC KEY BLOCK-----",
      "-----END PGP PRIVATE KEY BLOCK-----",
    ];
    bool isOpenPgp = pem.contains('BEGIN PGP');

    for (final s in startsWith) {
      if (pem.startsWith(s)) {
        pem = pem.substring(s.length);
      }
    }

    for (final s in endsWith) {
      if (pem.endsWith(s)) {
        pem = pem.substring(0, pem.length - s.length);
      }
    }

    if (isOpenPgp) {
      final index = pem.indexOf('\r\n');
      pem = pem.substring(0, index);
    }

    pem = pem.replaceAll('\n', '');
    pem = pem.replaceAll('\r', '');

    return base64.decode(pem);
  }

  String encrypt(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()
      ..init(
        true,
        PublicKeyParameter<RSAPublicKey>(publicKey),
      );
    final cipherText = cipher.process(Uint8List.fromList(plaintext.codeUnits));

    return String.fromCharCodes(cipherText);
  }

  String decrypt(String ciphertext, RSAPrivateKey privateKey) {
    final cipher = RSAEngine()..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(Uint8List.fromList(ciphertext.codeUnits));

    return String.fromCharCodes(decrypted);
  }

  parsePublicKeyFromPem(pemString) {
    Uint8List publicKeyDER = decodePEM(pemString);
    final asn1Parser = ASN1Parser(publicKeyDER);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1];

    final publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes()!);
    ASN1Sequence publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    final modulus = publicKeySeq.elements[0] as ASN1Integer;
    final exponent = publicKeySeq.elements[1] as ASN1Integer;

    RSAPublicKey rsaPublicKey = RSAPublicKey(
      modulus.valueAsBigInteger!,
      exponent.valueAsBigInteger!,
    );

    return rsaPublicKey;
  }

  parsePrivateKeyFromPem(pemString) {
    Uint8List privateKeyDER = decodePEM(pemString);
    var asn1Parser = ASN1Parser(privateKeyDER);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    // var version = topLevelSeq.elements[0];
    // final algorithm = topLevelSeq.elements[1];
    final privateKey = topLevelSeq.elements[2];

    asn1Parser = ASN1Parser(privateKey.contentBytes()!);
    final pkSeq = asn1Parser.nextObject() as ASN1Sequence;

    // var version = pkSeq.elements[0];
    final modulus = pkSeq.elements[1] as ASN1Integer;
    //final publicExponent = pkSeq.elements[2] as ASN1Integer;
    final privateExponent = pkSeq.elements[3] as ASN1Integer;
    final p = pkSeq.elements[4] as ASN1Integer;
    final q = pkSeq.elements[5] as ASN1Integer;
    // final exp1 = pkSeq.elements[6] as ASN1Integer;
    // final exp2 = pkSeq.elements[7] as ASN1Integer;
    // final co = pkSeq.elements[8] as ASN1Integer;

    RSAPrivateKey rsaPrivateKey = RSAPrivateKey(
      modulus.valueAsBigInteger!,
      privateExponent.valueAsBigInteger!,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );

    return rsaPrivateKey;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<void> saveKeysToFiles(AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair) async {
    final path = await _localPath;

    final publicDir = Directory('$path/public');
    if (!publicDir.existsSync()) {
      publicDir.createSync();
    }
    final privateDir = Directory('$path/private');
    if (!privateDir.existsSync()) {
      privateDir.createSync();
    }

    final publicKeyFile = File('$path/public/key.pem');
    publicKeyFile.writeAsString(encodePublicKeyToPem(keyPair.publicKey));
    final privateKeyFile = File('$path/private/key.pem');
    privateKeyFile.writeAsString(encodePrivateKeyToPem(keyPair.privateKey));
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>?> loadKeysFromFiles() async {
    final path = await _localPath;
    print(_localPath);

    final publicKeyFile = File('$path/public/key.pem');
    final privateKeyFile = File('$path/private/key.pem');
    if (await publicKeyFile.exists() && await privateKeyFile.exists()) {
      final publicKey = parsePublicKeyFromPem(await publicKeyFile.readAsString());
      final privateKey = parsePrivateKeyFromPem(await privateKeyFile.readAsString());
      return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
    }
    return null;
  }
}
