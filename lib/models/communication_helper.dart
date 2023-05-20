import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;

class CommunicationController {
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
    socket.write(encrypter.encrypt(file.uri.pathSegments.last, iv: iv).base16);
    while (fileBytes.isNotEmpty) {
      sendPacket(fileBytes, socket, encrypter, iv, packetCounter, totalPackets);
    }
    socket.write(encrypter.encrypt('SENT', iv: iv).base16);
  }

  void sendPacket(List<int> fileBytes, Socket socket, encrypt.Encrypter encrypter, encrypt.IV iv, int packetCounter, int totalPackets) {
    final packetEndIdx = fileBytes.length < packetSize ? fileBytes.length : packetSize;
    final dataChunk = fileBytes.sublist(0, packetEndIdx);
    socket.add(encrypter.encryptBytes(dataChunk, iv: iv).bytes);
    fileBytes.removeRange(0, packetEndIdx);
    packetCounter++;
    print("Sending in progress (${(packetCounter / totalPackets) * 100}%)"); //TODO zamienic na fajny paseczek
  }

  bool handleRegularCommunication(encrypt.Encrypter? encrypter, List<int> receivedData, encrypt.IV? iv, List<int> fileBytesBuffer, recvFile) {
    String decryptedMessage = encrypter!.decrypt16(utf8.decode(receivedData), iv: iv);
    if (decryptedMessage == 'SEND-FILE') {
      return true;
    }
    if (recvFile) {
      if (decryptedMessage == 'SENT') {
        saveBytesToFile(fileBytesBuffer, 'tmp.jpg'); //TODO zmienic na prawidlowa sciezke
        return false;
      } else if (decryptedMessage == 'INTERRUPT') {
        //TODO jakies obsluzenie faktu ze sie wydupcylo przesylanie
        return false;
      }
      List<int> decryptedData = encrypter.decryptBytes(encrypt.Encrypted(Uint8List.fromList(receivedData)), iv: iv);
      fileBytesBuffer.addAll(decryptedData);
      return true;
    } 
    print(decryptedMessage); //regular message
    return false;
  }




  void test(encrypt.Encrypter encrypter, encrypt.IV iv) async { //TODO remove it in the future, it is only for 
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
      List<int> decryptedChunk = encrypter.decryptBytes(encrypt.Encrypted(Uint8List.fromList(encryptedChunk)), iv: iv);
      fileBuffer.addAll(decryptedChunk);
      bytes.removeRange(0, packetEndIdx);
      packetCounter++;
      print("Sending in progress (${(packetCounter / totalPackets) * 100}%)");
    }
    saveBytesToFile(fileBuffer, 'bird2.avi');
  }
}


