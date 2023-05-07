import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//import 'package:encrypt/encrypt.dart' as encrypt;

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
    var socket = await Socket.connect(destination, 2137);

    // Listen for incoming messages from server
    bool afterHandshake = false;
    socket.listen(
      (List<int> data) {
        String message = utf8.decode(data);
        print('Received message from server: $message');

        if (!afterHandshake) {
          RsaKeyHelper rsaKeyHelper = RsaKeyHelper(); //TODO singleton
          RSAPublicKey serverPublicKey = rsaKeyHelper.parsePublicKeyFromPem(message);
          UserSession userSession = context.read<UserSession>();
          userSession.generateSessionKey();
          print(userSession.sessionKey!.base64);
          socket.write(rsaKeyHelper.encrypt(userSession.sessionKey!.base64, serverPublicKey));
          afterHandshake = true;
        }
      },
    );
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
