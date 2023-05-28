import 'package:flutter/material.dart';

import 'package:secure_messenger/widgets/messages.dart';
import 'package:secure_messenger/widgets/chatbox.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static const routeName = '/chat';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isECB = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: const [
          Expanded(
            child: Messages(),
          ),
          Chatbox(),
        ],
      ),
    );
  }
}
