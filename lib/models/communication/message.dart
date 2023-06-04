import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class Message {
  final String id;
  final String username;
  final String text;
  final bool isMe;

  Message({
    required this.username,
    required this.text,
    required this.isMe,
  }) : id = uuid.v4();
}
