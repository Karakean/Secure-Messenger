import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/widgets/message_bubble.dart';

/// Widget that renders messages from [UserSession] as [MessageBubble].
class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<UserSession>().messages;
    return messages.isNotEmpty
        ? ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) => MessageBubble(
              messages[index].text,
              messages[index].username,
              messages[index].isMe,
              key: ValueKey(messages[index].id),
            ),
          )
        : const Text("There are no messages yet. Write something!");
  }
}
