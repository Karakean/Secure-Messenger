import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

import '../models/communication/file_data.dart';

const kPacketSize = 1024;

Future<void> saveBytesToFile(List<int> bytes, String filePath) async {
  final path = await getLocalPath();
  final file = File('$path/$filePath');
  await file.writeAsBytes(bytes);
  bytes.clear();
  print('File saved: $filePath'); //TODO mozna wyrzucic potem
}

void sendFile(
  File file,
  FileData fileData,
  CommunicationData communicationData,
  Socket socket
) async {
  final Uint8List fixedLengthFileBytes = await file.readAsBytes();
  final List<int> fileBytes = fixedLengthFileBytes.toList();
  final int totalPackets = (fileBytes.length / kPacketSize).ceil();
  int packetCounter = 0;

  fileData.fileAcceptId = UniqueKey().hashCode;
  fileData.fileReceivedId = UniqueKey().hashCode;
  fileData.completersMap[fileData.fileAcceptId] = Completer<void>();
  fileData.completersMap[fileData.fileReceivedId] = Completer<void>();
  fileData.fileName = file.uri.pathSegments.last;
  fileData.fileSize = fileBytes.length;
  socket.write(communicationData.encrypter!.encrypt('SEND-FILE/${fileData.fileName}/${fileData.fileSize}', iv: communicationData.iv).base16);
  communicationData.currentState = CommunicationStates.fileAcceptExpectation;
  try {
    await fileData.completersMap[fileData.fileAcceptId]!.future.timeout(const Duration(seconds: 10));

    while (fileBytes.isNotEmpty) {
      sendPacket(fileBytes, socket, communicationData.encrypter!, communicationData.iv!, packetCounter, totalPackets);
      packetCounter++;
    }

    await fileData.completersMap[fileData.fileReceivedId]!.future.timeout(const Duration(seconds: 10));
    print("Wyslano"); //TODO change to popup
  } on TimeoutException catch (e) {
    if (fileData.completersMap[fileData.fileAcceptId]!.isCompleted) {
      print('FILE-RECEIVED not received within the timeout period.');
    } else {
      print('FILE-ACCEPT not received within the timeout period.');
    }
  } finally {
    communicationData.currentState = CommunicationStates.regular;
    fileData.clear();
  }
}

void sendPacket(
  List<int> fileBytes,
  Socket socket,
  encrypt.Encrypter encrypter,
  encrypt.IV iv,
  int packetCounter,
  int totalPackets,
) {
  final packetEndIdx = fileBytes.length < kPacketSize ? fileBytes.length : kPacketSize;
  final dataChunk = fileBytes.sublist(0, packetEndIdx);
  final encryptedChunk = encrypter.encryptBytes(dataChunk, iv: iv).bytes;

  socket.add(encryptedChunk);
  fileBytes.removeRange(0, packetEndIdx);
  print(
    "Sending in progress (${(packetCounter / totalPackets) * 100}%)",
  ); //TODO zamienic na fajny paseczek
}

String formatFileSize(int x) {

  if (x > 1024 * 1024 * 1024) {
    return '${(x / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  } else if (x > 1024 * 1024) {
    return '${(x / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else if (x > 1024) {
    return '${(x / 1024).toStringAsFixed(2)} KB';
  } else {
    return '$x B';
  }
}

void handleCommunication(Socket socket, CommunicationData communicationData, FileData fileData, List<int> receivedData) {
  String decryptedMessage = "";
  try {
    decryptedMessage = communicationData.encrypter!.decrypt16(
      utf8.decode(receivedData, allowMalformed: true),
      iv: communicationData.iv,
    );
  } catch (e) {
    print("$e | secure_messenger ignore");
  }

  switch (communicationData.currentState) {
    case CommunicationStates.regular:
      if (decryptedMessage.startsWith('SEND-FILE')) {
        List<String> splittedString = decryptedMessage.split('/');
        String fileName = splittedString[1];
        int fileSize = int.parse(splittedString[2]);
        print('Do you accept file $fileName (size: ${formatFileSize(fileSize)})?'); // TODO change to popup
        socket.write(communicationData.encrypter!
            .encrypt('FILE-ACCEPT', iv: communicationData.iv)
            .base16); //TODO accept conditionally
        fileData.fileName = fileName;
        fileData.fileSize = fileSize;
        communicationData.currentState = CommunicationStates.receivingFile;
        break;
      }
      break;
    case CommunicationStates.fileAcceptExpectation:
      if (decryptedMessage == 'FILE-ACCEPT') {
        communicationData.currentState = CommunicationStates.sendingFile;
        fileData.completersMap[fileData.fileAcceptId]!.complete();
      }
      break;
    case CommunicationStates.sendingFile:
      if (decryptedMessage == 'FILE-RECEIVED') {
        fileData.completersMap[fileData.fileReceivedId]!.complete();
      }
      break;
    case CommunicationStates.receivingFile:
      List<int> decryptedData = communicationData.encrypter!.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(receivedData)),
        iv: communicationData.iv,
      );
      fileData.fileBytesBuffer.addAll(decryptedData);
      fileData.receivedBytes += decryptedData.length;
      if (fileData.fileSize == fileData.receivedBytes) {
        saveBytesToFile(
          fileData.fileBytesBuffer,
          fileData.fileName,
        ); //TODO dodac prawidlowa sciezke
        fileData.clear();
        communicationData.currentState = CommunicationStates.regular;
        socket.write(communicationData.encrypter!
            .encrypt('FILE-RECEIVED', iv: communicationData.iv)
            .base16);
      }
      break;

    default:
      break;
  }
}

void fileTest(encrypt.Encrypter encrypter, encrypt.IV iv) async {
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
