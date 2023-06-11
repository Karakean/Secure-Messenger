import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart';

import 'package:secure_messenger/logic/sockets.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
import 'package:secure_messenger/models/communication/file_data.dart';
import 'package:secure_messenger/models/communication/message.dart';

/// Object containing data that should be reset after every session.
class UserSession with ChangeNotifier {
  UserSession();

  encrypt.IV? _iv;
  encrypt.Key? _sessionKey;
  bool _isECB = true;

  ThingThatIsTheServer? _server;
  ThingThatTalksToServer? _client;
  CommunicationData communicationData = CommunicationData();
  FileSendData fileSendData = FileSendData();
  FileReceiveData fileReceiveData = FileReceiveData();

  List<Message> messages = [];

  /// Required as an argument to create a popup on chat screen.
  BuildContext? chatContext;

  encrypt.IV? get iv => _iv;
  encrypt.Key? get sessionKey => _sessionKey;
  bool get isECB => _isECB;

  ThingThatIsTheServer? get server => _server;
  ThingThatTalksToServer? get client => _client;

  double get progress => fileSendData.progress;

  set sessionKey(encrypt.Key? newKey) {
    _sessionKey = newKey;
    notifyListeners();
  }

  set isECB(bool value) {
    _isECB = value;
    notifyListeners();
  }

  void generateSessionKey() {
    _sessionKey = encrypt.Key.fromSecureRandom(16);
    notifyListeners();
  }

  set server(ThingThatIsTheServer? value) {
    _server = value;
    notifyListeners();
  }

  set client(ThingThatTalksToServer? value) {
    _client = value;
    notifyListeners();
  }

  void reset() {
    _server?.close();
    _server = null;

    _client?.close();
    _client = null;

    _iv = null;
    _sessionKey = null;
    _isECB = true;

    communicationData = CommunicationData();
    fileSendData = FileSendData();
    fileReceiveData = FileReceiveData();

    messages.clear();

    chatContext = null;

    notifyListeners();
  }

  set progress(double progress) {
    fileSendData.progress = progress;
    notifyListeners();
  }

  void addMessage(Message msg) {
    messages.add(msg);
    notifyListeners();
  }
}

/// Object containing data that doesn't change during the session
class UserData with ChangeNotifier {
  NetworkInterface? interface;
  InternetAddress? ipAddr;
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keyPair;
  String? username;
}
