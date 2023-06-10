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

/// Contains state of the communication protocol
/// and also the encrypter object for the current session
class CommunicationData {
  CommunicationStates currentState = CommunicationStates.initial;
  bool afterHandshake = false;
  encrypt.Encrypter? encrypter;
  encrypt.IV? iv;
}
