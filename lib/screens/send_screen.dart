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
  CommunicationController communicationController = CommunicationController();

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
    encrypt.Encrypter? encrypter;
    encrypt.IV? iv;
    var socket = await Socket.connect(destination, 2137);
    bool establishedConnection = false;
    int handshakeProgress = 0; //progress of the handshake
    List<int> fileBytesBuffer = []; //are we receiving file rn
    bool recvFile = false;
    socket.listen(
      (List<int> receivedData) {
        if (establishedConnection){
          recvFile = communicationController.handleRegularCommunication(encrypter, receivedData, iv, fileBytesBuffer, recvFile);
        } else {
          handshakeProgress = handleClientHandshake(encrypter, iv, receivedData, socket, handshakeProgress);
        }

        if (handshakeProgress == -1) {
          throw Exception("Krzychu dasz tu cos fajnego?");
        } else if(handshakeProgress == 3) {
          establishedConnection = true;
          print("ESSA"); //TODO przejscie do chatu
        }
      },
    );
    socket.write('SYN');
  }

  int handleClientHandshake(encrypt.Encrypter? encrypter, encrypt.IV? iv, List<int> receivedData, Socket socket, int handshakeProgress) {
    String decodedData = utf8.decode(receivedData);
    switch(handshakeProgress) {
      case 0:
        if (decodedData == 'SYN-ACK') {
          socket.write('ACK');
          return ++handshakeProgress;
        }
        break;
      case 1:
        try {
          RSAPublicKey serverPublicKey = rsaKeyHelper.parsePublicKeyFromPem(decodedData);
          UserSession userSession = context.read<UserSession>();
          userSession.generateSessionKey();
          iv = encrypt.IV.fromSecureRandom(16);
          ClientPackage clientPackage = ClientPackage(userSession.sessionKey!, "AES", "CBC", 16, 16, iv); //TODO change to user chosen mode
          encrypter = encrypt.Encrypter(encrypt.AES(userSession.sessionKey!, mode: encrypt.AESMode.cbc)); //TODO change to user chosen mode
          String encryptedPackage = rsaKeyHelper.encrypt(clientPackage.toString(), serverPublicKey);
          socket.write(encryptedPackage);
          return ++handshakeProgress;
        } catch (e) {
          print('$e Krzychu obsluzysz to szwagier?');
        }
        break;
      case 2:
        if (encrypter!.decrypt16(decodedData, iv: iv) == 'DONE') {
          socket.write(encrypter.encrypt('DONE-ACK', iv: iv).base16);
          return ++handshakeProgress;
        }
        break;
      default:
        break;
    }
    return -1;
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
