import 'package:flutter/material.dart';

import 'message_bubble.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.value([
        {'id': 1, 'text': 'xd', 'username': 'maciek'}
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final messages = snapshot.data!;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) => MessageBubble(
            messages[index]['text'] as String,
            messages[index]['username'] as String,
            true,
            key: ValueKey(messages[index]['id']),
          ),
        );
      },
    );
  }
}
