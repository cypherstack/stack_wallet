import 'dart:io';
import 'dart:math';

import 'package:fusiondart/src/connection.dart';
import 'package:fusiondart/src/covert.dart';
import 'package:fusiondart/src/covert/covert_connection.dart';
import 'package:fusiondart/src/covert/covert_slot.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/util.dart';
import 'package:protobuf/protobuf.dart';

/// Manages submission of covert tasks.
///
/// This class manages the submission of covert tasks to a server.
class CovertSubmitter {
  final String destAddr;
  final int destPort;
  final bool ssl;
  final ({InternetAddress host, int port}) proxyInfo;
  final int numSlots;
  final int randSpan;
  final int submitTimeout = 0;

  /// A list of slots that can take covert tasks.
  final List<CovertSlot> slots;

  /// More instance variables.
  String? failureException;
  bool stopping = false;
  String? randTag;
  int countFailed = 0;
  int countEstablished = 0;
  int countAttempted = 0;
  final Random rng = Random.secure();
  DateTime? stopTStart;
  List<CovertConnection> spareConnections = [];

  /// Constructor to initialize the CovertSubmitter.
  CovertSubmitter({
    required this.destAddr,
    required this.destPort,
    required this.ssl,
    required this.proxyInfo,
    required this.numSlots,
    required this.randSpan,
    required Duration submitTimeout,
  }) : slots = List<CovertSlot>.generate(
            numSlots, (index) => CovertSlot(submitTimeout));

  /// Wakes all connections for tasks.
  ///
  /// Returns:
  ///  `void`
  void wakeAll() {
    // Wake up all the connections.
    for (CovertSlot s in slots) {
      if (s.covConn != null) {
        // Wake up the connection associated with the slot.
        s.covConn!.wakeupSet();
      }
    }

    // Wake up all the spare connections, too.
    for (CovertConnection c in spareConnections) {
      c.wakeupSet();
    }
  }

  /// Sets the time to stop all tasks.
  void setStopTime(int tStart) {
    // Set the time at which to stop.
    stopTStart = DateTime.fromMillisecondsSinceEpoch(tStart * 1000);

    // Wake up all the connections.
    if (stopping) {
      wakeAll();
    }
  }

  Future<void> killConnections() async {
    for (final spare in spareConnections) {
      try {
        await spare.connection?.close();
      } catch (_) {
        // who cares? continue
      }
    }

    for (final slot in slots) {
      try {
        await slot.covConn?.connection?.close();
      } catch (_) {
        // who cares? continue
      }
    }
  }

  /// Stops all tasks and closes the connections.
  void stop([Exception? exception]) {
    if (stopping) {
      // Already requested!
      return;
    }
    failureException = exception?.toString();
    stopping = true;

    // Calculate the time remaining until the stop time.
    var timeRemaining = stopTStart?.difference(DateTime.now()).inSeconds ?? 0;
    Utilities.debugPrint(
        "Stopping; connections will close in approximately $timeRemaining seconds");

    // Wake up all the connections.
    wakeAll();
  }

  /// Schedules connections for tasks and runs them unawaited.
  void scheduleConnectionsAndStartRunningThem(
    DateTime tStart,
    Duration tSpan, {
    int numSpares = 0,
    Duration connectTimeout = const Duration(seconds: 10),
  }) {
    // Prepare the list to store new connections.
    List<CovertConnection> newConns = <CovertConnection>[];

    // Loop through each slot and initialize a new covert connection if none exists for that slot.
    for (int sNum = 0; sNum < slots.length; sNum++) {
      CovertSlot s = slots[sNum];
      if (s.covConn == null) {
        // Initialize a new covert connection and associate it with the slot.
        s.covConn = CovertConnection()..slotNum = sNum;

        // Add the new connection to the list of new connections.
        newConns.add(s.covConn!);
      }
    }

    // Calculate the number of new spare connections needed.
    int numNewSpares = max(0, numSpares - spareConnections.length);

    // Create new spare connections.
    List<CovertConnection> newSpares =
        List.generate(numNewSpares, (index) => CovertConnection());

    // Update the list of spare connections.
    spareConnections = [...newSpares, ...spareConnections];

    // Add new spare connections to the list of new connections.
    newConns.addAll(newSpares);

    // Holds all the runConnection futures in case we want to return them at some
    // point. For now they are run unawaited.
    final List<Future<void>> runConnectionFutures = [];

    // Loop through each new connection to schedule it.
    for (CovertConnection covConn in newConns) {
      // Assign a unique connection number for tracking.
      covConn.connNumber = countAttempted;

      // Increment the total number of attempted connections.
      countAttempted++;

      // Calculate the specific DateTime to establish this connection.
      DateTime connTime = tStart
          .add(Duration(seconds: (tSpan.inSeconds * randTrap(rng)).round()));

      // Calculate a random delay to add to the connection time.
      final randDelay = Duration(seconds: (randSpan * randTrap(rng).toInt()));

      // Invoke the method to initiate and run the connection unawaited.
      runConnectionFutures.add(
        _runConnection(
          covConn,
          connTime.millisecondsSinceEpoch,
          randDelay,
          connectTimeout,
        ),
      );
    }
  }

  /// Schedules tasks for all available slots.
  void scheduleSubmissions(
    DateTime tStart,
    List<GeneratedMessage?> slotMessages,
  ) {
    // Convert to list (Dart does not have tuples)
    slotMessages = List.from(slotMessages);

    // Ensure that the number of slot messages equals the number of slots
    assert(slotMessages.length == slots.length);

    // First, notify the spare connections that they will need to make a ping.
    // Note that Dart does not require making a copy of the list before iteration,
    // since Dart does not support mutation during iteration.
    for (CovertConnection c in spareConnections) {
      c.tPing = tStart;
      c.wakeupSet();
    }

    // Then, notify the slots that there is a message to submit.
    for (int i = 0; i < slots.length; i++) {
      CovertSlot slot = slots[i];
      GeneratedMessage? subMsg = slotMessages[i];
      CovertConnection? covConn = slot.covConn;

      if (covConn != null) {
        if (subMsg == null) {
          covConn.tPing = tStart;
        } else {
          slot.subMsg = subMsg;
          slot.tSubmit = tStart;
        }
        covConn.wakeupSet();
      }
    }
  }

  /// Runs a connection thread for the provided covert connection.
  Future<void> _runConnection(
    CovertConnection covConn,
    int connTime,
    Duration randDelay,
    Duration connectTimeout,
  ) async {
    // Main loop for connection thread
    DateTime connDateTime =
        DateTime.fromMillisecondsSinceEpoch(connTime * 1000);
    while (await covConn.waitWakeupOrTime(connDateTime)) {
      // if we are woken up before connection and stopping is happening, then just don't make a connection at all
      if (stopping) {
        return;
      }

      // Note the time at which the connection was established.
      final tBegin = DateTime.now().millisecondsSinceEpoch;

      try {
        // STATE 1 - connecting
        // Increment the total number of attempted connections.
        limiter.bump();

        Utilities.debugPrint("STATE 1: limiter.count=${limiter.count}");

        // Attempt to open a connection.
        try {
          Utilities.debugPrint(
              "STATE 1: Connection.openConnection START slotNum=${covConn.slotNum}");
          final connection = await Connection.openConnection(
            host: destAddr,
            port: destPort,
            connTimeout: connectTimeout,
            ssl: ssl,
            proxyInfo: proxyInfo,
          );
          covConn.connection = connection;
          Utilities.debugPrint(
              "STATE 1: Connection.openConnection DONE slotNum=${covConn.slotNum}");
        } catch (e) {
          // Connection failed.

          // Increment the total number of failed connections.
          countFailed++;

          // Note the time at which the connection failed.
          final tEnd = DateTime.now().millisecondsSinceEpoch;

          Utilities.debugPrint(
              'could not establish connection (after ${((tEnd - tBegin) / 1000).toStringAsFixed(3)}s): $e');
          rethrow;
        }

        // Connection succeeded.

        // Increment the total number of established connections.
        countEstablished++;

        // Note the time at which the connection was established.
        final tEnd = DateTime.now().millisecondsSinceEpoch;
        Utilities.debugPrint(
            '[${covConn.connNumber}] connection established after ${((tEnd - tBegin) / 1000).toStringAsFixed(3)}s');

        // Set the ping time for the connection.
        covConn.delay = randTrap(rng) * randSpan;

        // Note the time at which the ping was sent.
        // Assigned but not used.
        // int lastActionTime = DateTime.now().millisecondsSinceEpoch;

        // STATE 2 - Working.
        while (!stopping) {
          Utilities.debugPrint("STATE 2 - Working");
          DateTime? nextTime;
          final slotNum = covConn.slotNum;
          Function? action; // Callback to hold the action function.

          // Second preference: submit something.
          if (slotNum != null) {
            CovertSlot slot = slots[slotNum];
            nextTime = slot.tSubmit;
            action = slot.submit;
          }
          // Third preference: send a ping.
          if (nextTime == null && covConn.tPing != null) {
            nextTime = covConn.tPing;
            action = covConn.ping;
          }
          // Last preference: wait doing nothing.
          if (nextTime == null) {
            nextTime = DateTime.now()
                .add(Duration(seconds: TIMEOUT_INACTIVE_CONNECTION));
            action = covConn.inactive;
          }

          // Add a random delay to the next time.
          nextTime = nextTime.add(randDelay);

          Utilities.debugPrint("STATE 2 - Wait until the next time.");
          // Wait until the next time.
          if (await covConn.waitWakeupOrTime(nextTime)) {
            // Got woken up...  Let's go back and reevaluate what to do.

            Utilities.debugPrint(
                "STATE 2 - Got woken up...  Let's go back and reevaluate what to do.");
            continue;
          }

          // Reached action time, time to do it.
          final label = "[${covConn.connNumber}-$slotNum]";

          // Call the action function.
          try {
            Utilities.debugPrint(
                "Calling action ${action.runtimeType} for label=$label");
            await action?.call();
          } catch (e) {
            Utilities.debugPrint("$label error $e");
            rethrow;
          } finally {
            Utilities.debugPrint("$label done");
          }

          // Note the time at which the action was completed.
          // lastActionTime = DateTime.now().millisecondsSinceEpoch;
        }

        // STATE 3 - Stopping.
        while (true) {
          Utilities.debugPrint("STATE 3 - Stopping.");
          // Wait for the stop time or the next wakeup.
          final stopTime = stopTStart?.add(randDelay) ?? DateTime.now();

          // If we are woken up before the stop time, then just don't make a connection at all.
          if (!(await covConn.waitWakeupOrTime(stopTime))) {
            break;
          }
        }

        Utilities.debugPrint("[${covConn.connNumber}] closing from stop");
      } catch (e, s) {
        Utilities.debugPrint(
            "_runConnection EXCEPTION for connNumber=[${covConn.connNumber}]: $e\n$s");

        // In case of any problem, if we have a slot, reassign it.
        final slotNum = covConn.slotNum;
        if (slotNum != null) {
          try {
            final spare = spareConnections.removeLast();
            // Found a spare.
            slots[slotNum].covConn = spare;
            spare.slotNum = slotNum;
            spare.wakeupSet();

            // Clear the slot number for the connection.
            covConn.slotNum = null;
          } catch (e) {
            // We failed, and there are no spares.  Party is over!

            if (e is Exception) {
              // Stop the covert submitter with the exception.
              stop(e);
            } else {
              // Handle the case where the exception is not an instance of Exception.
              stop(Exception("runConnection exception: $e"));
            }
          }
        }
      } finally {
        // Close the connection.

        Utilities.debugPrint(
            "[${covConn.connNumber}] closing in finally block");
        await covConn.connection?.close();
      }
    }
  }

  /// Checks for any failure exceptions and throws them if they exist.
  void checkOk() {
    var e = failureException;
    if (e != null) {
      throw FusionError('Covert connections failed: ${e.runtimeType} $e');
    }
  }

  /// Verifies all slots are connected.
  void checkConnected() {
    checkOk();
    var numMissing = slots.where((s) => s.covConn?.connection == null).length;
    if (numMissing > 0) {
      // throw FusionError(
      //     "Covert connections were too slow ($numMissing incomplete out of ${slots.length}).");
      Utilities.debugPrint(
          "Covert connections were too slow ($numMissing incomplete out of ${slots.length}).  TODO re-enable throw.");
    }
  }

  /// Verifies all submissions are done.
  void checkDone() {
    checkOk();
    int numMissing = slots.where((s) => !s.done).length;
    if (numMissing > 0) {
      // throw FusionError(
      //     "Covert submissions were too slow ($numMissing incomplete out of ${slots.length}).");
      Utilities.debugPrint(
          "Covert submissions were too slow ($numMissing incomplete out of ${slots.length}).  TODO re-enable throw.");
    }
  }
}
