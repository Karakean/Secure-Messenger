import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
import 'package:secure_messenger/models/communication/message.dart';
import 'package:secure_messenger/models/exceptions.dart';
import 'package:secure_messenger/models/user.dart';

import '../models/communication/file_data.dart';

const kPacketSize = 1024;

Future<void> saveBytesToFile(List<int> bytes, String fileName) async {
  final path = await getLocalPath();
  final file = File('$path/$fileName');
  await file.writeAsBytes(bytes);
  bytes.clear();
  print('File saved: $fileName'); //TODO mozna wyrzucic potem
}

void sendFile(
  File file,
  UserSession session,
) async {
  assert(session.client == null || session.server == null);

  final Socket socket = session.client?.socket ?? session.server!.handler.socket;
  final fileSendData = session.fileSendData;
  final communicationData = session.communicationData;

  final Uint8List fixedLengthFileBytes = await file.readAsBytes();
  final List<int> fileBytes = fixedLengthFileBytes.toList();
  final int totalPackets = (fileBytes.length / kPacketSize).ceil();
  int packetCounter = 0;

  fileSendData.fileAcceptId = UniqueKey().hashCode;
  fileSendData.fileReceivedId = UniqueKey().hashCode;
  fileSendData.completersMap[fileSendData.fileAcceptId] = Completer<void>();
  fileSendData.completersMap[fileSendData.fileReceivedId] = Completer<void>();
  fileSendData.fileName = file.uri.pathSegments.last;
  fileSendData.fileSize = fileBytes.length;
  communicationData.currentState = CommunicationStates.fileAcceptExpectation;
  socket.write(communicationData.encrypter!
      .encrypt('SEND-FILE/${fileSendData.fileName}/${fileSendData.fileSize}',
          iv: communicationData.iv)
      .base16);
  try {
    await fileSendData.completersMap[fileSendData.fileAcceptId]!.future
        .timeout(const Duration(seconds: 10));

    while (fileBytes.isNotEmpty) {
      fileSendData.completersMap[packetCounter] = Completer<void>();
      sendPacket(fileBytes, socket, communicationData.encrypter!, communicationData.iv!,
          packetCounter, totalPackets);
      session.progress = packetCounter / totalPackets;
      await fileSendData.completersMap[packetCounter++]!.future
          .timeout(const Duration(seconds: 10));
    }

    socket.write(
      communicationData.encrypter!.encrypt('FILE-SENT', iv: communicationData.iv).base16,
    );
    session.progress = 1.0;

    await fileSendData.completersMap[fileSendData.fileReceivedId]!.future
        .timeout(const Duration(seconds: 10));
    print("Wyslano"); //TODO change to popup
  } on TimeoutException {
    session.progress = 1.0;
    await Future.delayed(const Duration(seconds: 1));
    print('Timeout occured during file sending.');
  } on FileRefusedException catch (e) {
    session.progress = 1.0;
    await Future.delayed(const Duration(seconds: 1));
    print(e);
  } finally {
    communicationData.currentState = CommunicationStates.regular;
    fileSendData.clear();
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

void handleCommunication(
  Providers providers,
  Socket socket,
  List<int> receivedData,
) async {
  final CommunicationData communicationData = providers.session.communicationData;
  final FileSendData fileSendData = providers.session.fileSendData;
  final FileReceiveData fileReceiveData = providers.session.fileReceiveData;
  String decryptedMessage = "";
  try {
    decryptedMessage = communicationData.encrypter!.decrypt16(
      utf8.decode(receivedData, allowMalformed: true),
      iv: communicationData.iv,
    );
  } on FormatException {
    //git
  } on AssertionError {
    //tez git
  }

  switch (communicationData.currentState) {
    case CommunicationStates.regular:
      if (decryptedMessage.startsWith('SEND-FILE')) {
        List<String> splittedString = decryptedMessage.split('/');
        String fileName = splittedString[1];
        int fileSize = int.parse(splittedString[2]);
        print(
          'Do you accept file $fileName (size: ${formatFileSize(fileSize)})?',
        ); // TODO change to popup
        if (await _popUpFileAccept(providers.session.chatContext) == true) {
          socket.write(communicationData.encrypter!
              .encrypt('FILE-ACCEPT', iv: communicationData.iv)
              .base16); //TODO accept conditionally
        } else {
          socket.write(
              communicationData.encrypter!.encrypt('FILE-DENY', iv: communicationData.iv).base16);
        }

        fileReceiveData.fileName = fileName;
        fileReceiveData.fileSize = fileSize;
        communicationData.currentState = CommunicationStates.receivingFile;
        break;
      } else {
        List<String> splittedString = decryptedMessage.split('/');
        final username = splittedString[1];
        final msg = splittedString[2];

        providers.session.addMessage(Message(
          username: username, //TODO change
          text: msg,
          isMe: false,
        ));
      }
      break;
    case CommunicationStates.fileAcceptExpectation:
      if (decryptedMessage == 'FILE-ACCEPT') {
        communicationData.currentState = CommunicationStates.sendingFile;
        fileSendData.completersMap[fileSendData.fileAcceptId]!.complete();
      } else if (decryptedMessage == 'FILE-DENY') {
        // fileSendData.completersMap[fileSendData.fileAcceptId]!
        //     .completeError(FileRefusedException("User refused to receive a file."));
        fileSendData.progress = 1.0;
        communicationData.currentState = CommunicationStates.regular;
      }
      break;
    case CommunicationStates.sendingFile:
      if (decryptedMessage.startsWith('PACKET-RECEIVED')) {
        int packetNumber = int.parse(decryptedMessage.split('/')[1]);
        fileSendData.completersMap[packetNumber]!.complete();
      } else if (decryptedMessage == 'FILE-RECEIVED') {
        fileSendData.completersMap[fileSendData.fileReceivedId]!.complete();
      }
      break;
    case CommunicationStates.receivingFile:
      if (decryptedMessage == 'FILE-SENT') {
        saveBytesToFile(
          fileReceiveData.fileBytesBuffer,
          fileReceiveData.fileName,
        ).then((value) => fileReceiveData.clear());
        communicationData.currentState = CommunicationStates.regular;
        socket.write(
            communicationData.encrypter!.encrypt('FILE-RECEIVED', iv: communicationData.iv).base16);
        return;
      }

      List<int> decryptedData = communicationData.encrypter!.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(receivedData)),
        iv: communicationData.iv,
      );
      fileReceiveData.fileBytesBuffer.addAll(decryptedData);
      socket.write(communicationData.encrypter!
          .encrypt('PACKET-RECEIVED/${fileReceiveData.packetCounter++}', iv: communicationData.iv)
          .base16);
      break;

    default:
      break;
  }
}

void sendMessage(
  String msg,
  UserSession session,
  UserData user,
) {
  assert(session.client == null || session.server == null);

  final Socket socket = session.client?.socket ?? session.server!.handler.socket;
  final data = session.communicationData;

  socket.write(data.encrypter!.encrypt('msg/${user.username}/$msg', iv: data.iv).base16);

  session.addMessage(Message(
    username: user.username!,
    text: msg,
    isMe: true,
  ));
}

Future<bool?> _popUpFileAccept(BuildContext? context) {
  return context != null
      ? showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Text("File send request"),
            content: const Text("User wants to send you a file, do you accept?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("No"),
              ),
            ],
          ),
        )
      : Future(() => false);
}
