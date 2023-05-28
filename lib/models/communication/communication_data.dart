import 'package:encrypt/encrypt.dart' as encrypt;

enum CommunicationStates {
  initial,
  ackExpectation,
  keyExpectation,
  packageExpectation,
  doneExpectation,
  doneAckExpectation,
  regular,
  filenameExpecation,
  receivingFile
}

class CommunicationData {
  CommunicationStates currentState = CommunicationStates.initial;
  bool afterHandshake = false;

  encrypt.Encrypter? encrypter;
  encrypt.IV? iv;
  List<int> fileBytesBuffer = [];
  String filename = '';
}
