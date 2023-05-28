import 'dart:async';

import 'package:encrypt/encrypt.dart' as encrypt;

enum CommunicationStates {
  initial,
  ackExpectation,
  keyExpectation,
  packageExpectation,
  doneExpectation,
  doneAckExpectation,
  regular,
  fileAcceptExpectation,
  filenameExpectation,
  receivingFile
}

class CommunicationData {
  CommunicationStates currentState = CommunicationStates.initial;
  bool afterHandshake = false;

  encrypt.Encrypter? encrypter;
  encrypt.IV? iv;
  List<int> fileBytesBuffer = [];
  String filename = '';

  int currentFileHash = 0;
  Map<int, Completer<void>> fileAcceptMap = {};
}
