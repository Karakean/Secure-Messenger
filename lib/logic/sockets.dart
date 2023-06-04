import 'dart:io';

import 'package:secure_messenger/logic/file_logic.dart';
import 'package:secure_messenger/logic/handshake_logic.dart';
import 'package:secure_messenger/models/common.dart';
import 'package:secure_messenger/models/communication/communication_data.dart';

class ThingThatIsTheServer {
  final Providers providers;
  final ServerSocket server;
  bool connected = false;
  late final ThingThatTalksToClient handler;

  ThingThatIsTheServer(this.server, this.providers) {
    server.listen((client) {
      connected = true;
      providers.session.data = CommunicationData();
      handler = ThingThatTalksToClient(client, providers);
    });
  }

  Future<ServerSocket> close() async {
    if (connected) handler.close();
    return server.close();
  }
}

class ThingThatTalksToClient {
  final Providers providers;
  final Socket socket;

  ThingThatTalksToClient(this.socket, this.providers) {
    socket.listen(messageHandler, onError: errorHandler, onDone: finishedHandler);
  }

  void messageHandler(List<int> data) {
    if (providers.session.data.afterHandshake) {
      //split or smth idk
      handleCommunication(providers, socket, data);
    } else {
      handleServerHandshake(providers, socket, data);
    }
  }

  void errorHandler(error) {
    print("ERROR CLOSING SOCKET");
    close();
  }

  void finishedHandler() {
    print("DONE CLOSING SOCKET");
    close();
  }

  void close() {
    providers.session.server = null;
    socket.destroy();
  }

  // void write(String message) {
  //   _socket.write(message);
  // }
}

class ThingThatTalksToServer {
  final Socket socket;
  final Providers providers;

  ThingThatTalksToServer(this.socket, this.providers) {
    socket.listen(messageHandler, onError: errorHandler, onDone: finishedHandler);
  }

  void messageHandler(List<int> data) {
    if (providers.session.data.afterHandshake) {
      //split or smth idk
      handleCommunication(providers, socket, data);
    } else {
      handleClientHandshake(providers, socket, data);
    }
  }

  void errorHandler(error) {
    print("ERROR CLOSING SOCKET");
    close();
  }

  void finishedHandler() {
    print("DONE CLOSING SOCKET");
    close();
  }

  void close() {
    providers.session.client = null;
    socket.destroy();
  }

  // void write(String message) {
  //   _socket.write(message);
  // }
}
