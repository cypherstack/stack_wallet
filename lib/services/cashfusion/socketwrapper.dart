import 'dart:io';

class SocketWrapper {
  late Socket _socket;
  final String serverIP;
  final int serverPort;

  late Stream<List<int>> _receiveStream;  // create a field for the broadcast stream

  SocketWrapper(this.serverIP, this.serverPort);
  Socket get socket => _socket;

  Stream<List<int>> get receiveStream => _receiveStream;  // expose the stream with a getter

  Future<void> connect() async {
    _socket = await Socket.connect(serverIP, serverPort);
    _receiveStream = _socket.asBroadcastStream();  // initialize the broadcast stream
    _socket.done.then((_) {
      print('......Socket has been closed');
    });
    _socket.handleError((error) {
      print('Socket error: $error');
    });
  }

  void status() {
    if (_socket != null) {
      print("Socket connected to ${_socket.remoteAddress.address}:${_socket.remotePort}");
    } else {
      print("Socket is not connected");
    }
  }

  Future<void> send(List<int> data) async {
    if (_socket != null) {
      _socket.add(data);
      await _socket.flush();
    } else {
      // handle error
    }
  }

  void close() {
    _socket.close();
  }
}
