import 'package:flutter/material.dart';
import 'package:secure_messenger/screens/chat_screen.dart';
import 'package:secure_messenger/screens/login_screen.dart';
import 'package:secure_messenger/screens/menu_screen.dart';
import 'package:secure_messenger/screens/receive_screen.dart';
import 'package:secure_messenger/screens/send_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Messenger',
      theme: ThemeData.light(),
      initialRoute: LoginScreen.routeName,
      routes: {
        "/": (context) => const MenuScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SendScreen.routeName: (context) => const SendScreen(),
        ReceiveScreen.routeName: (context) => const ReceiveScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(),
      },
    );
  }
}