import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/user.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserData(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserSession(),
        ),
      ],
      child: MaterialApp(
        title: 'Secure Messenger',
        theme: ThemeData.light(),
        routes: {
          MenuScreen.routeName: (context) => const MenuScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          SendScreen.routeName: (context) => const SendScreen(),
          ReceiveScreen.routeName: (context) => const ReceiveScreen(),
          ChatScreen.routeName: (context) => const ChatScreen(),
        },
      ),
    );
  }
}
