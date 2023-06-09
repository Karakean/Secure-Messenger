import 'dart:async';

class FileReceiveData {
  List<int> fileBytesBuffer = [];
  List<int> malformedPacketBuffer = [];
  String fileName = '';
  int fileSize = 0;
  int packetCounter = 0;
  int expectedPacketNumber = 0;
  int malformedPacketBytesReceived = 0;
  bool malformedPacket = false;

  void clear() {
    fileBytesBuffer.clear();
    fileName = '';
    fileSize = 0;
    packetCounter = 0;
  }
}

class FileSendData {
  Map<int, Completer<void>> completersMap = {};
  String fileName = '';
  int fileSize = 0;
  int fileAcceptId = 0;
  int fileReceivedId = 0;
  int packetCounter = 0;
  double progress = 0;

  void clear() {
    completersMap.clear();
    fileName = '';
    fileSize = 0;
    fileAcceptId = 0;
    fileReceivedId = 0;
    packetCounter = 0;
    progress = 0;
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
