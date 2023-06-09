import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/logic/sockets.dart';
import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/chat_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  static const routeName = "/receive";

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  @override
  void initState() {
    super.initState();
    initializeServer();
  }

  Future<void> initializeServer() async {
    final session = context.read<UserSession>();
    final data = context.read<UserData>();
    final rsa = context.read<RsaKeyHelper>();

    final providers = Providers(user: data, session: session, rsa: rsa);

    final socket = await ServerSocket.bind(data.ipAddr, 2137, shared: true);
    session.server = ThingThatIsTheServer(socket, providers);
  }

  @override
  void didChangeDependencies() {
    // Open chat after establishing connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userSession = context.read<UserSession>();
      if (userSession.sessionKey != null) {
        Navigator.pushReplacementNamed(context, ChatScreen.routeName);
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    final userData = context.read<UserData>();
    return WillPopScope(
      onWillPop: () async {
        userSession.reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Listen for connections"),
          actions: [
            Center(
              child: Text(
                userData.ipAddr != null ? "Your IP is: ${userData.ipAddr!.address}" : "No IP set!",
              ),
            ),
          ],
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
