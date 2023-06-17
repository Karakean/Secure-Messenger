import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/client_package.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
import 'package:secure_messenger/models/communication/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';

void handleServerHandshake(
  Providers providers,
  Socket socket,
  List<int> receivedData,
) {
  final rsa = providers.rsa;
  final userData = providers.user;
  final session = providers.session;
  final communicationData = session.communicationData;
  final decodedData = utf8.decode(receivedData, allowMalformed: true);

  switch (communicationData.currentState) {
    case CommunicationStates.initial:
      _handleSynExpectation(socket, decodedData, communicationData);
      break;

    case CommunicationStates.ackExpectation:
      _handleAckExpectation(socket, decodedData, userData, communicationData, rsa);
      break;

    case CommunicationStates.packageExpectation:
      _handlePackageExpectation(socket, decodedData, userData, session, communicationData, rsa);
      break;

    case CommunicationStates.doneAckExpectation:
      _handleDoneAckExpectation(decodedData, communicationData);
      break;

    default:
      throw Exception("Something went wrong...");
  }
}

void handleClientHandshake(
  Providers providers,
  Socket socket,
  List<int> receivedData,
) {
  final rsa = providers.rsa;
  final communicationData = providers.session.communicationData;
  final userSession = providers.session;

  final decodedData = utf8.decode(receivedData);

  switch (communicationData.currentState) {
    case CommunicationStates.initial:
      _handleSynAckExpectation(
        socket,
        decodedData,
        communicationData,
      );
      break;

    case CommunicationStates.keyExpectation:
      _handleKeyExpectation(
        socket,
        decodedData,
        userSession,
        communicationData,
        rsa,
      );
      break;

    case CommunicationStates.doneExpectation:
      _handleDoneExpectation(
        socket,
        decodedData,
        communicationData,
      );
      break;

    default:
      throw Exception("Something went wrong...");
  }
}

void _handleDoneAckExpectation(
  String decodedData,
  CommunicationData communicationData,
) {
  final decryptedData = communicationData.encrypter!.decrypt16(
    decodedData,
    iv: communicationData.iv,
  );

  if (decryptedData == 'DONE-ACK') {
    communicationData.currentState = CommunicationStates.regular;
    communicationData.afterHandshake = true;
  }
}

void _handlePackageExpectation(
  Socket socket,
  String decodedData,
  UserData userData,
  UserSession session,
  CommunicationData communicationData,
  RsaKeyHelper rsa,
) {
  final decryptedMessage = rsa.decrypt(decodedData, userData.keyPair!.privateKey);
  final clientPackage = ClientPackage.fromString(decryptedMessage);
  final chosenMode = clientPackage.cipherMode == "CBC" ? encrypt.AESMode.cbc : encrypt.AESMode.ecb;

  session.sessionKey = clientPackage.sessionKey;
  communicationData.encrypter = encrypt.Encrypter(
    encrypt.AES(
      clientPackage.sessionKey,
      mode: chosenMode,
    ),
  );
  communicationData.iv = clientPackage.iv;

  socket.write(communicationData.encrypter!.encrypt('DONE', iv: communicationData.iv).base16);
  communicationData.currentState = CommunicationStates.doneAckExpectation;
}

void _handleAckExpectation(
  Socket socket,
  String decodedData,
  UserData userData,
  CommunicationData communicationData,
  RsaKeyHelper rsa,
) {
  if (decodedData == 'ACK') {
    socket.write(rsa.encodePublicKeyToPem(userData.keyPair!.publicKey));
    communicationData.currentState = CommunicationStates.packageExpectation;
  }
}

void _handleSynExpectation(
  Socket socket,
  String decodedData,
  CommunicationData communicationData,
) {
  if (decodedData == 'SYN') {
    socket.write('SYN-ACK');
    communicationData.currentState = CommunicationStates.ackExpectation;
  }
}

void _handleSynAckExpectation(
  Socket socket,
  String decodedData,
  CommunicationData communicationData,
) {
  if (decodedData == 'SYN-ACK') {
    socket.write('ACK');
    communicationData.currentState = CommunicationStates.keyExpectation;
  }
}

void _handleKeyExpectation(
  Socket socket,
  String decodedData,
  UserSession userSession,
  CommunicationData communicationData,
  RsaKeyHelper rsa,
) {
  final RSAPublicKey serverPublicKey = rsa.parsePublicKeyFromPem(decodedData);

  userSession.generateSessionKey();
  communicationData.iv = encrypt.IV.fromSecureRandom(16);
  ClientPackage clientPackage = ClientPackage(
    userSession.sessionKey!,
    "AES",
    userSession.isECB ? "ECB" : "CBC",
    16,
    16,
    communicationData.iv!,
  );
  communicationData.encrypter = encrypt.Encrypter(
    encrypt.AES(
      userSession.sessionKey!,
      mode: userSession.isECB ? encrypt.AESMode.ecb : encrypt.AESMode.cbc,
    ),
  );
  String encryptedPackage = rsa.encrypt(
    clientPackage.toString(),
    serverPublicKey,
  );

  socket.write(encryptedPackage);
  communicationData.currentState = CommunicationStates.doneExpectation;
}

void _handleDoneExpectation(
  Socket socket,
  String decodedData,
  CommunicationData communicationData,
) {
  final decryptedData = communicationData.encrypter!.decrypt16(
    decodedData,
    iv: communicationData.iv,
  );

  if (decryptedData == 'DONE') {
    socket.write(
      communicationData.encrypter!.encrypt('DONE-ACK', iv: communicationData.iv).base16,
    );
    communicationData.currentState = CommunicationStates.regular;
    communicationData.afterHandshake = true;
  }
}
