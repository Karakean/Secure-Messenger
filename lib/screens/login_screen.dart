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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;

  bool _isLogin = true;
  String _login = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
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

    if (!_formKey.currentState!.validate()) {
      return; //nie wyslo
    }
    _formKey.currentState!.save();

    if (_password == "xdxd") {
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
                "Secure Messenger",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomField(
                      visible: !_isLogin,
                      child: TextFormField(
                        enabled: !_isLogin,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Username",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.characters.length < 4) {
                            return "Enter at least 4 characters";
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _login = newValue!;
                        },
                      ),
                    ),
                    CustomField(
                      child: TextFormField(
                        enabled: true,
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Password",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.characters.length < 4) {
                            return "Enter at least 4 characters";
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _password = newValue!;
                        },
                      ),
                    ),
                    CustomField(
                      visible: !_isLogin,
                      child: TextFormField(
                        enabled: !_isLogin,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Repeat password",
                        ),
                        validator: (value) {
                          if (_passwordController.text != value) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 10,
                ),
                child: Text(_isLogin ? "Log in" : "Register"),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? "I want to register." : "I want to log in.",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomField extends StatelessWidget {
  final Widget child;
  final bool visible;

  const CustomField({this.visible = true, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: visible ? double.infinity : 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: child,
        ),
      ),
    );
  }
}
