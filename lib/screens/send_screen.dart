import 'package:flutter/material.dart';

class SendScreen extends StatelessWidget {
  static const routeName = "/send";

  const SendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wyślij wiadomość"),
      ),
      body: const Center(
        child: Text("Fajno"),
      ),
    );
  }
}
