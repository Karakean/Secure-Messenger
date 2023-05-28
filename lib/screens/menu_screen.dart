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

  // @override
  // bool operator ==(dynamic other) => other?.interface == interface && address == other?.address;

  // @override
  // int get hashCode => super.hashCode;
}

class MenuScreen extends StatefulWidget {
  static const routeName = "/menu";

  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  InterfaceAndAddress? selectedValue;
  late Future optionsFuture = _getOptions();
  bool isECB = false;

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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Secure Messenger"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("CBC"),
                  Switch(
                    activeColor: Theme.of(context).colorScheme.surface,
                    activeTrackColor: const Color(0x52000000),
                    value: isECB,
                    onChanged: (val) {
                      setState(() {
                        isECB = val;
                      });
                    },
                  ),
                  const Text("ECB"),
                ],
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  // Text(
                  //   userData.ipAddr?.address ?? "No IP address set!",
                  //   style: Theme.of(context).textTheme.titleMedium,
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FutureBuilder(
                        future: optionsFuture,
                        builder: (context, snapshot) => snapshot.data == null
                            ? const CircularProgressIndicator()
                            : DropdownButton(
                                items: [
                                  for (InterfaceAndAddress val in snapshot.data!)
                                    DropdownMenuItem<InterfaceAndAddress>(
                                      value: val,
                                      child: Text("${val.interface.name}: ${val.address.address}"),
                                    )
                                ],
                                value: selectedValue,
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
                        onPressed: () {
                          setState(() {
                            optionsFuture = _getOptions();
                            selectedValue = null;
                          });
                          userData.interface = null;
                          userData.ipAddr = null;
                        },
                        child: const Icon(Icons.refresh),
                      )
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: userData.ipAddr == null
                    ? null
                    : () => Navigator.of(context).pushNamed(SendScreen.routeName),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                child: Text(
                  "Initialize connection",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: userData.ipAddr == null
                    ? null
                    : () => Navigator.of(context).pushNamed(ReceiveScreen.routeName),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                child: Text(
                  "Listen for connections",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
