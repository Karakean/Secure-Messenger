import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/logic/communication_logic.dart';
import 'package:secure_messenger/logic/handshake_logic.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';
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
  CancelableOperation? clientFuture;
  String? destination;

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> connectToServer() async {
    setState(() {
      _loading = true;
    });

    final session = context.read<UserSession>();

    session.clientSocket = await Socket.connect(destination, 2137);
    session.data = CommunicationData();

    session.clientSocket!.listen(
      (List<int> receivedData) {
        if (session.data.afterHandshake) {
          handleCommunication(session.clientSocket!, session.data, receivedData);
        } else {
          handleClientHandshake(context, session.clientSocket!, session.data, receivedData);
        }
      },
    );
    session.clientSocket!.write('SYN');
  }

  @override
  Widget build(BuildContext context) {
    UserSession userSession = context.watch<UserSession>();
    return WillPopScope(
      onWillPop: () async {
        clientFuture?.cancel();
        userSession.clientSocket?.close();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Initialize connection"),
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
                  onPressed: destination != null
                      ? () {
                          clientFuture = CancelableOperation.fromFuture(connectToServer()).then(
                            (value) =>
                                Navigator.pushReplacementNamed(context, ChatScreen.routeName),
                          );
                        }
                      : null,
                  child: const Text("Connect"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
