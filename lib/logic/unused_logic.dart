//* SERVER

// void handleMessages(Socket socket) async {
//   while (true) {
//     var message = await socket.first;
//     print(message);
//     if (utf8.decode(message).trim() == "3X17") {
//       return;
//     }
//   }
// }

// void disconnectFromServer(Socket socket) {
//   socket.writeln('QU17');
//   socket.flush();
//   socket.close();
// }

//* CLIENT

// void closeConnection(ServerSocket server, Socket socket) {
//   socket.close();
//   server.close();
// }

// void handleMessages(Socket socket) async {
//   while (true) {
//     var message = await socket.first;
//     print(message);
//     if (utf8.decode(message).trim() == "QU17") {
//       return;
//     }
//   }
// }

//* FILES

// import 'dart:io';
// import 'dart:typed_data';

// Future<Uint8List> readBytesFromFile(String filePath) async {
//   final file = File(filePath);
//   return await file.readAsBytes();
// }

// Future<void> saveBytesToFile(List<int> bytes, String filePath) async {
//   final file = File(filePath);
//   await file.writeAsBytes(bytes);
//   print('File saved: $filePath');
// }

//! MIKOŁAJ CZEMU ZOSTAWIASZ KOD JAK TO NAWET UŻYWANE NIE JEST