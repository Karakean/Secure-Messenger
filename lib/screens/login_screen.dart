import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart' as rsa;
import 'package:provider/provider.dart';
import 'package:secure_messenger/tmp.dart';

import '../models/user.dart';
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
  final RsaKeyHelper rsaKeyHelper = RsaKeyHelper();

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
    // final sessionKey = encrypt.Key.fromSecureRandom(32);
    // final iv = encrypt.IV.fromSecureRandom(16);
    // final encrypter = encrypt.Encrypter(encrypt.AES(sessionKey, mode: encrypt.AESMode.cbc));
    
    // final plaintext = 'Hello, world!';
    // final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // final encodedIv = base64.encode(iv.bytes);
    // final encodedEncrypted = base64.encode(encrypted.bytes);
    
    // print('IV: $encodedIv');
    // print('Encrypted data: $encodedEncrypted');

    UserSession userSession = UserSession();
    encrypt.IV hiv = encrypt.IV.fromLength(16);
    encrypt.Encrypted xd = userSession.encrypter.encrypt("XDDD", iv: hiv);
    String tmp = userSession.sessionKey.base64;
    print("LOL1: " + tmp);
    encrypt.Key kkk = encrypt.Key.fromBase64(tmp);
    print("LOL2: " + kkk.base64);
    encrypt.Encrypter eee = encrypt.Encrypter(encrypt.AES(kkk, mode: encrypt.AESMode.cbc));
    print(eee.decrypt(xd, iv: hiv));
    NetworkInterface.list().then((interfaces) {
      for (var interface in interfaces) {
        print('Name: ${interface.name}');
        for (var addr in interface.addresses) {
          print('Addr: $addr');
        }
      }
    });

    if (!_formKey.currentState!.validate()) {
      return; //nie wyslo
    }
    _formKey.currentState!.save();

    if (_password != "xdxd") {
      return;
    }

    rsa.AsymmetricKeyPair<rsa.RSAPublicKey, rsa.RSAPrivateKey>? keyPair;
    if (_isLogin) {
      keyPair = rsaKeyHelper.loadKeysFromFiles();
      if (keyPair == null) {
        print("brak klucza xd");
        return;
      }
    } else {
      keyPair = rsaKeyHelper.generateRSAkeyPair(rsaKeyHelper.exampleSecureRandom());
      rsaKeyHelper.saveKeysToFiles(keyPair);
    }

    final userData = context.read<UserData>();
    userData.keyPair = keyPair;

    // ? dziwne ale wychodzi na to ze menu jest by default na stacku pod loginem
    Navigator.of(context).pop();
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
                          if (_isLogin) return null;
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
                          if (_isLogin) return null;
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
