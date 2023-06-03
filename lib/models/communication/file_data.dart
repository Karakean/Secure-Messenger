import 'dart:async';
import 'dart:convert';

class FileData {
  List<int> fileBytesBuffer = [];
  Map<int, Completer<void>> completersMap = {};
  String fileName = '';
  int fileSize = 0;
  int receivedBytes = 0;
  int fileAcceptId = 0;
  int fileReceivedId = 0;

  void clear() {
    fileBytesBuffer.clear();
    completersMap.clear();
    fileName = '';
    fileSize = 0;
    receivedBytes = 0;
    fileAcceptId = 0;
    fileReceivedId = 0;
  }

  // void updateFromDto(Map<String, dynamic> dto) {
  //   fileName = dto["fileName"] as String;
  //   fileSize = dto["fileSize"] as int;
  //   fileReceivedId = dto["fileReceivedId"] as int;
  // }

  // Map<String, dynamic> entityToDtoMapper() {
  //   return {
  //     "fileName" : fileName,
  //     "fileSize" : fileSize,
  //     "fileReceivedId" : fileReceivedId
  //   };
  // }

  // String toDtoString() {
  //   final dto = entityToDtoMapper();
  //   return json.encode(dto);
  // }

  // void updateFromDtoString(String plaintext) {
  //   final dto = json.decode(plaintext) as Map<String, dynamic>;
  //   updateFromDto(dto);
  // }
  //TO SIE CHYBA NIE PRZYDA ALE NARAZIE ZOSTAWIE SORY KRZYSIU
}

