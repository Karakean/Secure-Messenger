import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

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
    var socket = await Socket.connect(destination, 2137); //TODO change to receiver IP
    var message = await socket.first;
    RsaKeyHelper rsaKeyHelper = RsaKeyHelper(); //TODO singleton
    RSAPublicKey serverPublicKey = rsaKeyHelper.parsePublicKeyFromPem(String.fromCharCodes(message));
    UserSession userSession = UserSession(); //initialize a few things including session key
    socket.writeln(rsaKeyHelper.encrypt(userSession.sessionKey.base64, serverPublicKey)); //DONE send session key encrypted with server public key
    message = await socket.first; //maybe handle first message xd
    print('Server said: $message');

    
    //handleMessages(socket);
    disconnectFromServer(socket);

    await socket.flush();
    await socket.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Initialize connection"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
