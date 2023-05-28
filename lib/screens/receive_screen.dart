import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/logic/file_logic.dart';
import 'package:secure_messenger/logic/handshake_logic.dart';

import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/chat_screen.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

class ReceiveScreen extends StatefulWidget {
  static const routeName = "/receive";

  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
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

  Future<void> initializeServer(UserData userData) async {
    ServerSocket serverSocket = await ServerSocket.bind(userData.ipAddr, 2137);

    await for (Socket clientSocket in serverSocket) {
      CommunicationData communicationData = CommunicationData();
      clientSocket.listen(
        (List<int> receivedData) {
          if (communicationData.afterHandshake) {
            //split or smth idk
            handleCommunication(clientSocket, communicationData, receivedData);
          } else {
            handleServerHandshake(context, clientSocket, communicationData, receivedData);
          }
        },
      );

      await clientSocket.done;
      print(
        'Client disconnected: ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}',
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
