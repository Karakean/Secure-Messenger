import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/client_package.dart';
import 'package:secure_messenger/models/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:secure_messenger/screens/chat_screen.dart';

import '../models/communication_helper.dart';

class ReceiveScreen extends StatefulWidget {
  static const routeName = "/receive";

  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final RsaKeyHelper rsaKeyHelper = RsaKeyHelper();
  CommunicationHelper communicationHelper = CommunicationHelper();
  late final CancelableOperation serverFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final userData = context.read<UserData>();
      serverFuture = CancelableOperation.fromFuture(
        initializeServer(userData),
        //Future.delayed(const Duration(seconds: 5)),
      ).then(
        (value) => Navigator.pushReplacementNamed(context, ChatScreen.routeName),
      );
    });
  }

  // void closeConnection(ServerSocket server, Socket socket) {
  //   socket.close();
  //   server.close();
  // }

  // void handleMessages(Socket socket) async {
  //   while (true) {
  //     var message = await socket.first;
  //     print(message);
  //     if (utf8.decode(message).trim() == "QU17") {
  //       return;
  //     }
  //   }
  // }

  Future<Uint8List> readBytesFromFile(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  Future<void> saveBytesToFile(List<int> bytes, String filePath) async {
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    print('File saved: $filePath');
  }

  Future<void> initializeServer(UserData userData) async {
    // UserSession userSession = context.read<UserSession>();
    // userSession.generateSessionKey();
    // iv = encrypt.IV.fromSecureRandom(16);
    // communicationHelper.test(encrypt.Encrypter(encrypt.AES(userSession.sessionKey!)), iv);
    ServerSocket serverSocket = await ServerSocket.bind(userData.ipAddr, 2137);

    await for (Socket clientSocket in serverSocket) {
      //print('Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
      CommunicationData communicationData = CommunicationData();
      clientSocket.listen(
        (List<int> receivedData) {
          if (communicationData.afterHandshake) {
            //split or smth idk
            communicationHelper.handleCommunication(clientSocket, communicationData, receivedData);
          } else {
            try {
              handleServerHandshake(clientSocket, communicationData, userData, receivedData);
            } catch (e) {
              print('$e Krzychu obsluzysz to szwagier?');
            }
          }
        },
      );

      await clientSocket.done;
      print(
        'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}',
      );
    }
  }

  void handleServerHandshake(Socket socket, CommunicationData communicationData, UserData userData,
      List<int> receivedData) {
    String decodedData = utf8.decode(receivedData, allowMalformed: true); // tu sie jebie
    switch (communicationData.currentState) {
      case CommunicationStates.initial:
        if (decodedData == 'SYN') {
          socket.write('SYN-ACK');
          communicationData.currentState = CommunicationStates.ackExpectation;
          return;
        }
        break;
      case CommunicationStates.ackExpectation:
        try {
          if (decodedData == 'ACK') {
            socket.write(rsaKeyHelper.encodePublicKeyToPem(userData.keyPair!.publicKey));
            communicationData.currentState = CommunicationStates.packageExpectation;
            return;
          }
        } catch (e) {
          print("$e ??!!");
        }

        break;
      case CommunicationStates.packageExpectation:
        try {
          String decryptedMessage = rsaKeyHelper.decrypt(decodedData, userData.keyPair!.privateKey);
          print("decrypted");
          ClientPackage clientPackage = ClientPackage.fromString(decryptedMessage);
          encrypt.AESMode chosenMode =
              clientPackage.cipherMode == "CBC" ? encrypt.AESMode.cbc : encrypt.AESMode.ecb;
          communicationData.encrypter =
              encrypt.Encrypter(encrypt.AES(clientPackage.sessionKey, mode: chosenMode));
          communicationData.iv = clientPackage.iv;
          socket
              .write(communicationData.encrypter!.encrypt('DONE', iv: communicationData.iv).base16);
          communicationData.currentState = CommunicationStates.doneAckExpectation;
          return;
        } catch (e) {
          print('$e szkurna pkg-expect');
        }
        break;
      case CommunicationStates.doneAckExpectation:
        if (communicationData.encrypter!.decrypt16(decodedData, iv: communicationData.iv) ==
            'DONE-ACK') {
          communicationData.currentState = CommunicationStates.regular;
          communicationData.afterHandshake = true;
          return;
        }
        break;
      default:
        break;
    }
    throw Exception("Something went wrong...");
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listen for connections"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userSession.sessionKey != null
                ? Text(
                    "Your session key is: ${userSession.sessionKey!.base64}") //Krzychu wez to wyrzuc co to tu wgl robi
                : const CircularProgressIndicator(),
            Text(
              "Listening for connections...",
              style: Theme.of(context).textTheme.titleLarge,
            )
          ],
        ),
      ),
    );
  }
}
