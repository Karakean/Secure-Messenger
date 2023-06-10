import 'package:flutter/material.dart';

/// Wrapper that make the text fiels a bit more pretty.
class CustomField extends StatelessWidget {
  const CustomField({this.visible = true, required this.child, super.key});

  final Widget child;
  final bool visible;

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
