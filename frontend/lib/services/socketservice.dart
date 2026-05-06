import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../appconfig.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;

  void init() {
    socket = IO.io(AppConfig.apiBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => print('Connected to Socket Server'));
    socket.onDisconnect((_) => print('Disconnected from Socket Server'));
  }

  // Join an existing room
  void joinRoom(String code) {
    socket.emit('join_room', {'room': code});
  }

  // Host a new room
  void hostRoom(String code) {
    socket.emit('create_room', {'code': code});
  }
}