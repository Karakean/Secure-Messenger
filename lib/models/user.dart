import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart';

class UserSession with ChangeNotifier {
  encrypt.IV? _iv;
  encrypt.Key? _sessionKey;
  //encrypt.Encrypter encrypter;

  UserSession();

  encrypt.IV? get iv => _iv;
  encrypt.Key? get sessionKey => _sessionKey;

  set sessionKey(encrypt.Key? newKey) {
    _sessionKey = newKey;
    notifyListeners();
  }

  void generateIV() {
    _iv = encrypt.IV.fromLength(16); //TODO change to fromSecureRandom(16)
    notifyListeners();
  }

  void generateSessionKey() {
    _sessionKey = encrypt.Key.fromSecureRandom(16);
    notifyListeners();
  }

  //encrypter = encrypt.Encrypter(encrypt.AES(sessionKey, mode: encrypt.AESMode.cbc)); //TODO change cbc to user choice cbc or ecb
}

class UserData with ChangeNotifier {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keyPair;
  String? username;
  NetworkInterface? interface;
  InternetAddress? ipAddr = InternetAddress("192.168.0.8");
}
