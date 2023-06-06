import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:secure_messenger/models/user.dart';
import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/screens/receive_screen.dart';
import 'package:secure_messenger/screens/send_screen.dart';
import 'package:secure_messenger/widgets/ecb_switch.dart';
import 'package:secure_messenger/widgets/ip_adress_dropdown_menu.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  static const routeName = "/menu";

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool isECB = false;
  late Future optionsFuture = _getOptions();
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
  void initState() {
    final data = context.read<UserData>();
    data.interface = null;
    data.ipAddr = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    UserData userData = context.watch<UserData>();
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Secure Messenger"),
          actions: const [
            EcbSwitch(),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FutureBuilder(
                        future: optionsFuture,
                        builder: (context, snapshot) => snapshot.data == null
                            ? const CircularProgressIndicator()
                            : IpAdressDrowdownMenu(
                                value: selectedValue,
                                values: snapshot.data!,
                                callback: (value) {
                                  setState(() {
                                    selectedValue = value;
                                  });
                                  userData.ipAddr = value?.address;
                                  userData.interface = value?.interface;
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
