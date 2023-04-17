import 'dart:convert';
import 'dart:typed_data';

import "package:asn1lib/asn1lib.dart";
import 'dart:io';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:pointycastle/asymmetric/api.dart';
import "package:pointycastle/export.dart";


AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAkeyPair(
  SecureRandom secureRandom,
  {int bitLength = 2048}) {
// Create an RSA key generator and initialize it

// final keyGen = KeyGenerator('RSA'); // Get using registry
final keyGen = RSAKeyGenerator();

keyGen.init(ParametersWithRandom(
    RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
    secureRandom));

// Use the generator

final pair = keyGen.generateKeyPair();

// Cast the generated key pair into the RSA key types

final myPublic = pair.publicKey as RSAPublicKey;
final myPrivate = pair.privateKey as RSAPrivateKey;

return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(myPublic, myPrivate);
}

SecureRandom exampleSecureRandom() {
final secureRandom = SecureRandom('Fortuna')
  ..seed(KeyParameter(
      Platform.instance.platformEntropySource().getBytes(32)));
return secureRandom;
}

BigInt validateBigIntValue(BigInt? value) {
  BigInt tmp = value ?? BigInt.one;
  if (tmp == BigInt.one) {
    throw ArgumentError("Invalid key!");
  }
  return tmp;
}

  encodePublicKeyToPem(RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]));
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var publicKeySeq = ASN1Sequence();
    
    publicKeySeq.add(ASN1Integer(validateBigIntValue(publicKey.modulus)));
    publicKeySeq.add(ASN1Integer(validateBigIntValue(publicKey.exponent)));
    var publicKeySeqBitString = ASN1BitString(Uint8List.fromList(publicKeySeq.encodedBytes));

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    var version = ASN1Integer(BigInt.from(0));

    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]));
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var privateKeySeq = ASN1Sequence();
    var modulus = ASN1Integer(validateBigIntValue(privateKey.n));
    var publicExponent = ASN1Integer(BigInt.parse('65537'));
    var privateExponent = ASN1Integer(validateBigIntValue(privateKey.privateExponent));
    var p = ASN1Integer(validateBigIntValue(privateKey.p));
    var q = ASN1Integer(validateBigIntValue(privateKey.q));
    var dP = validateBigIntValue(privateKey.privateExponent) % (validateBigIntValue(privateKey.p) - BigInt.from(1));
    var exp1 = ASN1Integer(dP);
    var dQ = validateBigIntValue(privateKey.privateExponent) % (validateBigIntValue(privateKey.q) - BigInt.from(1));
    var exp2 = ASN1Integer(dQ);
    var iQ = validateBigIntValue(privateKey.q).modInverse(validateBigIntValue(privateKey.p));
    var co = ASN1Integer(iQ);

    privateKeySeq.add(version);
    privateKeySeq.add(modulus);
    privateKeySeq.add(publicExponent);
    privateKeySeq.add(privateExponent);
    privateKeySeq.add(p);
    privateKeySeq.add(q);
    privateKeySeq.add(exp1);
    privateKeySeq.add(exp2);
    privateKeySeq.add(co);
    var publicKeySeqOctetString = ASN1OctetString(Uint8List.fromList(privateKeySeq.encodedBytes));

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(version);
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqOctetString);
    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
  }