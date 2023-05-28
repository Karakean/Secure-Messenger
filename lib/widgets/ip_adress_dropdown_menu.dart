import 'package:flutter/material.dart';

import 'package:secure_messenger/models/common.dart';

class IpAdressDrowdownMenu extends StatelessWidget {
  const IpAdressDrowdownMenu({this.value, required this.values, this.callback, super.key});

  final Function(InterfaceAndAddress?)? callback;
  final InterfaceAndAddress? value;
  final List<InterfaceAndAddress> values;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      items: [
        for (InterfaceAndAddress val in values)
          DropdownMenuItem<InterfaceAndAddress>(
            value: val,
            child: Text("${val.interface.name}: ${val.address.address}"),
          )
      ],
      value: value,
      onChanged: (value) => callback?.call(value),
    );
  }
}
