import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/communication_helper.dart';
import 'package:secure_messenger/models/client_package.dart';
import 'package:encrypt/encrypt.dart' as encrypt;


import '../models/rsa_key_helper.dart';
import '../models/user.dart';
import 'package:pointycastle/pointycastle.dart';

class SendScreen extends StatefulWidget {
  static const routeName = "/send";

  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  InternetAddress destination = InternetAddress("192.168.0.8");
  RsaKeyHelper rsaKeyHelper = RsaKeyHelper();
  CommunicationHelper communicationHelper = CommunicationHelper();

  void disconnectFromServer(Socket socket) {
    socket.writeln('QU17');
    socket.flush();
    socket.close();
  }

  void handleMessages(Socket socket) async {
    while (true) {
      var message = await socket.first;
      print(message);
      if (utf8.decode(message).trim() == "3X17") {
        return;
      }
    }
  }

  void connectToServer() async {
    var socket = await Socket.connect(destination, 2137);
    CommunicationData communicationData = CommunicationData();
    socket.listen(
      (List<int> receivedData) {
        if (communicationData.currentState == CommunicationStates.regular) {
          communicationHelper.handleCommunication(socket, communicationData, receivedData);
        } else {
          try {
            handleClientHandshake(socket, communicationData, receivedData);
          } catch (e) {
            print('$e Krzychu obsluzysz to szwagier?');
          }
        }
      },
    );
    socket.write('SYN');
  }

  void handleClientHandshake(Socket socket, CommunicationData communicationData, List<int> receivedData) {
    String decodedData = utf8.decode(receivedData);
    switch(communicationData.currentState) {
      case CommunicationStates.initial:
        if (decodedData == 'SYN-ACK') {
          socket.write('ACK');
          communicationData.currentState = CommunicationStates.keyExpectation;
          return;
        }
        break;
      case CommunicationStates.keyExpectation:
        try {
          RSAPublicKey serverPublicKey = rsaKeyHelper.parsePublicKeyFromPem(decodedData);
          UserSession userSession = context.read<UserSession>();
          userSession.generateSessionKey();
          communicationData.iv = encrypt.IV.fromSecureRandom(16);
          ClientPackage clientPackage = ClientPackage(userSession.sessionKey!, "AES", "CBC", 16, 16, communicationData.iv!); //TODO change to user chosen mode
          communicationData.encrypter = encrypt.Encrypter(encrypt.AES(userSession.sessionKey!, mode: encrypt.AESMode.cbc)); //TODO change to user chosen mode
          String encryptedPackage = rsaKeyHelper.encrypt(clientPackage.toString(), serverPublicKey);
          socket.write(encryptedPackage);
          communicationData.currentState = CommunicationStates.doneExpectation;
          return;
        } catch (e) {
          print('$e Krzychu obsluzysz to szwagier?');
        }
        break;
      case CommunicationStates.doneExpectation:
        if (communicationData.encrypter!.decrypt16(decodedData, iv: communicationData.iv) == 'DONE') {
          socket.write(communicationData.encrypter!.encrypt('DONE-ACK', iv: communicationData.iv).base16);
          communicationData.currentState = CommunicationStates.regular;
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
    UserSession userSession = context.watch<UserSession>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Initialize connection"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userSession.sessionKey != null
                ? Text("Your session key is: ${userSession.sessionKey!.base64}")
                : const CircularProgressIndicator(),
            Text(
              "Waiting for the recipient to accept the connection...",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ElevatedButton(
              onPressed: connectToServer,
              child: const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }
}
