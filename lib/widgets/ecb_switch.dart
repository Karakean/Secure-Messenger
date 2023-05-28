import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_messenger/models/user.dart';

class EcbSwitch extends StatelessWidget {
  const EcbSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("CBC"),
          Switch(
            activeColor: Theme.of(context).colorScheme.surface,
            activeTrackColor: const Color(0x52000000),
            value: session.isECB,
            onChanged: (val) {
              session.isECB = val;
            },
          ),
          const Text("ECB"),
        ],
      ),
    );
  }
}
