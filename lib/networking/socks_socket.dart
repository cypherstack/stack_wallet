import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SOCKSSocket {
  final String proxyHost;
  final int proxyPort;

  late final Socket _socksSocket;
  Socket get socket => _socksSocket;

  final StreamController<List<int>> _responseController =
      StreamController.broadcast();

  // Private constructor
  SOCKSSocket._(this.proxyHost, this.proxyPort);

  static Future<SOCKSSocket> create(
      {required String proxyHost, required int proxyPort}) async {
    var instance = SOCKSSocket._(proxyHost, proxyPort);
    await instance._init();
    return instance;
  }

  SOCKSSocket({required this.proxyHost, required this.proxyPort}) {
    _init();
  }

  /// Initializes the SOCKS socket.

  Future<void> _init() async {
    _socksSocket = await Socket.connect(
      proxyHost,
      proxyPort,
    );

    _socksSocket.listen(
      (data) {
        _responseController.add(data);
      },
      onError: (dynamic e) {
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
    // Greeting and method selection
    _socksSocket.add([0x05, 0x01, 0x00]);

    // Wait for server response
    var response = await _responseController.stream.first;
    if (response[1] != 0x00) {
      throw Exception('Failed to connect to SOCKS5 socket.');
    }
  }

  /// Connects to the specified [domain] and [port] through the SOCKS socket.
  Future<void> connectTo(String domain, int port) async {
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

  /// Sends the server.features command to the proxy server.
  Future<void> sendServerFeaturesCommand() async {
    const String command =
        '{"jsonrpc":"2.0","id":"0","method":"server.features","params":[]}';
    _socksSocket.writeln(command);

    var responseData = await _responseController.stream.first;
    print("responseData: ${utf8.decode(responseData)}");
  }

  /// Closes the connection to the Tor proxy.
  Future<void> close() async {
    await _socksSocket.flush(); // Ensure all data is sent before closing
    await _responseController.close();
    return await _socksSocket.close();
  }
}
