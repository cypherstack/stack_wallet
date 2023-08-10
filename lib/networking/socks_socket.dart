import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A SOCKS5 proxy client
class SOCKSSocket {
  final String host;
  final int port;

  late Socket _socksSocket;
  Socket get socket => _socksSocket;

  final StreamController<List<int>> _responseController = StreamController();

  // TODO accept String host or InternetAddress host
  SOCKSSocket({required this.host, required this.port}) {
    _init();
  }

  /// Initializes the SOCKS socket.
  Future<void> _init() async {
    _socksSocket = await Socket.connect(
      host,
      port,
    );

    _socksSocket.listen(
      (data) {
        _responseController.add(data);
      },
      onError: (e) {
        if (e is Object) {
          _responseController.addError(e);
        }
        _responseController.addError("$e");
        // TODO make sure sending error as string is acceptable
      },
      onDone: () {
        _responseController.close();
      },
    );
  }

  /// Connects to the SOCKS socket.
  Future<void> connect() async {
    _socksSocket = await Socket.connect(host, port);

    // Greeting and method selection
    _socksSocket.add([0x05, 0x01, 0x00]);

    // Wait for server response
    var response = await _socksSocket.first;
    if (response[1] != 0x00) {
      throw Exception('Failed to connect to SOCKS5 socket.');
    }
  }

  /// Connects to the specified [domain] and [port] through the SOCKS socket.
  Future<void> connectTo(String domain, int port) async {
    // Command, Reserved, Address Type, Address, Port
    var request = [
      0x05,
      0x01,
      0x00,
      0x03,
      domain.length,
      ...domain.codeUnits,
      (port >> 8) & 0xFF,
      port & 0xFF
    ];

    _socksSocket.add(request);

    if (await _responseController.stream.isEmpty) {
      throw Exception(
          'Stream has no data: Failed to connect to target through SOCKS5 proxy.');
    }

    // // Wait for server response
    // var response;
    // try {
    //   response = await _responseController.stream.first
    //       .timeout(const Duration(seconds: 10), onTimeout: () {
    //     throw TimeoutException(
    //         'Failed to get response from the server within 10 seconds.');
    //   });
    // } catch (e) {
    //   throw Exception('Failed to connect to target through SOCKS5 proxy: $e');
    // }
    var response = await _responseController.stream.first;
    if (response[1] != 0x00) {
      throw Exception('Failed to connect to target through SOCKS5 proxy.');
    }
  }

  /// Converts [object] to a String by invoking [Object.toString] and
  /// sends the encoding of the result to the socket.
  void write(Object? object) {
    if (object == null) return;

    List<int> data = utf8.encode(object.toString());
    _socksSocket.add(data);
  }

  /// Closes the connection to the Tor proxy.
  Future<void> close() async {
    await _socksSocket.flush(); // Ensure all data is sent before closing
    await _responseController.close();
    return await _socksSocket.close();
  }
}
