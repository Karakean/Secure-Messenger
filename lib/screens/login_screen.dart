import 'dart:io';
import 'dart:math';



import 'package:flutter/material.dart';
import 'package:secure_messenger/tmp.dart';


import '../models/session.dart';
import '../models/rsa_key_helper.dart';




class LoginScreen extends StatefulWidget {
  static const routeName = "/login";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}



class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
  
  NetworkInterface.list().then((interfaces) {
    for (var interface in interfaces) {
      print('Name: ${interface.name}');
      for (var addr in interface.addresses) {
        print('Addr: ${addr}');
      }
    }
  RsaKeyHelper rsaKeyHelper = RsaKeyHelper();
  var keyPair = rsaKeyHelper.generateRSAkeyPair(rsaKeyHelper.exampleSecureRandom());
  rsaKeyHelper.saveKeysToFiles(keyPair);
  rsaKeyHelper.loadKeysFromFiles();
  });
  if (_controller.text.trim() == "xd") {
    // ? dziwne ale wychodzi na to ze menu jest by default na stacku pod loginem
    Navigator.of(context).pop();
  }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Select an interface:",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                "Select an interface:",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                "Enter your password:",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    obscureText: true,
                    controller: _controller,
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(
                      hintText: "Password",
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 10,
                ),
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
