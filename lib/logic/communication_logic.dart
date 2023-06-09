import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
import 'package:secure_messenger/models/communication/file_data.dart';
import 'package:secure_messenger/models/communication/message.dart';
import 'package:secure_messenger/models/exceptions.dart';
import 'package:secure_messenger/models/user.dart';

const kPacketSize = 1024;

Future<void> saveBytesToFile(List<int> bytes, String fileName) async {
  final path = await getLocalPath();
  final file = File('$path/$fileName');
  await file.writeAsBytes(bytes);
  bytes.clear();
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

    final fileBytesSlices = fileBytes.slices(kPacketSize);
    for (final slice in fileBytesSlices) {
      fileSendData.completersMap[packetCounter] = Completer<void>();

      final encryptedChunk = communicationData.encrypter!
          .encryptBytes(
            slice,
            iv: communicationData.iv,
          )
          .bytes;
      socket.add(encryptedChunk);

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
) {
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
      _handleRegularCommunication(
        socket,
        decryptedMessage,
        providers,
      );
      break;
    case CommunicationStates.fileAcceptExpectation:
      _handleFileAcceptExpectation(
        decryptedMessage,
        fileSendData,
        communicationData,
      );
      break;
    case CommunicationStates.sendingFile:
      _handleFileSend(
        decryptedMessage,
        fileSendData,
      );
      break;
    case CommunicationStates.receivingFile:
      _handleFileReceive(
        socket,
        receivedData,
        decryptedMessage,
        fileReceiveData,
        communicationData,
      );
      break;

    default:
      break;
  }
}

void _handleRegularCommunication(
  Socket socket,
  String decryptedMessage,
  Providers providers,
) {
  if (decryptedMessage.startsWith('SEND-FILE')) {
    _handleFileReceiveRequest(
      socket,
      decryptedMessage,
      providers,
    );
  } else {
    _handleMessageReceive(decryptedMessage, providers);
  }
}

void _handleFileReceiveRequest(
  Socket socket,
  String decryptedMessage,
  Providers providers,
) async {
  final communicationData = providers.session.communicationData;
  final fileReceiveData = providers.session.fileReceiveData;

  List<String> splittedString = decryptedMessage.split('/');
  String fileName = splittedString[1];
  int fileSize = int.parse(splittedString[2]);

  if (await _popUpFileAccept(providers.session.chatContext) == true) {
    socket.write(
        communicationData.encrypter!.encrypt('FILE-ACCEPT', iv: communicationData.iv).base16);
  } else {
    socket
        .write(communicationData.encrypter!.encrypt('FILE-DENY', iv: communicationData.iv).base16);
  }

  fileReceiveData.fileName = fileName;
  fileReceiveData.fileSize = fileSize;
  communicationData.currentState = CommunicationStates.receivingFile;
}

void _handleMessageReceive(String decryptedMessage, Providers providers) {
  List<String> splittedString = decryptedMessage.split('/');
  final username = splittedString[1];
  final msg = splittedString[2];

  providers.session.addMessage(Message(
    username: username,
    text: msg,
    isMe: false,
  ));
}

void _handleFileAcceptExpectation(
  String decryptedMessage,
  FileSendData fileSendData,
  CommunicationData communicationData,
) {
  if (decryptedMessage == 'FILE-ACCEPT') {
    communicationData.currentState = CommunicationStates.sendingFile;
    fileSendData.completersMap[fileSendData.fileAcceptId]!.complete();
  } else if (decryptedMessage == 'FILE-DENY') {
    // fileSendData.completersMap[fileSendData.fileAcceptId]!
    //     .completeError(FileRefusedException("User refused to receive a file."));
    fileSendData.progress = 1.0;
    communicationData.currentState = CommunicationStates.regular;
  }
}

void _handleFileSend(String decryptedMessage, FileSendData fileSendData) {
  if (decryptedMessage.startsWith('PACKET-RECEIVED')) {
    int packetNumber = int.parse(decryptedMessage.split('/')[1]);
    fileSendData.completersMap[packetNumber]!.complete();
  } else if (decryptedMessage == 'FILE-RECEIVED') {
    fileSendData.completersMap[fileSendData.fileReceivedId]!.complete();
  }
}

void _handleFileReceive(
  Socket socket,
  List<int> receivedData,
  String decryptedMessage,
  FileReceiveData fileReceiveData,
  CommunicationData communicationData,
) {
  if (decryptedMessage == 'FILE-SENT') {
    saveBytesToFile(
      fileReceiveData.fileBytesBuffer,
      fileReceiveData.fileName,
    ).then((value) => fileReceiveData.clear());
    communicationData.currentState = CommunicationStates.regular;
    socket.write(
        communicationData.encrypter!.encrypt('FILE-RECEIVED', iv: communicationData.iv).base16);
  } else {
    List<int> decryptedData = communicationData.encrypter!.decryptBytes(
      encrypt.Encrypted(Uint8List.fromList(receivedData)),
      iv: communicationData.iv,
    );
    fileReceiveData.fileBytesBuffer.addAll(decryptedData);
    socket.write(communicationData.encrypter!
        .encrypt('PACKET-RECEIVED/${fileReceiveData.packetCounter++}', iv: communicationData.iv)
        .base16);
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
