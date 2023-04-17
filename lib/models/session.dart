import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;


class Session {
  final iv = encrypt.IV.fromLength(23);

  final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromSecureRandom(32)));
  late final NetworkInterface _networkInterface;
  late InternetAddress _assignedAddressIP;

  Session(this._networkInterface) {
      for (var address in _networkInterface.addresses) {
        if (address.type == InternetAddressType.IPv4) {
            _assignedAddressIP = address;
        }
      }
  }
  InternetAddress get addressIP => _assignedAddressIP;
}