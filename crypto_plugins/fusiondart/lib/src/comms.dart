import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fusiondart/src/connection.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart' as pb;
import 'package:fusiondart/src/protocol.dart';
import 'package:fusiondart/src/receive_messages.dart';
import 'package:protobuf/protobuf.dart';

abstract final class Comms {
  static Future<void> sendPb(
    Connection connection,
    GeneratedMessage pbMessage, {
    Duration? timeout,
  }) async {
    // Convert the Protobuf message to bytes.
    final msgBytes = pbMessage.writeToBuffer();

    try {
      // Send the message through the connection.
      await connection.sendMessage(msgBytes, timeout: timeout);
    } on SocketException {
      throw FusionError('Connection closed by remote');
    } on TimeoutException {
      throw FusionError('Timed out during send');
    } catch (e) {
      throw FusionError('Communications error: ${e.runtimeType}: $e');
    }
  }

  /// Receive a Protobuf message from the server.
  static Future<GeneratedMessage> recvPb(
    List<String> expectedFieldNames, {
    required bool covert,
    required Connection connection,
    Duration? timeout,
  }) async {
    try {
      // Receive the message blob from the server.
      List<int> blob = await connection.recvMessage(timeout: timeout);

      // Deserialize the blob into a protocol buffer message.
      final pbMessage = covert
          ? CovertResponse.fromBuffer(blob)
          : ServerMessage.fromBuffer(blob);
      if (!pbMessage.isInitialized()) {
        throw FusionError('Incomplete message received');
      }

      // Check for the presence of expected fields.
      for (String name in expectedFieldNames) {
        final fieldInfo = pbMessage.info_.byName[name];

        if (fieldInfo == null) {
          throw FusionError('Expected field not found in message: $name');
        }

        // Check if the field is present in the message.
        if (pbMessage.hasField(fieldInfo.tagNumber)) {
          return pbMessage;
        }
      }

      // check for errors
      final errorFieldInfo = pbMessage.info_.byName[ReceiveMessages.error];
      if (errorFieldInfo != null) {
        final error = pbMessage.getField(errorFieldInfo.tagNumber) as pb.Error;

        throw FusionError("Server error: \"${error.message}\"");
      }

      throw FusionError(
        'None of the expected fields found in the received message',
      );
    } catch (e) {
      if (e is SocketException) {
        throw FusionError('Connection closed by remote');
      } else if (e is InvalidProtocolBufferException) {
        throw FusionError('Message decoding error: $e');
      } else if (e is TimeoutException) {
        throw FusionError('Timed out during receive');
      } else if (e is OSError && e.errorCode == 9) {
        throw FusionError('Connection closed by local');
      } else {
        rethrow;
      }
    }
  }

  /// Greet the server.
  ///
  /// Sends a ClientHello message to the server and waits for a ServerHello
  /// message in reply.
  static Future<
      ({
        int numComponents,
        int componentFeeRate,
        int minExcessFee,
        int maxExcessFee,
        List<int> availableTiers,
      })> greet({
    required Connection connection,
    required Uint8List genesisHash,
  }) async {
    // Create the ClientHello message with version and genesis hash.
    final clientHello = ClientHello(
      version: Uint8List.fromList(utf8.encode(Protocol.VERSION)),
      genesisHash: genesisHash,
    );

    // Wrap the ClientHello in a ClientMessage.
    ClientMessage clientMessage = ClientMessage()..clienthello = clientHello;

    // Send the message to the server.
    await sendPb(
      connection,
      clientMessage,
    );

    // Wait for a ServerHello message in reply.
    GeneratedMessage replyMsg = await recvPb(
      [ReceiveMessages.serverHello],
      connection: connection,
      covert: false,
    );

    // Process the ServerHello message.
    if (replyMsg is ServerMessage) {
      ServerHello reply = replyMsg.serverhello;

      // Extract and set various server parameters.
      final numComponents = reply.numComponents;
      final componentFeeRate = reply.componentFeerate.toInt();
      final minExcessFee = reply.minExcessFee.toInt();
      final maxExcessFee = reply.maxExcessFee.toInt();
      final availableTiers = reply.tiers.map((tier) => tier.toInt()).toList();

      // Enforce some sensible limits, in case server is crazy
      if (componentFeeRate > Protocol.MAX_COMPONENT_FEERATE) {
        throw FusionError('excessive component feerate from server');
      }
      if (minExcessFee > 400) {
        // note this threshold should be far below MAX_EXCESS_FEE.
        throw FusionError('excessive min excess fee from server');
      }
      if (minExcessFee > maxExcessFee) {
        throw FusionError('bad config on server: fees');
      }
      if (numComponents < Protocol.MIN_TX_COMPONENTS * 1.5) {
        throw FusionError('bad config on server: num_components');
      }

      return (
        numComponents: numComponents,
        componentFeeRate: componentFeeRate,
        minExcessFee: minExcessFee,
        maxExcessFee: maxExcessFee,
        availableTiers: availableTiers,
      );
    } else {
      throw Exception(
          'Received unexpected message type: ${replyMsg.runtimeType}');
    }
  }
}
