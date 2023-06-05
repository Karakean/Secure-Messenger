import 'dart:io';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import 'package:secure_messenger/logic/communication_logic.dart';
import 'package:secure_messenger/models/common.dart';

import 'package:secure_messenger/models/communication/client_package.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

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
      if (decodedData == 'SYN') {
        socket.write('SYN-ACK');
        communicationData.currentState = CommunicationStates.ackExpectation;
        return;
      }
      break;

    case CommunicationStates.ackExpectation:
      if (decodedData == 'ACK') {
        socket.write(rsa.encodePublicKeyToPem(userData.keyPair!.publicKey));
        communicationData.currentState = CommunicationStates.packageExpectation;
        return;
      }

      break;

    case CommunicationStates.packageExpectation:
      final decryptedMessage = rsa.decrypt(decodedData, userData.keyPair!.privateKey);
      final clientPackage = ClientPackage.fromString(decryptedMessage);
      final chosenMode =
          clientPackage.cipherMode == "CBC" ? encrypt.AESMode.cbc : encrypt.AESMode.ecb;

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
      break;

    case CommunicationStates.doneAckExpectation:
      final decryptedData = communicationData.encrypter!.decrypt16(
        decodedData,
        iv: communicationData.iv,
      );

      if (decryptedData == 'DONE-ACK') {
        communicationData.currentState = CommunicationStates.regular;
        communicationData.afterHandshake = true;
        break;
      }
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
      if (decodedData == 'SYN-ACK') {
        socket.write('ACK');
        communicationData.currentState = CommunicationStates.keyExpectation;
        return;
      }
      break;

    case CommunicationStates.keyExpectation:
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
      break;

    case CommunicationStates.doneExpectation:
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

        Future.delayed(const Duration(seconds: 2)).then((value) {
          print("sending file");
          sendFile(
            File("/home/kulpas/Desktop/test.jpg"),
            providers.session.fileSendData,
            providers.session.communicationData,
            socket,
          );
        });

        return;
      }
      break;

    default:
      throw Exception("Something went wrong...");
  }
}
