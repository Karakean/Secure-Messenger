import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart';

class UserSession {
  final iv = encrypt.IV.fromLength(23);

  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
}

class UserData with ChangeNotifier {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keyPair;
  String? username;
  NetworkInterface? interface;
  InternetAddress? ipAddr = InternetAddress("192.168.0.8");
}
