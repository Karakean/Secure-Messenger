import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/logic/communication_logic.dart';
import 'package:secure_messenger/logic/handshake_logic.dart';
import 'package:secure_messenger/models/communication/file_data.dart';

import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/chat_screen.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  static const routeName = "/receive";

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  late final CancelableOperation serverFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      serverFuture = CancelableOperation.fromFuture(
        initializeServer(),
        //Future.delayed(const Duration(seconds: 5)),
      ).then(
        (value) => Navigator.pushReplacementNamed(context, ChatScreen.routeName),
      );
    });
  }

  Future<void> initializeServer() async {
    final session = context.read<UserSession>();
    final data = context.read<UserData>();

    session.serverSocket = await ServerSocket.bind(data.ipAddr, 2137);

    await for (Socket clientSocket in session.serverSocket!) {
      session.communicationData = CommunicationData(); //TODO verify if this initialization is not redundant bo imo jest krzychu skoro to inicjalizujemy w userze xd
      session.fileSendData = FileSendData(); //TODO verify if this initialization is not redundant bo imo jest krzychu skoro to inicjalizujemy w userze xd
      session.fileReceiveData = FileReceiveData(); //TODO verify if this initialization is not redundant bo imo jest krzychu skoro to inicjalizujemy w userze xd
      clientSocket.listen(
        (List<int> receivedData) {
          if (session.communicationData.afterHandshake) {
            //split or smth idk
            handleCommunication(clientSocket, session.communicationData, session.fileSendData, session.fileReceiveData, receivedData);
          } else {
            handleServerHandshake(context, clientSocket, session.communicationData, receivedData);
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
    return WillPopScope(
      onWillPop: () async {
        serverFuture.cancel();
        userSession.serverSocket?.close();
        return true;
      },
      child: Scaffold(
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
      ),
    );
  }
}
