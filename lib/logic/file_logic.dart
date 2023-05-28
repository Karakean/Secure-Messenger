import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

const kPacketSize = 1024;

Future<void> saveBytesToFile(List<int> bytes, String filePath) async {
  final path = await getLocalPath();
  final file = File('$path/$filePath');
  await file.writeAsBytes(bytes);
  print('File saved: $filePath'); //TODO mozna wyrzucic potem
}

void sendFile(
  File file,
  Socket socket,
  encrypt.Encrypter encrypter,
  encrypt.IV iv,
) async {
  final Uint8List fixedLengthFileBytes = await file.readAsBytes();
  final List<int> fileBytes = fixedLengthFileBytes.toList();
  final int totalPackets = (fileBytes.length / kPacketSize).ceil();
  int packetCounter = 0;

  socket.write(encrypter.encrypt('SEND-FILE', iv: iv).base16);
  await Future.delayed(
    const Duration(milliseconds: 250),
  ); //TODO: Replace with acknoledge mechanism
  socket.write(encrypter.encrypt(file.uri.pathSegments.last, iv: iv).base16);

  while (fileBytes.isNotEmpty) {
    sendPacket(fileBytes, socket, encrypter, iv, packetCounter, totalPackets);
    await Future.delayed(const Duration(milliseconds: 50));
    packetCounter++;
  }

  socket.write(encrypter.encrypt('SENT', iv: iv).base16);
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

void handleCommunication(
  Socket socket,
  CommunicationData communicationData,
  List<int> receivedData,
) {
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
      if (decryptedMessage == 'SEND-FILE') {
        socket.write(communicationData.encrypter!
            .encrypt('FILE-ACCEPT', iv: communicationData.iv)
            .base16); //TODO accept conditionally
        communicationData.currentState = CommunicationStates.filenameExpecation;
        break;
      }
      break;

    case CommunicationStates.filenameExpecation:
      communicationData.filename = decryptedMessage;
      communicationData.currentState = CommunicationStates.receivingFile;
      break;

    case CommunicationStates.receivingFile:
      if (decryptedMessage == 'SENT') {
        saveBytesToFile(
          communicationData.fileBytesBuffer,
          communicationData.filename,
        ); //TODO dodac prawidlowa sciezke
        communicationData.currentState = CommunicationStates.regular;
        break;
      } else if (decryptedMessage == 'INTERRUPT') {
        //TODO jakies obsluzenie faktu ze sie wydupcylo przesylanie
        communicationData.currentState = CommunicationStates.regular;
        break;
      }

      List<int> decryptedData = communicationData.encrypter!.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(receivedData)),
        iv: communicationData.iv,
      );
      communicationData.fileBytesBuffer.addAll(decryptedData);
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
