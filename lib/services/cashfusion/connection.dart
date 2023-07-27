import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:stackwallet/services/cashfusion/socketwrapper.dart';

/*
This file might need some fixing up because each time we call fillBuf, we're trying to
remove data from a buffer but its a local copy , might not actually
remove the data from the socket buffer.  We may need a wrapper class for the buffer??

 */

class BadFrameError extends Error {
  final String message;

  BadFrameError(this.message);

  @override
  String toString() => message;
}

Future<Connection> openConnection(
  String host,
  int port, {
  double connTimeout = 5.0,
  double defaultTimeout = 5.0,
  bool ssl = false,
  dynamic socksOpts,
}) async {
  try {
    // Dart's Socket class handles connection timeout internally.
    Socket socket = await Socket.connect(host, port);
    if (ssl) {
      // We can use SecureSocket.secure to upgrade socket connection to SSL/TLS.
      socket = await SecureSocket.secure(socket);
    }

    return Connection(
        socket: socket, timeout: Duration(seconds: defaultTimeout.toInt()));
  } catch (e) {
    throw 'Failed to open connection: $e';
  }
}

class Connection {
  Duration timeout = Duration(seconds: 1);
  Socket? socket;

  static const int MAX_MSG_LENGTH = 200 * 1024;
  static final Uint8List magic =
      Uint8List.fromList([0x76, 0x5b, 0xe8, 0xb4, 0xe4, 0x39, 0x6d, 0xcf]);
  final Uint8List recvbuf = Uint8List(0);
  Connection({required this.socket, this.timeout = const Duration(seconds: 1)});
  Connection.withoutSocket({this.timeout = const Duration(seconds: 1)});

  Future<void> sendMessageWithSocketWrapper(
      SocketWrapper socketwrapper, List<int> msg,
      {Duration? timeout}) async {
    timeout ??= this.timeout;
    print("DEBUG sendmessage msg sending ");
    print(msg);
    final lengthBytes = Uint8List(4);
    final byteData = ByteData.view(lengthBytes.buffer);
    byteData.setUint32(0, msg.length, Endian.big);

    final frame = <int>[]
      ..addAll(Connection.magic)
      ..addAll(lengthBytes)
      ..addAll(msg);

    try {
      socketwrapper.send(frame);
    } on SocketException catch (e) {
      throw TimeoutException('Socket write timed out', timeout);
    }
  }

  Future<void> sendMessage(List<int> msg, {Duration? timeout}) async {
    timeout ??= this.timeout;

    final lengthBytes = Uint8List(4);
    final byteData = ByteData.view(lengthBytes.buffer);
    byteData.setUint32(0, msg.length, Endian.big);

    print(Connection.magic);
    final frame = <int>[]
      ..addAll(Connection.magic)
      ..addAll(lengthBytes)
      ..addAll(msg);

    try {
      StreamController<List<int>> controller = StreamController();

      controller.stream.listen((data) {
        socket?.add(data);
      });

      try {
        controller.add(frame);
        // Remove the socket.flush() if it doesn't help.
        // await socket?.flush();
      } catch (e) {
        print('Error when adding to controller: $e');
      } finally {
        controller.close();
      }
    } on SocketException catch (e) {
      throw TimeoutException('Socket write timed out', timeout);
    }
  }

  void close() {
    socket?.close();
  }

  Future<List<int>> fillBuf2(
      SocketWrapper socketwrapper, List<int> recvBuf, int n,
      {Duration? timeout}) async {
    final maxTime = timeout != null ? DateTime.now().add(timeout) : null;

    await for (var data in socketwrapper.socket!.cast<List<int>>()) {
      print("DEBUG fillBuf2 1 - new data received: $data");
      if (maxTime != null && DateTime.now().isAfter(maxTime)) {
        throw SocketException('Timeout');
      }

      if (data.isEmpty) {
        if (recvBuf.isNotEmpty) {
          throw SocketException('Connection ended mid-message.');
        } else {
          throw SocketException('Connection ended while awaiting message.');
        }
      }

      recvBuf.addAll(data);
      print(
          "DEBUG fillBuf2 2 - data added to recvBuf, new length: ${recvBuf.length}");

      if (recvBuf.length >= n) {
        print("DEBUG fillBuf2 3 - breaking loop, recvBuf is big enough");
        break;
      }
    }

    return recvBuf;
  }

  Future<List<int>> fillBuf(int n, {Duration? timeout}) async {
    var recvBuf = <int>[];
    socket?.listen((data) {
      print('Received from server: $data');
    }, onDone: () {
      print('Server closed connection.');
      socket?.destroy();
    }, onError: (error) {
      print('Error: $error');
      socket?.destroy();
    });
    return recvBuf;

    StreamSubscription<List<int>>? subscription; // Declaration moved here
    subscription = socket!.listen(
      (List<int> data) {
        recvBuf.addAll(data);
        if (recvBuf.length >= n) {
          subscription?.cancel();
        }
      },
      onError: (e) {
        subscription?.cancel();
        if (e is Exception) {
          throw e;
        } else {
          throw Exception(e ?? 'Error in `subscription` socket!.listen');
        }
      },
      onDone: () {
        print("DEBUG ON DONE");
        if (recvBuf.length < n) {
          throw SocketException(
              'Connection closed before enough data was received');
        }
      },
    );

    if (timeout != null) {
      Future.delayed(timeout, () {
        if (recvBuf.length < n) {
          subscription?.cancel();
          throw SocketException('Timeout');
        }
      });
    }

    return recvBuf;
  }


  Future<List<int>> recv_message2(SocketWrapper socketwrapper, {Duration? timeout}) async {
    print ("START OF RECV2");
    if (timeout == null) {
      timeout = this.timeout;
    }

    final maxTime = timeout != null ? DateTime.now().add(timeout) : null;

    List<int> recvBuf = [];
    int bytesRead = 0;

    print("DEBUG recv_message2 1 - about to read the header");

    try {
      await for (var data in socketwrapper.receiveStream) {
        if (maxTime != null && DateTime.now().isAfter(maxTime)) {
          throw SocketException('Timeout');
        }

        if (data.isEmpty) {
          if (recvBuf.isNotEmpty) {
            throw SocketException('Connection ended mid-message.');
          } else {
            throw SocketException('Connection ended while awaiting message.');
          }
        }

        recvBuf.addAll(data);

        if (bytesRead < 12) {
          bytesRead += data.length;
        }

        if (recvBuf.length >= 12) {
          final magic = recvBuf.sublist(0, 8);

          if (!ListEquality().equals(magic, Connection.magic)) {
            throw BadFrameError('Bad magic in frame: ${hex.encode(magic)}');
          }

          final byteData =
              ByteData.view(Uint8List.fromList(recvBuf.sublist(8, 12)).buffer);
          final messageLength = byteData.getUint32(0, Endian.big);

          if (messageLength > MAX_MSG_LENGTH) {
            throw BadFrameError(
                'Got a frame with msg_length=$messageLength > $MAX_MSG_LENGTH (max)');
          }

          /*
          print("DEBUG recv_message2 3 - about to read the message body, messageLength: $messageLength");

          print("DEBUG recvfbuf len is ");
          print(recvBuf.length);
          print("bytes read is ");
          print(bytesRead);
          print("message length is ");
          print(messageLength);

           */
          if (recvBuf.length == bytesRead && bytesRead == 12 + messageLength) {
            final message = recvBuf.sublist(12, 12 + messageLength);

            //print("DEBUG recv_message2 4 - message received, length: ${message.length}");
            //print("DEBUG recv_message2 5 - message content: $message");
            print ("END OF RECV2");
            return message;
          } else {
            // Throwing exception if the length doesn't match
            throw Exception(
                'Message length mismatch: expected ${12 + messageLength} bytes, received ${recvBuf.length} bytes.');
          }
        }
      }
    } on SocketException catch (e) {
      print('Socket exception: $e');
    }

    // This is a default return in case of exceptions.
    return [];
  }

  Future<List<int>> recv_message({Duration? timeout}) async {
    // DEPRECATED
    return [];
  }
} // END OF CLASS
