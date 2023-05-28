import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pointycastle/pointycastle.dart' as rsa;
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';

import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/screens/menu_screen.dart';
import 'package:secure_messenger/widgets/custom_field.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/models/communication/rsa_key_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = "/";

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Future<String> path = getLocalPath();
  final RsaKeyHelper rsaKeyHelper = RsaKeyHelper();

  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  // ignore: unused_field
  String _login = '';
  String _password = '';

  late final TextEditingController _passwordController;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return; //nie wyslo
    }
    _formKey.currentState!.save();

    if (_password != "xdxd") {
      return;
    }

    final rsa.AsymmetricKeyPair<rsa.RSAPublicKey, rsa.RSAPrivateKey>? keyPair;
    final bytes = utf8.encode(_password); //convert string password to UTF-8 bytes
    final hash = sha256.convert(bytes); //create hash from UTF-8 bytes
    final hashHex = hash.toString(); //convert hash to its hexadecimal representation

    if (_isLogin) {
      keyPair = await rsaKeyHelper.loadKeysFromFiles(hashHex);
      if (keyPair == null) {
        print("brak klucza xd");
        return;
      }
    } else {
      keyPair = rsaKeyHelper.generateRSAkeyPair(rsaKeyHelper.exampleSecureRandom());
      await rsaKeyHelper.saveKeysToFiles(keyPair, hashHex);
    }

    if (context.mounted) {
      final userData = context.read<UserData>();
      userData.keyPair = keyPair;

      Navigator.of(context).pushReplacementNamed(MenuScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder(
                  future: path,
                  builder: (context, snapshot) => Image.file(File('${snapshot.data!}/xdd.jpeg')),
                ),
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
      ),
    );
  }
}
