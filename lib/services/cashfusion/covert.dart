import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:protobuf/protobuf.dart' as pb;

import 'comms.dart';
import 'connection.dart';
import 'fusion.pb.dart';

const int TOR_COOLDOWN_TIME = 660;
const int TIMEOUT_INACTIVE_CONNECTION = 120;

class FusionError implements Exception {
  String cause;
  FusionError(this.cause);
}

class Unrecoverable extends FusionError {
  Unrecoverable(String cause) : super(cause);
}

Future<bool> isTorPort(String host, int port) async {
  if (port < 0 || port > 65535) {
    return false;
  }

  try {
    Socket sock =
        await Socket.connect(host, port, timeout: Duration(milliseconds: 100));
    sock.write("GET\n");
    List<int> data = await sock.first;
    sock.destroy();
    if (utf8.decode(data).contains("Tor is not an HTTP Proxy")) {
      return true;
    }
  } on SocketException {
    return false;
  }

  return false;
}

class TorLimiter {
  Queue<DateTime> deque = Queue<DateTime>();
  int lifetime;
  // Declare a lock here, may need a special Dart package for this
  int _count = 0;

  TorLimiter(this.lifetime);

  void cleanup() {}

  int get count {
    // return some default value for now
    return 0;
  }

  void bump() {}
}

TorLimiter limiter = TorLimiter(TOR_COOLDOWN_TIME);

double randTrap(Random rng) {
  final sixth = 1.0 / 6;
  final f = rng.nextDouble();
  final fc = 1.0 - f;

  if (f < sixth) {
    return sqrt(0.375 * f);
  } else if (fc < sixth) {
    return 1.0 - sqrt(0.375 * fc);
  } else {
    return 0.75 * f + 0.125;
  }
}

class CovertConnection {
  Connection? connection; // replace dynamic with the type of your connection
  int? slotNum;
  DateTime? tPing;
  int? connNumber;
  Completer wakeup = Completer();
  double? delay;

  Future<bool> waitWakeupOrTime(DateTime? t) async {
    if (t == null) {
      return false;
    }

    var remTime = t.difference(DateTime.now()).inMilliseconds;
    remTime = remTime > 0 ? remTime : 0;

    await Future.delayed(Duration(milliseconds: remTime));
    wakeup.complete(true);

    var wasSet = await wakeup.future;
    wakeup = Completer();
    return wasSet;
  }

  void ping() {
    if (this.connection != null) {
      sendPb(this.connection!, CovertMessage, Ping(),
          timeout: Duration(seconds: 1));
    }

    this.tPing = null;
  }

  void inactive() {
    throw Unrecoverable("Timed out from inactivity (this is a bug!)");
  }
}

class CovertSlot {
  int submitTimeout;
  pb.GeneratedMessage? subMsg; // The work to be done.
  bool done; // Whether last work requested is done.
  CovertConnection?
      covConn; // which CovertConnection is assigned to work on this slot
  CovertSlot(this.submitTimeout) : done = true;
  DateTime? t_submit;

  // Define a getter for tSubmit
  DateTime? get tSubmit => t_submit;

  Future<void> submit() async {
    var connection = covConn?.connection;

    if (connection == null) {
      throw Unrecoverable('connection is null');
    }

    await sendPb(connection, CovertMessage, subMsg!,
        timeout: Duration(seconds: submitTimeout));
    var result = await recvPb(connection, CovertResponse, ['ok', 'error'],
        timeout: Duration(seconds: submitTimeout));

    if (result.item1 == 'error') {
      throw Unrecoverable('error from server: ${result.item2}');
    }
    done = true;
    t_submit = DateTime.fromMillisecondsSinceEpoch(0);
    covConn?.tPing = DateTime.fromMillisecondsSinceEpoch(
        0); // if a submission is done, no ping is needed.
  }
}

class PrintError {
  // Declare properties here
}

class CovertSubmitter extends PrintError {
  // Declare properties here
  List<CovertSlot> slots;
  bool done = true;
  String failure_exception = "";
  int num_slots;

  bool stopping = false;
  Map<String, dynamic>? proxyOpts;
  String? randtag;
  String? destAddr;
  int? destPort;
  bool ssl = false;
  Object lock = Object();
  int countFailed = 0;
  int countEstablished = 0;
  int countAttempted = 0;
  Random rng = Random.secure();
  int? randSpan;
  DateTime? stopTStart;
  List<CovertConnection> spareConnections = [];
  String? failureException;
  int submit_timeout = 0;

  CovertSubmitter(
      String dest_addr,
      int dest_port,
      bool ssl,
      String tor_host,
      int tor_port,
      this.num_slots,
      double randSpan, // changed from int to double
      double submit_timeout) // changed from int to double
      : slots = List<CovertSlot>.generate(
            num_slots, (index) => CovertSlot(submit_timeout.toInt())) {
    // constructor body...
  }

  void wakeAll() {
    for (var s in slots) {
      if (s.covConn != null) {
        s.covConn!.wakeup.complete();
      }
    }
    for (var c in spareConnections) {
      c.wakeup.complete();
    }
  }

  void setStopTime(int tstart) {
    this.stopTStart = DateTime.fromMillisecondsSinceEpoch(tstart * 1000);
    if (this.stopping) {
      this.wakeAll();
    }
  }

  void stop([Exception? exception]) {
    if (this.stopping) {
      // already requested!
      return;
    }
    this.failureException = exception?.toString();
    this.stopping = true;
    var timeRemaining =
        this.stopTStart?.difference(DateTime.now()).inSeconds ?? 0;
    print(
        "Stopping; connections will close in approximately $timeRemaining seconds");
    this.wakeAll();
  }

// PYTHON USES MULTITHREADING, WHICH ISNT IMPLEMENTED HERE YET
  void scheduleConnections(DateTime tStart, Duration tSpan,
      {int numSpares = 0, int connectTimeout = 10}) {
    var newConns = <CovertConnection>[];

    for (var sNum = 0; sNum < this.slots.length; sNum++) {
      var s = this.slots[sNum];
      if (s.covConn == null) {
        s.covConn = CovertConnection();
        s.covConn?.slotNum = sNum;
        CovertConnection? myCovConn = s.covConn;
        if (myCovConn != null) {
          newConns.add(myCovConn);
        }
      }
    }

    var numNewSpares = max(0, numSpares - this.spareConnections.length);
    var newSpares = List.generate(numNewSpares, (index) => CovertConnection());
    this.spareConnections = [...newSpares, ...this.spareConnections];

    newConns.addAll(newSpares);

    for (var covConn in newConns) {
      covConn.connNumber = this.countAttempted;
      this.countAttempted++;
      var connTime = tStart.add(
          Duration(seconds: (tSpan.inSeconds * randTrap(this.rng)).round()));
      var randDelay = (this.randSpan ?? 0) * randTrap(this.rng);

      runConnection(
          covConn, connTime.millisecondsSinceEpoch, randDelay, connectTimeout);
    }
  }

  void scheduleSubmit(int slotNum, DateTime tStart, dynamic subMsg) {
    var slot = slots[slotNum];

    assert(slot.done, "tried to set new work when prior work not done");

    slot.subMsg = subMsg;
    slot.done = false;
    slot.t_submit = tStart;
    var covConn = slot.covConn;
    if (covConn != null) {
      covConn.wakeup.complete();
    }
  }

  void scheduleSubmissions(DateTime tStart, List<dynamic> slotMessages) {
    // Convert to list (Dart does not have tuples)
    slotMessages = List.from(slotMessages);

    // Ensure that the number of slot messages equals the number of slots
    assert(slotMessages.length == slots.length);

    // First, notify the spare connections that they will need to make a ping.
    // Note that Dart does not require making a copy of the list before iteration,
    // since Dart does not support mutation during iteration.
    for (var c in spareConnections) {
      c.tPing = tStart;
      c.wakeup.complete();
    }

    // Then, notify the slots that there is a message to submit.
    for (var i = 0; i < slots.length; i++) {
      var slot = slots[i];
      var subMsg = slotMessages[i];
      var covConn = slot.covConn;

      if (covConn != null) {
        if (subMsg == null) {
          covConn.tPing = tStart;
        } else {
          slot.subMsg = subMsg;
          slot.done = false;
          slot.t_submit = tStart;
        }
        covConn.wakeup.complete();
      }
    }
  }

  Future runConnection(CovertConnection covConn, int connTime, double randDelay,
      int connectTimeout) async {
    // Main loop for connection thread
    DateTime connDateTime =
        DateTime.fromMillisecondsSinceEpoch(connTime * 1000);
    while (await covConn.waitWakeupOrTime(connDateTime)) {
      // if we are woken up before connection and stopping is happening, then just don't make a connection at all
      if (this.stopping) {
        return;
      }

      final tBegin = DateTime.now().millisecondsSinceEpoch;

      try {
        // STATE 1 - connecting
        Map<String, dynamic> proxyOpts;

        if (this.proxyOpts == null) {
          proxyOpts = {};
        } else {
          final unique = 'CF${this.randtag}_${covConn.connNumber}';
          proxyOpts = {
            'proxy_username': unique,
            'proxy_password': unique,
          };
          proxyOpts.addAll(this.proxyOpts!);
        }

        limiter.bump();

        try {
          final connection = await openConnection(
              this.destAddr!, this.destPort!,
              connTimeout: connectTimeout.toDouble(),
              ssl: this.ssl,
              socksOpts: proxyOpts);
          covConn.connection = connection;
        } catch (e) {
          this.countFailed++;

          final tEnd = DateTime.now().millisecondsSinceEpoch;

          print(
              'could not establish connection (after ${((tEnd - tBegin) / 1000).toStringAsFixed(3)}s): $e');
          rethrow;
        }

        this.countEstablished++;

        final tEnd = DateTime.now().millisecondsSinceEpoch;

        print(
            '[${covConn.connNumber}] connection established after ${((tEnd - tBegin) / 1000).toStringAsFixed(3)}s');

        covConn.delay = (randTrap(this.rng) ?? 0) * (this.randSpan ?? 0);

        var lastActionTime = DateTime.now().millisecondsSinceEpoch;

        // STATE 2 - working
        while (!this.stopping) {
          DateTime? nextTime;
          final slotNum = covConn.slotNum;
          Function()? action; // callback to hold the action function

          // Second preference: submit something
          if (slotNum != null) {
            CovertSlot slot = this.slots[slotNum];
            nextTime = slot.tSubmit;
            action = slot.submit;
          }
          // Third preference: send a ping
          if (nextTime == null && covConn.tPing != null) {
            nextTime = covConn.tPing;
            action = covConn.ping;
          }
          // Last preference: wait doing nothing
          if (nextTime == null) {
            nextTime = DateTime.now()
                .add(Duration(seconds: TIMEOUT_INACTIVE_CONNECTION));
            action = covConn.inactive;
          }

          nextTime = nextTime.add(Duration(seconds: randDelay.toInt()));

          if (await covConn.waitWakeupOrTime(nextTime)) {
            // got woken up ... let's go back and reevaluate what to do
            continue;
          }

          // reached action time, time to do it
          final label = "[${covConn.connNumber}-$slotNum]";
          try {
            await action?.call();
          } catch (e) {
            print("$label error $e");
            rethrow;
          } finally {
            print("$label done");
          }

          lastActionTime = DateTime.now().millisecondsSinceEpoch;
        }

        // STATE 3 - stopping
        while (true) {
          final stopTime =
              this.stopTStart?.add(Duration(seconds: randDelay.toInt())) ??
                  DateTime.now();

          if (!(await covConn.waitWakeupOrTime(stopTime))) {
            break;
          }
        }

        print("[${covConn.connNumber}] closing from stop");
      } catch (e) {
        // in case of any problem, record the exception and if we have a slot, reassign it.
        final exception = e;

        final slotNum = covConn.slotNum;
        if (slotNum != null) {
          try {
            final spare = this.spareConnections.removeLast();
            // Found a spare.
            this.slots[slotNum].covConn = spare;
            spare.slotNum = slotNum;
            spare.wakeup
                .complete(); // python code is using set, possibly dealing wiht multi thread...double check this is ok.

            covConn.slotNum = null;
          } catch (e) {
            // We failed, and there are no spares. Party is over!

            if (exception is Exception) {
              this.stop(exception);
            } else {
              // Handle the case where the exception is not an instance of Exception
            }
          }
        }
      } finally {
        covConn.connection?.close();
      }
    }
  }

  void checkOk() {
    // Implement checkOk logic here
    var e = this.failure_exception;
    if (e != null) {
      throw FusionError('Covert connections failed: ${e.runtimeType} $e');
    }
  }

  void checkConnected() {
    // Implement checkConnected logic here
    this.checkOk();
    var numMissing =
        this.slots.where((s) => s.covConn?.connection == null).length;
    if (numMissing > 0) {
      throw FusionError(
          "Covert connections were too slow ($numMissing incomplete out of ${this.slots.length}).");
    }
  }

  void checkDone() {
    // Implement checkDone logic here
    this.checkOk();
    var numMissing = this.slots.where((s) => !s.done).length;
    if (numMissing > 0) {
      throw FusionError(
          "Covert submissions were too slow ($numMissing incomplete out of ${this.slots.length}).");
    }
  }
}
