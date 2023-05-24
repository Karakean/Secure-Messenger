import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/communication_helper.dart';
import 'package:secure_messenger/models/client_package.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:secure_messenger/screens/chat_screen.dart';

//import 'package:encrypt/encrypt.dart' as encrypt;

import '../models/rsa_key_helper.dart';
import '../models/user.dart';
import 'package:secure_messenger/widgets/custom_field.dart';
import 'package:pointycastle/pointycastle.dart';

class SendScreen extends StatefulWidget {
  static const routeName = "/send";

  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  RsaKeyHelper rsaKeyHelper = RsaKeyHelper();
  CommunicationHelper communicationHelper = CommunicationHelper();
  CancelableOperation? clientFuture;
  final _formKey = GlobalKey<FormState>();
  String? destination;
  bool _loading = false;

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

  Future<void> connectToServer() async {
    setState(() {
      _loading = true;
    });
    var socket = await Socket.connect(destination, 2137);
    CommunicationData communicationData = CommunicationData();
    socket.listen(
      (List<int> receivedData) {
        if (communicationData.afterHandshake) {
          communicationHelper.handleCommunication(socket, communicationData, receivedData);
        } else {
          try {
            handleClientHandshake(socket, communicationData, receivedData);
          } catch (e) {
            print('$e Krzychu obsluzysz to szwagier?');
          }
        }
      },
    );
    socket.write('SYN');
  }

  void handleClientHandshake(
      Socket socket, CommunicationData communicationData, List<int> receivedData) {
    String decodedData = utf8.decode(receivedData);
    switch (communicationData.currentState) {
      case CommunicationStates.initial:
        if (decodedData == 'SYN-ACK') {
          socket.write('ACK');
          communicationData.currentState = CommunicationStates.keyExpectation;
          return;
        }
        break;
      case CommunicationStates.keyExpectation:
        try {
          RSAPublicKey serverPublicKey = rsaKeyHelper.parsePublicKeyFromPem(decodedData);
          UserSession userSession = context.read<UserSession>();
          userSession.generateSessionKey();
          communicationData.iv = encrypt.IV.fromSecureRandom(16);
          ClientPackage clientPackage = ClientPackage(userSession.sessionKey!, "AES", "CBC", 16, 16,
              communicationData.iv!); //TODO change to user chosen mode
          communicationData.encrypter = encrypt.Encrypter(encrypt.AES(userSession.sessionKey!,
              mode: encrypt.AESMode.cbc)); //TODO change to user chosen mode
          String encryptedPackage = rsaKeyHelper.encrypt(clientPackage.toString(), serverPublicKey);
          socket.write(encryptedPackage);
          communicationData.currentState = CommunicationStates.doneExpectation;
          return;
        } catch (e) {
          print('$e Krzychu obsluzysz to szwagier?');
        }
        break;
      case CommunicationStates.doneExpectation:
        if (communicationData.encrypter!.decrypt16(decodedData, iv: communicationData.iv) ==
            'DONE') {
          socket.write(
              communicationData.encrypter!.encrypt('DONE-ACK', iv: communicationData.iv).base16);
          communicationData.currentState = CommunicationStates.regular;
          communicationData.afterHandshake = true;

          print("sending file");
          communicationHelper.sendFile(
            File("/home/kulpas/Desktop/xdd.jpeg"),
            socket,
            communicationData.encrypter!,
            communicationData.iv!,
          );

          return;
        }
        break;
      default:
        break;
    }
    throw Exception("Something went wrong...");
  }

  @override
  Widget build(BuildContext context) {
    UserSession userSession = context.watch<UserSession>();
    return WillPopScope(
      onWillPop: () async {
        clientFuture?.cancel();
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
