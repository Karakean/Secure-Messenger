import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final RsaKeyHelper rsaKeyHelper = RsaKeyHelper();

    ServerSocket serverSocket = await ServerSocket.bind(
      userData.ipAddr,
      2137, //TODO change to chosen IP
    );
    await for (Socket clientSocket in serverSocket) {
      print('Client connected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}');

      clientSocket.write(rsaKeyHelper.encodePublicKeyToPem(userData.keyPair!.publicKey));

      bool receivedSessionKey = false;
      clientSocket.listen(
        (List<int> data) {
          String message = utf8.decode(data);

          if (!receivedSessionKey) {
            var encryptedSessionKey = message;
            encrypt.Key sessionKey = encrypt.Key.fromBase64(
              rsaKeyHelper.decrypt(encryptedSessionKey, userData.keyPair!.privateKey),
            ); //session key decrypted with server private key
            UserSession userSession = context.read<UserSession>();
            userSession.sessionKey = sessionKey;
            print(sessionKey.base64);
          }

          receivedSessionKey = true;
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
                ? Text("Your session key is: ${userSession.sessionKey!.base64}")
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
