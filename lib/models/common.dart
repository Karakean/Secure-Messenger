import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

class InterfaceAndAddress {
  InterfaceAndAddress(this.interface, this.address);

  final InternetAddress address;
  final NetworkInterface interface;

  // @override
  // bool operator ==(dynamic other) => other?.interface == interface && address == other?.address;

  // @override
  // int get hashCode => super.hashCode;
}
