import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/comms.dart';
import 'package:fusiondart/src/covert/covert_connection.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart';
import 'package:protobuf/protobuf.dart';

/// Represents a slot in a covert communication setup.
class CovertSlot {
  /// Constructor that initializes the covert slot with a given submission timeout.
  CovertSlot(this.submitTimeout);

  final Duration submitTimeout;

  bool get done => subMsg == null; // Whether last work requested is done.

  GeneratedMessage? subMsg;
  CovertConnection? covConn;

  /// the time of the last submit action.
  DateTime? tSubmit;

  int cnt = 0;
  int con = 0;
  int slot = 0;
  Type? msg;

  /// Submits the work to be done within the slot.
  Future<void> submit() async {
    // Attempt to get the connection object from the covert connection.
    final connection = covConn!.connection;

    cnt++;
    con = covConn!.connNumber!;
    slot = covConn!.slotNum!;
    msg = subMsg?.runtimeType;

    // Throw an unrecoverable exception if the connection is null.
    if (connection == null) {
      throw Unrecoverable('connection is null');
    }

    final message = CovertMessage();
    switch (subMsg!.runtimeType) {
      case CovertComponent:
        message.component = subMsg as CovertComponent;
      case CovertTransactionSignature:
        message.signature = subMsg as CovertTransactionSignature;
      case Ping:
        message.ping = subMsg as Ping;

      default:
        throw Exception("CTRL+F this error text and see TODO message");
    }

    // Start the work.
    //
    // Send a Protocol Buffers message to initiate the work,
    // and set a timeout based on the submitTimeout property.
    Utilities.debugPrint(
        "###### SENT   cnt=$cnt  conNum=$con    slot=$slot    type=$msg");
    await Comms.sendPb(connection, message, timeout: submitTimeout);
    try {
      // throws on error ( aka if not 'ok' )
      Utilities.debugPrint(
          "###### RECEIVE   cnt=$cnt  conNum=$con    slot=$slot    type=$msg");
      await Comms.recvPb(
        ['ok'],
        connection: connection,
        covert: true,
        timeout: submitTimeout,
      );
    } catch (e) {
      Utilities.debugPrint(
          "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
      Utilities.debugPrint("Covert.submit msg type = ${subMsg?.runtimeType}");
      Utilities.debugPrint("Slot num               = ${covConn?.slotNum}");
      Utilities.debugPrint("conn num               = ${covConn?.connNumber}");
      Utilities.debugPrint(
          "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");

      rethrow;
    } finally {
      // Set to null to indicate that the work has been completed.
      subMsg = null;

      tSubmit = null;

      // Reset the ping time for the associated covert connection.
      // If a submission has been successfully made, no ping is needed.
      covConn!.tPing = null; // if a submission is done, no ping is needed.
    }
  }
}
