import 'dart:io';

import 'package:flutter/material.dart';
import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/screens/receive_screen.dart';
import 'package:secure_messenger/screens/send_screen.dart';
import 'package:provider/provider.dart';

class InterfaceAndAddress {
  final NetworkInterface interface;
  final InternetAddress address;

  InterfaceAndAddress(this.interface, this.address);

  @override
  bool operator ==(dynamic other) => other?.interface == interface && address == other?.address;

  @override
  int get hashCode => super.hashCode;
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  InterfaceAndAddress? selectedValue;

  Future<List<InterfaceAndAddress>> _getOptions() async {
    final List<InterfaceAndAddress> items = [];
    final interfaces = await NetworkInterface.list();

    for (NetworkInterface interface in interfaces) {
      for (InternetAddress addr in interface.addresses) {
        items.add(
          InterfaceAndAddress(interface, addr),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = context.watch<UserData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Messenger"),
        actions: [
          Text("${userData.ipAddr?.address}"),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder(
              future: _getOptions(),
              builder: (context, snapshot) => DropdownButton(
                items: [
                  for (InterfaceAndAddress val in snapshot.data!)
                    DropdownMenuItem<InterfaceAndAddress>(
                      value: val,
                      child: Text("${val.interface.name}: ${val.address.address}"),
                    )
                ],
                value: snapshot.data!.first,
                onChanged: (value) {
                  setState(() {
                    selectedValue = value;
                  });
                  userData.interface = value?.interface;
                  userData.ipAddr = value?.address;
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(SendScreen.routeName),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
              child: Text(
                "Initialize connection",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed:
                  true ? () => Navigator.of(context).pushNamed(ReceiveScreen.routeName) : null,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
              child: Text(
                "Listen for connections",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
