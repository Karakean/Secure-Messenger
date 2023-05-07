import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:secure_messenger/models/common.dart';

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

  encrypt.Encrypter? encrypter;
  encrypt.IV? iv;
  List<int> fileBytesBuffer = [];
  String filename = '';
}

class CommunicationHelper {
  static const packetSize = 1024 * 1024; // 1MB

  Future<void> saveBytesToFile(List<int> bytes, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    print('File saved: $filePath'); //TODO mozna wyrzucic potem
  }

  void sendFile(File file, Socket socket, encrypt.Encrypter encrypter, encrypt.IV iv) async {
    Uint8List fixedLengthFileBytes = await file.readAsBytes();
    List<int> fileBytes = fixedLengthFileBytes.toList();
    final totalPackets = (fileBytes.length / packetSize).ceil();
    int packetCounter = 0;
    socket.write(encrypter.encrypt('SEND-FILE', iv: iv).base16);
    //socket.write(encrypter.encrypt(file.uri.pathSegments.last, iv: iv).base16);
    while (fileBytes.isNotEmpty) {
      sendPacket(fileBytes, socket, encrypter, iv, packetCounter, totalPackets);
    }
    socket.write(encrypter.encrypt('SENT', iv: iv).base16);
  }

  void sendPacket(List<int> fileBytes, Socket socket, encrypt.Encrypter encrypter, encrypt.IV iv,
      int packetCounter, int totalPackets) {
    final packetEndIdx = fileBytes.length < packetSize ? fileBytes.length : packetSize;
    final dataChunk = fileBytes.sublist(0, packetEndIdx);
    socket.add(encrypter.encryptBytes(dataChunk, iv: iv).bytes);
    fileBytes.removeRange(0, packetEndIdx);
    packetCounter++;
    print(
        "Sending in progress (${(packetCounter / totalPackets) * 100}%)"); //TODO zamienic na fajny paseczek
  }

  void handleCommunication(
      Socket socket, CommunicationData communicationData, List<int> receivedData) {
    String decryptedMessage =
        communicationData.encrypter!.decrypt16(utf8.decode(receivedData), iv: communicationData.iv);
    switch (communicationData.currentState) {
      case CommunicationStates.regular:
        if (decryptedMessage == 'SEND-FILE') {
          socket.write(communicationData.encrypter!
              .encrypt('FILE-ACCEPT', iv: communicationData.iv)
              .base16); //TODO accept conditionally
          communicationData.currentState = CommunicationStates.filenameExpecation;
          break;
        }
        print(decryptedMessage); //regular message
        break;
      case CommunicationStates.filenameExpecation:
        communicationData.filename = decryptedMessage;
        communicationData.currentState = CommunicationStates.receivingFile;
        break;
      case CommunicationStates.receivingFile:
        if (decryptedMessage == 'SENT') {
          saveBytesToFile(communicationData.fileBytesBuffer,
              communicationData.filename); //TODO dodac prawidlowa sciezke
          communicationData.currentState = CommunicationStates.regular;
          break;
        } else if (decryptedMessage == 'INTERRUPT') {
          //TODO jakies obsluzenie faktu ze sie wydupcylo przesylanie
          communicationData.currentState = CommunicationStates.regular;
          break;
        }
        List<int> decryptedData = communicationData.encrypter!.decryptBytes(
            encrypt.Encrypted(Uint8List.fromList(receivedData)),
            iv: communicationData.iv);
        communicationData.fileBytesBuffer.addAll(decryptedData);
        break;
      default:
        break;
    }
  }

  void test(encrypt.Encrypter encrypter, encrypt.IV iv) async {
    //TODO remove it in the future, it is only for
    // testing purposes
    print('HELLO');
    Uint8List orgbytes = await File('bird.avi').readAsBytes();
    var bytes = orgbytes.toList();
    final totalPackets = (bytes.length / (1024)).ceil();
    int packetCounter = 0;
    List<int> uno = utf8.encode(encrypter.encrypt('SEND-FILE', iv: iv).base16);
    if (encrypter.decrypt16(utf8.decode(uno), iv: iv) != 'SEND-FILE') {
      throw Exception("XD");
    }
    List<int> fileBuffer = [];
    while (bytes.isNotEmpty) {
      final packetEndIdx = bytes.length < 1024 ? bytes.length : 1024;
      if (packetEndIdx == 0) {
        print(bytes);
        print(bytes.isEmpty);
        print(bytes.first);
        print(bytes.isNotEmpty);
        print(bytes.last);
        print("XD");
        print(bytes.length);
      }
      final dataChunk = bytes.sublist(0, packetEndIdx);
      List<int> encryptedChunk = encrypter.encryptBytes(dataChunk, iv: iv).bytes.toList();
      List<int> decryptedChunk =
          encrypter.decryptBytes(encrypt.Encrypted(Uint8List.fromList(encryptedChunk)), iv: iv);
      fileBuffer.addAll(decryptedChunk);
      bytes.removeRange(0, packetEndIdx);
      packetCounter++;
      print("Sending in progress (${(packetCounter / totalPackets) * 100}%)");
    }
    saveBytesToFile(fileBuffer, 'bird2.avi');
  }
}
