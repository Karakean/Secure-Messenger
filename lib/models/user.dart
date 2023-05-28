import 'dart:io';

import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/pointycastle.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

class UserSession with ChangeNotifier {
  //encrypt.Encrypter encrypter;

  UserSession();

  encrypt.IV? _iv;
  encrypt.Key? _sessionKey;
  bool _isECB = true;

  ServerSocket? serverSocket;
  Socket? clientSocket;
  CommunicationData data = CommunicationData();

  encrypt.IV? get iv => _iv;
  encrypt.Key? get sessionKey => _sessionKey;
  bool get isECB => _isECB;

  set sessionKey(encrypt.Key? newKey) {
    _sessionKey = newKey;
    notifyListeners();
  }

  set isECB(bool value) {
    _isECB = value;
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
  NetworkInterface? interface;
  InternetAddress? ipAddr;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keyPair;
  String? username;
}
