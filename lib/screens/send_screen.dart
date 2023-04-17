import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class SendScreen extends StatelessWidget {
  static const routeName = "/send";

  const SendScreen({super.key});

  void disconnectFromServer(Socket socket) {
    socket.writeln('QU17');
    socket.flush();
    socket.close();
  }

  void handleMessages(Socket socket) async {
    while(true) {
      var message = await socket.first;
      print(message);
      if (utf8.decode(message).trim() == "3X17") {
        return;
      }
    }
  }

  void connectToServer() async {
    var socket = await Socket.connect('127.0.0.1', 2137); //TODO change to receiver IP
    var message = await socket.first;
    print('PUBLIC KEY $message'); //TODO take server's public key
    socket.writeln('ENCRYPTED SESSION KEY'); //TODO send session key encrypted with session key
    message = await socket.first; //maybe handle some message xd
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
            )
          ],
        ),
    ),
    );
  }
}
