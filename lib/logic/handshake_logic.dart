import 'dart:io';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/models/communication/rsa_key_helper.dart';
import 'package:secure_messenger/models/communication/client_package.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/logic/file_logic.dart';

void handleServerHandshake(
  BuildContext context,
  Socket socket,
  CommunicationData communicationData,
  List<int> receivedData,
) {
  final rsa = context.read<RsaKeyHelper>();
  final userData = context.read<UserData>();
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
  BuildContext context,
  Socket socket,
  CommunicationData communicationData,
  List<int> receivedData,
) {
  final rsa = context.read<RsaKeyHelper>();

  final decodedData = utf8.decode(receivedData);

  print('yy');

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
      final UserSession userSession = context.read<UserSession>();

      userSession.generateSessionKey();
      communicationData.iv = encrypt.IV.fromSecureRandom(16);
      ClientPackage clientPackage = ClientPackage(
        userSession.sessionKey!,
        "AES",
        "CBC",
        16,
        16,
        communicationData.iv!,
      ); //TODO change to user chosen mode
      communicationData.encrypter = encrypt.Encrypter(
        encrypt.AES(
          userSession.sessionKey!,
          mode: encrypt.AESMode.cbc,
        ),
      ); //TODO change to user chosen mode
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

        print("sending file");
        sendFile(
          File("/home/kulpas/Desktop/xdd.jpeg"),
          socket,
          communicationData.encrypter!,
          communicationData.iv!,
        );

        return;
      }
      break;

    default:
      throw Exception("Something went wrong...");
  }
}
