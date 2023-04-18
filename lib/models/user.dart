import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart';

class UserSession {

  //final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
  late encrypt.IV iv;
  late encrypt.Key sessionKey;
  late encrypt.Encrypter encrypter;
  UserSession() {
    iv = encrypt.IV.fromLength(16);
    sessionKey = encrypt.Key.fromSecureRandom(32);
    encrypter = encrypt.Encrypter(encrypt.AES(sessionKey, mode: encrypt.AESMode.cbc)); //TODO change cbc to user choice cbc or ecb
  }
}

class UserData with ChangeNotifier {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keyPair;
  String? username;
  NetworkInterface? interface;
  InternetAddress? ipAddr = InternetAddress("192.168.0.8");
}
