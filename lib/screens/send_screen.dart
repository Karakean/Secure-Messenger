import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/logic/sockets.dart';
import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/chat_screen.dart';
import 'package:secure_messenger/widgets/custom_field.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  static const routeName = "/send";

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  String? destination;

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> connectToServer() async {
    setState(() {
      _loading = true;
    });

    final session = context.read<UserSession>();
    final data = context.read<UserData>();
    final rsa = context.read<RsaKeyHelper>();

    final providers = Providers(user: data, session: session, rsa: rsa);

    final socket = await Socket.connect(destination, 2137);
    session.client = ThingThatTalksToServer(socket, providers);

    session.client!.socket.write('SYN');
  }

  @override
  void didChangeDependencies() {
    //Open chat after establishing connection
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
    UserSession userSession = context.watch<UserSession>();
    final userData = context.read<UserData>();
    return WillPopScope(
      onWillPop: () async {
        userSession.reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Initialize connection"),
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
              if (!_loading)
                Form(
                  key: _formKey,
                  child: CustomField(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "IP address",
                      ),
                      validator: (value) {
                        if (value == null) {
                          return "Enter a value";
                        }
                        if (InternetAddress.tryParse(value) == null) {
                          return "Enter a valid IP address";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_formKey.currentState!.validate()) {
                          return; //nie wyslo
                        }
                        _formKey.currentState!.save();
                      },
                      onSaved: (newValue) {
                        setState(() {
                          destination = newValue;
                        });
                      },
                    ),
                  ),
                ),
              if (_loading)
                userSession.sessionKey != null
                    ? Text("Your session key is: ${userSession.sessionKey!.base64}")
                    : const CircularProgressIndicator(),
              if (_loading)
                Text(
                  "Waiting for the recipient to accept the connection...",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              if (!_loading)
                ElevatedButton(
                  onPressed: destination != null ? connectToServer : null,
                  child: const Text("Connect"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
