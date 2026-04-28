import 'dart:async';

import 'package:fusiondart/src/comms.dart';
import 'package:fusiondart/src/connection.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart';

/// Represents a covert connection.
class CovertConnection {
  Connection? connection;
  int? slotNum;
  DateTime? tPing;
  int? connNumber;
  Completer<bool> _wakeup = Completer();
  double? delay;

  void wakeupSet() {
    if (_wakeup.isCompleted) {
      _wakeup = Completer();
    }
    _wakeup.complete(true);
  }

  /// Waits for the connection to wake up or for a timeout.
  Future<bool> waitWakeupOrTime(DateTime? t) async {
    // Check `t`'s validity.
    if (t == null) {
      return false;
    }

    // Calculate the remaining time until `t`.
    int remTime = t.difference(DateTime.now()).inMilliseconds;
    remTime = remTime > 0 ? remTime : 0;

    // wait for the first one of the following futures to complete
    await Future.any([
      Future<void>.delayed(Duration(milliseconds: remTime)).then((_) {
        if (!_wakeup.isCompleted) {
          _wakeup.complete(false);
        }
      }),
      _wakeup.future,
    ]);

    // Return whether the connection was woken up.
    final wasSet = await _wakeup.future;
    _wakeup = Completer();
    return wasSet;
  }

  /// Sends a ping message to keep the connection alive.
  void ping() {
    // If the connection exists, send a `Ping` message.
    if (connection != null) {
      Comms.sendPb(
        connection!,
        CovertMessage()..ping = Ping(),
        timeout: Duration(seconds: 1),
      );
    }

    // Reset the ping time, as a ping has just been sent.
    tPing = null;
  }

  /// Indicates the connection is inactive and throws an unrecoverable error.
  void inactive() {
    throw Unrecoverable("Timed out from inactivity (this is a bug!)");
  }
}
