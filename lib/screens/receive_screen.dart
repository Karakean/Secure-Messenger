import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/ClientPackage.dart';
import 'package:secure_messenger/models/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ReceiveScreen extends StatefulWidget {
  static const routeName = "/receive";

  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final RsaKeyHelper rsaKeyHelper = RsaKeyHelper();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final userData = context.read<UserData>();
      initializeServer(userData);
    });
  }

  void closeConnection(ServerSocket server, Socket socket) {
    socket.close();
    server.close();
  }

  void handleMessages(Socket socket) async {
    while (true) {
      var message = await socket.first;
      print(message);
      if (utf8.decode(message).trim() == "QU17") {
        return;
      }
    }
  }

  void initializeServer(UserData userData) async {
    encrypt.Encrypter? encrypter;
    encrypt.IV? iv;
    ServerSocket serverSocket = await ServerSocket.bind(
      userData.ipAddr,
      2137
    );

    await for (Socket clientSocket in serverSocket) {
      //print('Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');
      bool establishedConnection = false;
      int handshakeProgress = 0; //progress of the handshake
      clientSocket.listen(
        (List<int> data) {
          String message = utf8.decode(data);
          if (establishedConnection){
            //normal msg handling
          } else {
            handshakeProgress = handshake(encrypter, iv, userData, clientSocket, message, handshakeProgress);
          }

          if (handshakeProgress == -1) {
            throw Exception("Krzychu dasz tu cos fajnego?");
          } else if(handshakeProgress == 3) {
            establishedConnection = true;
            print("ESSA");
          }
        },
      );

      clientSocket.done.then(
        (_) {
          print(
            'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}',
          );
        },
      );
    }
  }

  int handshake(encrypt.Encrypter? encrypter, encrypt.IV? iv, UserData userData, Socket socket, String message, int handshakeProgress) {
    switch(handshakeProgress) {
      case 0:
        if (message == 'SYN') {
          socket.write('SYN-ACK');
          return ++handshakeProgress;
        }
        break;
      case 1:
        if (message == 'ACK') {
          socket.write(rsaKeyHelper.encodePublicKeyToPem(userData.keyPair!.publicKey));
          return ++handshakeProgress;
        }
        break;
      case 2:
        try {
          String decryptedMessage = rsaKeyHelper.decrypt(message, userData.keyPair!.privateKey);
          ClientPackage clientPackage = ClientPackage.fromString(decryptedMessage);
          encrypt.AESMode chosenMode = clientPackage.cipherMode == "CBC" ? encrypt.AESMode.cbc : encrypt.AESMode.ecb;
          encrypter = encrypt.Encrypter(encrypt.AES(clientPackage.sessionKey, mode: chosenMode));
          iv = clientPackage.iv;
          socket.write(encrypter.encrypt('DONE', iv: iv).base16);
          return ++handshakeProgress;
        } catch (e) {
          print('$e Krzychu obsluzysz to szwagier?');
        }
        break;
      default:
        break;
    }
    return -1;
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
                ? Text("Your session key is: ${userSession.sessionKey!.base64}") //Krzychu wez to wyrzuc co to tu wgl robi
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
