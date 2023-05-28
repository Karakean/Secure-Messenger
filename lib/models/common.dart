import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

class InterfaceAndAddress {
  final NetworkInterface interface;
  final InternetAddress address;

  InterfaceAndAddress(this.interface, this.address);

  // @override
  // bool operator ==(dynamic other) => other?.interface == interface && address == other?.address;

  // @override
  // int get hashCode => super.hashCode;
}
