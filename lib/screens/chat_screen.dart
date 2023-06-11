import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/menu_screen.dart';
import 'package:secure_messenger/widgets/chatbox.dart';
import 'package:secure_messenger/widgets/messages.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isECB = false;

  @override
  void didChangeDependencies() {
    // Leave chat if connection has been lost.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userSession = context.read<UserSession>();
      if (userSession.server == null && userSession.client == null) {
        Future.delayed(const Duration(milliseconds: 500)).then((value) => userSession.reset());
        Navigator.of(context).pushReplacementNamed(MenuScreen.routeName);
      }
    });

    super.didChangeDependencies();
  }

  @override
  void initState() {
    final userSession = context.read<UserSession>();
    userSession.chatContext = context;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userSession = context.watch<UserSession>();
    final userData = context.read<UserData>();
    return WillPopScope(
      onWillPop: () async {
        userSession.reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          actions: [
            Center(
              child: Text(
                userData.ipAddr != null ? "Your IP is: ${userData.ipAddr!.address}" : "No IP set!",
              ),
            ),
          ],
        ),
        body: const Column(
          children: [
            Expanded(
              child: Messages(),
            ),
            Chatbox(),
          ],
        ),
      ),
    );
  }
}
