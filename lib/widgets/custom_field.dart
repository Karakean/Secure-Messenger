import 'package:flutter/material.dart';

class CustomField extends StatelessWidget {
  final Widget child;
  final bool visible;

  const CustomField({this.visible = true, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: visible ? double.infinity : 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: child,
        ),
      ),
    );
  }
}
