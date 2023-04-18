import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';

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

    var server = await ServerSocket.bind(userData.ipAddr, 2137); //TODO change to chosen IP
    var socket = await server.first;
    socket.writeln(
        rsaKeyHelper.encodePublicKeyToPem(userData.keyPair!.publicKey)); //TODO send public key
    var response = await socket.first;
    print('Session key $response'); //TODO handle response which should be encoded session key
    socket.writeln('Hello there!'); //maybe write some ACK message ncoded with session key? idk
    //handleMessages(socket);
    closeConnection(server, socket);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listen for connections"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
