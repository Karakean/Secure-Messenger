import 'package:encrypt/encrypt.dart' as encrypt;

enum CommunicationStates {
  initial,
  ackExpectation,
  keyExpectation,
  packageExpectation,
  doneExpectation,
  doneAckExpectation,
  sendingFile,
  receivingFile,
  fileAcceptExpectation,
  regular
}

class CommunicationData {
  CommunicationStates currentState = CommunicationStates.initial;
  bool afterHandshake = false;
  encrypt.Encrypter? encrypter;
  encrypt.IV? iv;
}
