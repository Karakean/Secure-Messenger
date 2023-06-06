import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:secure_messenger/models/communication/rsa_key_helper.dart';
import 'package:secure_messenger/models/user.dart';

Future<String> getLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<String> getSavePath() async {
  final directory = await getDownloadsDirectory();

  return directory!.path;
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

class Providers {
  final UserData user;
  final UserSession session;
  final RsaKeyHelper rsa;

  Providers({required this.user, required this.session, required this.rsa});
}
