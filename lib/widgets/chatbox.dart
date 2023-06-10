import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/logic/communication_logic.dart';
import 'package:secure_messenger/models/user.dart';

class Chatbox extends StatefulWidget {
  const Chatbox({super.key});

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  final _controller = TextEditingController();

  void _sendMessage() async {
    final session = context.read<UserSession>();
    final user = context.read<UserData>();

    sendMessage(_controller.text, session, user);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  Future<bool> _pickAndSendFile(UserSession session) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) return false;

    File file = File(result.files.single.path!);
    sendFile(file, session);
    return true;
  }

  Future<void> _showProgressBar() async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final session = context.watch<UserSession>();
          if (session.progress == 1.0) {
            Navigator.of(context).pop();
          }
          return AlertDialog(
            title: const Text("Sending File"),
            content: LinearProgressIndicator(value: session.progress),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<UserSession>();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              final picked = await _pickAndSendFile(session);
              if (picked) {
                await _showProgressBar();
                session.progress = 0;
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Send a message...'),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _controller.text.trim().isEmpty ? null : _sendMessage,
          )
        ],
      ),
    );
  }
}
