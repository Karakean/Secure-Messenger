import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class ReceiveScreen extends StatelessWidget {
  static const routeName = "/receive";

  void closeConnection(ServerSocket server, Socket socket) {
    socket.close();
    server.close();
  }

  void handleMessages(Socket socket) async {
    while(true) {
      var message = await socket.first;
      print(message);
      if (utf8.decode(message).trim() == "QU17") {
        return;
      }
    }
  }

  void initializeServer() async {
    var server = await ServerSocket.bind('127.0.0.1', 2137); //TODO change to chosen IP
    var socket = await server.first;
    socket.writeln('My public key is XYZ.'); //TODO send public key
    var response = await socket.first;
    print('Session key $response'); //TODO handle response which should be encoded session key
    socket.writeln('Hello there!'); //maybe write some ACK message ncoded with session key? idk
    //handleMessages(socket);
    closeConnection(server, socket);
  }

  const ReceiveScreen({super.key});

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
