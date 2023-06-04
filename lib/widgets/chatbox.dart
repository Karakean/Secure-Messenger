import 'package:flutter/material.dart';
import 'package:secure_messenger/logic/communication_logic.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:provider/provider.dart';

class Chatbox extends StatefulWidget {
  const Chatbox({super.key});

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  final _controller = TextEditingController();
  String _message = '';

  void _sendMessage() async {
    final session = context.read<UserSession>();

    print("aa");
    sendMessage(_controller.text, session);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Send a message...'),
              onChanged: (value) {
                setState(() {
                  _message = value;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _message.trim().isEmpty ? null : _sendMessage,
          )
        ],
      ),
    );
  }
}
