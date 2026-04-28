import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:coin/coin.dart' as coin;
import 'package:fixnum/fixnum.dart';
import 'package:fusiondart/src/comms.dart';
import 'package:fusiondart/src/connection.dart';
import 'package:fusiondart/src/covert/covert_submitter.dart';
import 'package:fusiondart/src/encrypt.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_big_int.dart';
import 'package:fusiondart/src/extensions/on_list_int.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/models/address.dart';
import 'package:fusiondart/src/models/blind_signature_request.dart';
import 'package:fusiondart/src/models/output.dart';
import 'package:fusiondart/src/models/transaction.dart';
import 'package:fusiondart/src/models/utxo_dto.dart';
import 'package:fusiondart/src/output_handling.dart';
import 'package:fusiondart/src/protobuf/fusion.pb.dart';
import 'package:fusiondart/src/protocol.dart';
import 'package:fusiondart/src/receive_messages.dart';
import 'package:fusiondart/src/status.dart';
import 'package:fusiondart/src/util.dart';
import 'package:fusiondart/src/validation.dart';
import 'package:protobuf/protobuf.dart';

enum FusionMode { normal, fanout, consolidate }

final class FusionParams {
  /// CashFusion server host.
  ///
  /// Should default to Electron Cash's default: `fusion.servo.cash`.
  final String serverHost;

  /// CashFusion server port.
  ///
  /// Should default to Electron Cash's default: `8789`.
  final int serverPort;

  /// Should SSL be used to connect to the CashFusion server?
  final bool serverSsl;

  final Uint8List genesisHash;

  final FusionMode mode;

  /// Should Tor be used for typically-over connections?
  final bool torForOvert;

  final bool enableDebugPrint;

  FusionParams({
    required this.serverHost,
    required this.serverPort,
    required this.serverSsl,
    required String genesisHashHex,
    required this.mode,
    required this.torForOvert,
    this.enableDebugPrint = false,
  }) : genesisHash = Uint8List.fromList(
          genesisHashHex.toUint8ListFromHex.reversed.toList(),
        ) {
    Utilities.enableDebugPrint = enableDebugPrint;
  }
}

class Fusion {
  final FusionParams _fusionParams;

  // Private late finals used for dependency injection.
  late final Future<List<Map<String, dynamic>>> Function(String address)
      _getTransactionsByAddress;
  late final Future<List<Address>> Function(int numberOfAddresses)
      _getUnusedReservedChangeAddresses;
  late final Future<({InternetAddress host, int port})> Function()
      _getSocksProxyAddress;
  late final Future<int> Function() _getChainHeight;
  late final void Function({required FusionStatus status, String? info})
      _updateStatusCallback;
  late final Future<Map<String, dynamic>> Function(String txid)
      _getTransactionJson;
  late final Future<Uint8List> Function(List<int> pubKey)
      _getPrivateKeyForPubKey;
  late final Future<String> Function(String txHex) _broadcastTransaction;
  late final Future<void> Function(List<Address> addresses) _unReserveAddresses;
  late final Future<bool> Function(String, String, int) _checkUtxoExists;

  Fusion(this._fusionParams);

  /// Method to initialize Fusion instance with necessary wallet methods.
  Future<void> initFusion({
    required final Future<List<Map<String, dynamic>>> Function(String address)
        getTransactionsByAddress,
    required final Future<List<Address>> Function(int numberOfAddresses)
        getUnusedReservedChangeAddresses,
    required final Future<({InternetAddress host, int port})> Function()
        getSocksProxyAddress,
    required final Future<int> Function() getChainHeight,
    required final void Function({required FusionStatus status, String? info})
        updateStatusCallback,
    required final Future<Map<String, dynamic>> Function(String txid)
        getTransactionJson,
    required final Future<Uint8List> Function(List<int> pubKey)
        getPrivateKeyForPubKey,
    required final Future<String> Function(String txHex) broadcastTransaction,
    required final Future<void> Function(List<Address> addresses)
        unReserveAddresses,
    required final Future<bool> Function(String, String, int) checkUtxoExists,
  }) async {
    _getTransactionsByAddress = getTransactionsByAddress;
    _getUnusedReservedChangeAddresses = getUnusedReservedChangeAddresses;
    _getSocksProxyAddress = getSocksProxyAddress;
    _getChainHeight = getChainHeight;
    _updateStatusCallback = updateStatusCallback;
    _getTransactionJson = getTransactionJson;
    _getPrivateKeyForPubKey = getPrivateKeyForPubKey;
    _broadcastTransaction = broadcastTransaction;
    _unReserveAddresses = unReserveAddresses;
    _checkUtxoExists = checkUtxoExists;

    // Load coin library.
    await coin.initCoin();
  }

  ///
  /// Current status of the fusion process
  ///
  ({FusionStatus status, String info}) get status => _status;
  late ({FusionStatus status, String info}) _status;
  void _updateStatus({
    required FusionStatus status,
    required String info,
  }) {
    _status = (status: status, info: info);
    _updateStatusCallback(status: status, info: info);

    Utilities.debugPrint(
        "======= FusionStatus update ====================================");
    Utilities.debugPrint("=~ Status: $status");
    Utilities.debugPrint("=~   info: $info");
    Utilities.debugPrint(
        "================================================================");
  }

  /// Have we connected to the server?
  // Assigned but not used.
  // bool _serverConnectedAndGreeted = false;

  Completer<void>? _stopCompleter;
  bool _stopRequested = false;

  ({
    int numComponents,
    int componentFeeRate,
    int minExcessFee,
    int maxExcessFee,
    List<int> availableTiers,
  })? _serverParams;

  ({
    List<UtxoDTO> inputs,
    Map<int, List<int>> tierOutputs,
    BigInt safetySumIn,
    Map<int, int> safetyExcessFees,
  })? _allocatedOutputs;

  ({
    int tier,
    int covertPort,
    bool covertSSL,
    Uint8List covertDomainB,
    double beginTime,
    List<Output> outputs,
    List<int> lastHash,
  })? _registerAndWaitResult;

  /// List of reserved addresses.
  List<Address> _reservedAddresses = <Address>[];

  /// The time when Fusion began.
  DateTime _tFusionBegin = DateTime.now();

  static const INACTIVE_TIME_LIMIT = Duration(minutes: 10);

  /// Maturity for coinbase UTXOs.
  static const int COINBASE_MATURITY = 100;
  // https://github.com/Electron-Cash/Electron-Cash/blob/48ac434f9c7d94b335e1a31834ee2d7d47df5802/electroncash/bitcoin.py#L65

  /// Outputs to allocate for fusion.
  static const int DEFAULT_MAX_COINS = 20;
  // https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash_plugins/fusion/plugin.py#L68

  /// For semi-linked addresses (that share txids in their history), allow linking them with this probability.
  static const double KEEP_LINKED_PROBABILITY = 0.1;
  // https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash_plugins/fusion/plugin.py#L62

  /// Guess that expected number of coins in wallet in equilibrium is = (this number) / fraction
  static const COIN_FRACTION_FUDGE_FACTOR = 10;
  // https://github.com/Electron-Cash/Electron-Cash/blob/48ac434f9c7d94b335e1a31834ee2d7d47df5802/electroncash_plugins/fusion/plugin.py#L60

  // /// Not currently used. If needed, this should be made private and accessed using set/get
  // bool autofuseCoinbase = false; //   link to a setting in the wallet.
  // https://github.com/Electron-Cash/Electron-Cash/blob/48ac434f9c7d94b335e1a31834ee2d7d47df5802/electroncash_plugins/fusion/conf.py#L68

  /// Executes the fusion operation.
  ///
  /// This method orchestrates the entire lifecycle of a CashFusion operation.
  Future<void> fuse({
    required List<UtxoDTO> inputsFromWallet,
    required coin.Chain network,
  }) async {
    Utilities.debugPrint("DEBUG FUSION 223...fusion run....");

    // new stopping completer
    _stopCompleter = Completer();

    _stopRequested = false;

    String? txid;

    /// Number runRound calls
    int roundCount = 0;

    // set connecting state if not already done
    _updateStatus(
        status: FusionStatus.connecting,
        info: "Connecting to the CashFusion server.");

    try {
      if (inputsFromWallet.isEmpty) {
        throw FusionError('Started with no coins');
      }
    } catch (e, s) {
      Utilities.debugPrint("$e\n$s");
      return;
    }

    Connection? connection;

    try {
      // Check if can connect to Tor proxy, if not, raise FusionError.
      try {
        await _getSocksProxyAddress();
      } catch (e) {
        throw FusionError("Can't connect to Tor proxy");
      }

      if (_checkStop(connection, null)) {
        return;
      }

      // Connect to server.
      try {
        connection = await Connection.openConnection(
          host: _fusionParams.serverHost,
          port: _fusionParams.serverPort,
          connTimeout: Duration(seconds: 5),
          defaultTimeout: Duration(seconds: 5),
          ssl: _fusionParams.serverSsl,
          proxyInfo:
              _fusionParams.torForOvert ? await _getSocksProxyAddress() : null,
        );
      } catch (e, s) {
        _updateStatus(
            status: FusionStatus.failed,
            info: "Failed to connect to the server!  Please try again.");
        Utilities.debugPrint("Connect failed: $e");
        Utilities.debugPrint(s);
        String sslStr = _fusionParams.serverSsl ? ' SSL ' : '';
        throw FusionError(
          "Could not connect to "
          "$sslStr${_fusionParams.serverHost}:${_fusionParams.serverPort}",
        );
      }

      if (_checkStop(connection, null)) {
        return;
      }

      // Once connection is successful, wrap operations inside this block.
      //
      // Within this block, version checks, downloads server params, handles coins and runs rounds.
      try {
        // Version check and download server params.
        try {
          _serverParams = await Comms.greet(
            connection: connection,
            genesisHash: _fusionParams.genesisHash,
          );
        } catch (e, s) {
          Utilities.debugPrint("Exception greeting server: $e");
          Utilities.debugPrint("$s");
          rethrow;
        }

        // _serverConnectedAndGreeted = true;

        // In principle we can hook a pause in here -- user can insert coins after seeing server params.
        // If this can/will be done then this function should be broken in two

        if (_checkStop(connection, null)) {
          return;
        }

        final currentChainHeight = await _getChainHeight();

        // Allocate outputs for fusion.
        _updateStatus(
            status: FusionStatus.setup, info: "Allocating inputs for fusion.");

        try {
          _allocatedOutputs = await OutputHandling.allocateOutputs(
            connection: connection,
            // A non-null [connection] would've been caught by IO.greet()'s try-catch above, no need to check or handle it here.
            status: status.status,
            coins: inputsFromWallet,
            currentChainHeight: currentChainHeight,
            serverParams: _serverParams!,
            getTransactionsByAddress: _getTransactionsByAddress,
            mode: _fusionParams.mode,
          );
        } on FusionStopRequested {
          return;
        } catch (e, s) {
          _updateStatus(
              status: FusionStatus.failed,
              info: "Failed to allocate inputs, please try again.");
          Utilities.debugPrint("Exception allocating outputs: $e");
          Utilities.debugPrint("$s");
        }
        // In principle we can hook a pause in here -- user can tweak tier_outputs, perhaps cancelling some unwanted tiers.

        Utilities.debugPrint("Registering for tiers, waiting for a pool...");

        if (_checkStop(connection, null)) {
          return;
        }

        try {
          // Register for tiers, wait for a pool.
          _registerAndWaitResult = await registerAndWait(
            connection: connection,
            allocatedOutputs: _allocatedOutputs!,
            network: network,
          );
        } on FusionStopRequested {
          return;
        }

        if (_checkStop(connection, null)) {
          return;
        }

        Utilities.debugPrint("Starting covert submitter...");

        final CovertSubmitter covert;
        try {
          // launch the covert submitter
          covert = await startCovert(
            connection: connection,
            covertPort: _registerAndWaitResult!.covertPort,
            covertSSL: _registerAndWaitResult!.covertSSL,
            covertDomainB: _registerAndWaitResult!.covertDomainB,
            tFusionBegin: _tFusionBegin,
            serverParams: _serverParams!,
          );
        } on FusionStopRequested {
          return;
        }

        if (_checkStop(connection, covert)) {
          return;
        }
        _updateStatus(
            status: FusionStatus.running, info: "Running fusion rounds.");

        try {
          // Pool started. Keep running rounds until fail or complete.
          while (txid == null) {
            try {
              txid = await runRound(
                roundCount: roundCount,
                covert: covert,
                connection: connection,
                network: network,
              );
              roundCount += 1;
            } catch (e, s) {
              Utilities.debugPrint("runRound failed: $e\n$s");
              _updateStatus(status: FusionStatus.failed, info: "$e");
              rethrow;
            }
          }
        } finally {
          covert.stop();
        }
      } finally {
        try {
          // Close connection.
          await connection.close();
        } catch (e, s) {
          Utilities.debugPrint("Exception closing connection: $e");
          Utilities.debugPrint("$s");
        }
      }

      //  Wait for transaction to show up on the server.
      for (int i = 0; i < 60; i++) {
        if (_stopRequested) {
          break; // not an error
        }

        try {
          // Will throw if tx not found
          await _getTransactionJson(txid);

          break; // tx found
        } catch (_) {
          // tx not found or some other error
          Utilities.debugPrint("Did not get transaction: $_");
        }

        await Future<void>.delayed(Duration(seconds: 1));
      }

      // Set status to 'complete' with txid.
      _updateStatus(status: FusionStatus.complete, info: "Fusion complete.");
    } finally {
      // clearCoins();
      if (status.status != FusionStatus.complete) {
        await _unReserveAddresses(_reservedAddresses);
      }
      if (_stopCompleter?.isCompleted == false) {
        _stopCompleter?.complete();
      }
    }
  } // End of `fuse()`.

  Future<void> stop() async {
    _updateStatus(
      status: FusionStatus.running,
      info: "Stopping fusion.",
    );

    if (_stopRequested) {
      return;
    }
    _stopRequested = true;

    await Future.any([
      Future<void>.delayed(Duration(minutes: 4)),
      _stopCompleter?.future ?? Future(() {}),
    ]);
  }

  /// Checks if the system should stop the current operation.
  ///
  /// This function is periodically called to determine whether the system should
  /// halt its operation.
  bool _checkStop(
    Connection? connection,
    CovertSubmitter? covertSubmitter,
  ) {
    // Gets called occasionally from fusion thread to allow a stop point.

    if (_stopRequested) {
      final List<Future<void>> futures = [];
      if (connection != null) {
        futures.add(connection.close());
      }
      if (covertSubmitter != null) {
        futures.add(covertSubmitter.killConnections());
      }

      Future.wait(futures).then((value) => _stopCompleter!.complete());

      return true;
    }
    return false;
  }

  /// Registers a client to a fusion server and waits for the fusion process to start.
  ///
  /// This method is responsible for the client-side setup and management of the
  /// CashFusion protocol. It sends registration messages to the server,
  /// maintains state, and listens for updates through a [socketWrapper]
  Future<
      ({
        int tier,
        int covertPort,
        bool covertSSL,
        Uint8List covertDomainB,
        double beginTime,
        List<Output> outputs,
        List<int> lastHash,
      })> registerAndWait({
    required Connection connection,
    required ({
      List<UtxoDTO> inputs,
      Map<int, List<int>> tierOutputs,
      BigInt safetySumIn,
      Map<int, int> safetyExcessFees,
    }) allocatedOutputs,
    required coin.Chain network,
  }) async {
    // Initialize a stopwatch to measure elapsed time.
    Stopwatch stopwatch = Stopwatch()..start();

    // Placeholder for messages from the server.
    GeneratedMessage msg;

    // Initialize a map to store the outputs for each tier.
    Map<int, List<int>> tierOutputs = allocatedOutputs.tierOutputs;

    // Sort the tiers in ascending order.
    List<int> tiersSorted = tierOutputs.keys.toList()..sort();

    // Check if tierOutputs is empty and throw an error if so.
    if (tierOutputs.isEmpty) {
      _updateStatus(
          status: FusionStatus.failed,
          info: "Failed to allocate inputs, please try again.");
      throw FusionError(
          'No outputs available at any tier (selected inputs were too small / too large).');
    }

    Utilities.debugPrint('registering for tiers: $tiersSorted');
    _updateStatus(status: FusionStatus.waiting, info: "");

    // Temporary initialization of some CashFusion parameters.
    int selfFuse = 1; // Temporary value for now.
    List<int> cashfusionTag = [1]; // Temporary value for now.

    // Prechecks before proceeding.
    if (_checkStop(connection, null)) {
      throw FusionStopRequested();
    }

    // Prepare tags for joining the pool.
    List<JoinPools_PoolTag> tags = [
      JoinPools_PoolTag(id: cashfusionTag, limit: selfFuse)
    ];

    // Create the JoinPools message.
    JoinPools joinPools =
        JoinPools(tiers: tiersSorted.map((i) => Int64(i)).toList(), tags: tags);

    // Wrap it in a ClientMessage.
    ClientMessage clientMessage = ClientMessage()..joinpools = joinPools;

    // Send the message to the server.
    await Comms.sendPb(
      connection,
      clientMessage,
    );

    _updateStatus(status: FusionStatus.waiting, info: 'Registered for tiers');

    Map<dynamic, String> tiersStrings = {
      for (var entry in tierOutputs.entries)
        entry.key:
            (entry.key * 1e-8).toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '')
    };

    // Main loop to receive updates from the server.
    while (true) {
      Utilities.debugPrint("RECEIVE LOOP 870............DEBUG");
      msg = await Comms.recvPb(
        [
          ReceiveMessages.tierStatusUpdate,
          ReceiveMessages.fusionBegin,
        ],
        connection: connection,
        covert: false,
        timeout: Duration(seconds: 10),
      );

      // Check for a FusionBegin message.
      FieldInfo<dynamic>? fieldInfoFusionBegin =
          msg.info_.byName[ReceiveMessages.fusionBegin];
      if (fieldInfoFusionBegin == null) {
        throw FusionError(
            'Expected field not found in message: $ReceiveMessages.fusionbegin');
      }

      // Validate that the received message is indeed a FusionBegin message.
      final bool messageIsFusionBegin =
          msg.hasField(fieldInfoFusionBegin.tagNumber);
      if (messageIsFusionBegin) {
        Utilities.debugPrint("DEBUG 867 Fusion Begin message...");
        break;
      } /* else {
        throw FusionError('Expected a FusionBegin message');
      }
      */

      // Prechecks before processing the received message.
      if (_checkStop(connection, null)) {
        throw FusionStopRequested();
      }

      // Initialize a variable to store field information for "tierstatusupdate" in the message.
      FieldInfo<dynamic>? fieldInfo =
          msg.info_.byName[ReceiveMessages.tierStatusUpdate];
      // Check if the field exists in the message, if not, throw an error.
      if (fieldInfo == null) {
        throw FusionError(
            'Expected field not found in message: ${ReceiveMessages.tierStatusUpdate}');
      }

      // Determine if the message contains a "TierStatusUpdate"
      final bool messageIsTierStatusUpdate = msg.hasField(fieldInfo.tagNumber);
      Utilities.debugPrint("DEBUG 889 getting tier update.");

      // If the message doesn't contain a "TierStatusUpdate", throw an error.
      if (!messageIsTierStatusUpdate) {
        throw FusionError('Expected a TierStatusUpdate message');
      }

      // Initialize a map to store the statuses from the TierStatusUpdate message.
      final Map<Int64, TierStatusUpdate_TierStatus> statuses;

      // Populate the statuses map if "TierStatusUpdate" exists in the message.
      if (messageIsTierStatusUpdate) {
        /*TierStatusUpdate tierStatusUpdate = msg.tierstatusupdate;*/
        TierStatusUpdate tierStatusUpdate =
            msg.getField(fieldInfo.tagNumber) as TierStatusUpdate;
        statuses = tierStatusUpdate.statuses;
      } else {
        throw Exception("messageIsTierStatusUpdate is false");
      }

      // Utilities.debugPrint("DEBUG 8892 statuses: $statuses.");
      // Utilities.debugPrint("DEBUG 8893 statuses: ${statuses!.entries}.");

      // Initialize variables to store the maximum fraction and tier numbers.
      double maxFraction = 0.0;
      List<int> maxTiers = <int>[];
      int? bestTime;
      int? bestTimeTier;

      // Loop through each entry in statuses to find the maximum fraction and best time.
      for (var entry in statuses.entries) {
        // Calculate the fraction of players to minimum players.
        final double frac = ((entry.value.players.toInt())) /
            ((entry.value.minPlayers.toInt()));

        // Update 'maxFraction' and 'maxTiers' if the current fraction is greater than or equal to the current 'maxFraction'.
        if (frac >= maxFraction) {
          if (frac > maxFraction) {
            maxFraction = frac;
            maxTiers.clear();
          }
          maxTiers.add(entry.key.toInt());
        }

        // // Check if "timeRemaining" field exists and find the smallest time.
        FieldInfo<dynamic>? fieldInfoTimeRemaining =
            entry.value.info_.byName["timeRemaining"];
        /*
        if (fieldInfoTimeRemaining == null) {
          throw FusionError(
              'Expected field not found in message: timeRemaining');
        }
        */

        // Check if the field 'timeRemaining' exists in the current entry.
        if (fieldInfoTimeRemaining != null) {
          // Confirm that the message contains the 'timeRemaining' field.
          if (entry.value.hasField(fieldInfoTimeRemaining.tagNumber)) {
            // Convert 'timeRemaining' to integer
            int tr = entry.value.timeRemaining.toInt();

            // Update 'bestTime' and 'bestTimeTier' if this is the first time or if 'tr' is smaller than the current 'bestTime'
            if (bestTime == null || tr < bestTime) {
              bestTime = tr;
              bestTimeTier = entry.key.toInt();
            }
          }
        }
        // Do we need to handle the else case when timeRemaining is missing?
      }

      // Initialize lists to store tiers for different display sections.
      List<String> displayBest = <String>[];
      List<String> displayMid = <String>[];
      List<String> displayQueued = <String>[];

      // Populate the display lists based on the tier status.
      for (int tier in tiersSorted) {
        if (statuses.containsKey(tier)) {
          String? tierStr = tiersStrings[tier];
          if (tierStr == null) {
            throw FusionError(
                'server reported status on tier we are not registered for');
          }
          if (tier == bestTimeTier) {
            displayBest.insert(0, '**$tierStr**');
          } else if (maxTiers.contains(tier)) {
            displayBest.add('[$tierStr]');
          } else {
            displayMid.add(tierStr);
          }
        } else {
          displayQueued.add(tiersStrings[tier]!);
        }
      }

      // Construct the final display string for tiers.
      List<String> parts = <String>[];
      if (displayBest.isNotEmpty || displayMid.isNotEmpty) {
        parts.add("Tiers: ${displayBest.join(', ')} ${displayMid.join(', ')}");
      }
      if (displayQueued.isNotEmpty) {
        parts.add("Queued: ${displayQueued.join(', ')}");
      }
      String tiersString = parts.join(' ');

      // Determine the overall status based on the best time and maximum fraction.
      if (bestTime == null) {
        if (stopwatch.elapsedMilliseconds >
            INACTIVE_TIME_LIMIT.inMilliseconds) {
          throw FusionError('stopping due to inactivity');
        }
      }

      // Final status assignment based on calculated variables
      if (bestTime != null) {
        _updateStatus(
          status: FusionStatus.waiting,
          info: 'Starting in ${bestTime}s. $tiersString',
        );
      } else if (maxFraction >= 1) {
        _updateStatus(
          status: FusionStatus.waiting,
          info: 'Starting soon. $tiersString',
        );
      } else if (displayBest.isNotEmpty || displayMid.isNotEmpty) {
        _updateStatus(
          status: FusionStatus.waiting,
          info: '${(maxFraction * 100).round()}% full. $tiersString',
        );
      } else {
        _updateStatus(
          status: FusionStatus.waiting,
          info: tiersString,
        );
      }
    } // End of while loop.  Loop exits with a break if a FusionBegin message is received.

    // Check if the field 'fusionbegin' exists in the message.
    FieldInfo<dynamic>? fieldInfoFusionBegin =
        msg.info_.byName[ReceiveMessages.fusionBegin];
    if (fieldInfoFusionBegin == null) {
      throw FusionError(
          'Expected field not found in message: $ReceiveMessages.fusionbegin');
    }

    // Determine if the message contains a FusionBegin message.
    bool messageIsFusionBegin = msg.hasField(fieldInfoFusionBegin.tagNumber);

    // Check if the received message is a FusionBegin message.
    if (!messageIsFusionBegin) {
      throw FusionError('Expected a FusionBegin message');
    }

    // Record the time when the fusion process began.
    _tFusionBegin = DateTime.now();

    // Check if the received message is a ServerMessage.
    if (msg is! ServerMessage) {
      throw FusionError('Expected a ServerMessage');
    }

    // Retrieve the FusionBegin message from the ServerMessage.
    FusionBegin fusionBeginMsg = msg.fusionbegin;

    // Calculate the time discrepancy between the server and the client.
    double clockMismatch = fusionBeginMsg.serverTime.toInt() -
        DateTime.now().millisecondsSinceEpoch / 1000;

    // Check if the clock mismatch exceeds the maximum allowed discrepancy.
    if (clockMismatch.abs().toDouble() > Protocol.MAX_CLOCK_DISCREPANCY) {
      throw FusionError(
          "Clock mismatch too large: ${(clockMismatch.toDouble()).toStringAsFixed(3)}.");
    }

    // Retrieve the tier in which the fusion process will occur.
    final tier = fusionBeginMsg.tier.toInt();

    // Populate covertDomainB with the received covert domain information.
    final covertDomainB = Uint8List.fromList(fusionBeginMsg.covertDomain);

    // Retrieve additional information such as port, SSL status, and server time for the fusion process.
    final covertPort = fusionBeginMsg.covertPort;
    final covertSSL = fusionBeginMsg.covertSsl;
    final beginTime = fusionBeginMsg.serverTime.toDouble();

    // Calculate the initial hash value for the fusion process
    final lastHash = Utilities.calcInitialHash(
      tier,
      covertDomainB,
      covertPort,
      covertSSL,
      beginTime,
    );

    // Retrieve the output amounts for the given tier and prepare the output addresses.
    List<int>? outAmounts = tierOutputs[tier];
    final List<Address> outAddrs;
    if (outAmounts != null && outAmounts.isNotEmpty) {
      outAddrs = await _getUnusedReservedChangeAddresses(outAmounts.length);
    } else {
      outAddrs = [];
    }

    // Populate reservedAddresses and outputs with the prepared amounts and addresses.
    _reservedAddresses = outAddrs;

    final outputs = Utilities.zip(outAmounts ?? [], outAddrs)
        .map((pair) => Output.fromAddress(
              value: pair[0] as int,
              address: (pair[1] as Address).address,
              network: network,
            ))
        .toList();

    Utilities.debugPrint(
        "starting fusion rounds at tier $tier: ${allocatedOutputs.inputs.length} inputs and ${outputs.length} outputs");

    return (
      tier: tier,
      covertPort: covertPort,
      covertSSL: covertSSL,
      covertDomainB: covertDomainB,
      beginTime: beginTime,
      outputs: outputs,
      lastHash: lastHash,
    );
  }

  /// Starts a CovertSubmitter and schedules Tor connections.
  ///
  /// This method initializes a `CovertSubmitter` with the specified configuration,
  /// schedules the connections, and continuously checks the connection status.
  Future<CovertSubmitter> startCovert({
    required Connection? connection,
    required int covertPort,
    required bool covertSSL,
    required Uint8List covertDomainB,
    required DateTime tFusionBegin,
    required ({
      int numComponents,
      int componentFeeRate,
      int minExcessFee,
      int maxExcessFee,
      List<int> availableTiers,
    }) serverParams,
  }) async {
    Utilities.debugPrint("DEBUG START COVERT!");

    // set status record/tuple.
    _updateStatus(
      status: FusionStatus.running,
      info: 'Setting up Tor connections',
    );

    // Get the Tor host and port from the wallet configuration.
    final ({InternetAddress host, int port}) proxyInfo;
    try {
      proxyInfo = await _getSocksProxyAddress();
    } catch (e) {
      throw FusionError("startCovert() can't connect to Tor proxy");
    }

    // Decode the covert domain and validate it.
    String covertDomain;
    try {
      covertDomain = utf8.decode(covertDomainB);
    } catch (e) {
      throw FusionError('badly encoded covert domain');
    }

    // Create a new CovertSubmitter instance.
    CovertSubmitter covert = CovertSubmitter(
      destAddr: covertDomain,
      destPort: covertPort,
      ssl: covertSSL,
      proxyInfo: proxyInfo,
      numSlots: serverParams.numComponents,
      randSpan: Protocol.COVERT_SUBMIT_WINDOW,
      submitTimeout: Duration(seconds: Protocol.COVERT_SUBMIT_TIMEOUT),
    );
    try {
      // Schedule Tor connections for the CovertSubmitter.
      covert.scheduleConnectionsAndStartRunningThem(
        tFusionBegin,
        Duration(seconds: Protocol.COVERT_CONNECT_WINDOW),
        numSpares: Protocol.COVERT_CONNECT_SPARES,
        connectTimeout: Duration(
          seconds: Protocol.COVERT_CONNECT_TIMEOUT,
        ),
      );

      // Loop a bit before we're expecting startRound, watching for status updates.
      final tend = tFusionBegin.add(Duration(
          seconds: (Protocol.WARMUP_TIME - Protocol.WARMUP_SLOP - 1).round()));

      // Poll the status of the connections until the ending time.
      while (DateTime.now().millisecondsSinceEpoch / 1000 <
          tend.millisecondsSinceEpoch / 1000) {
        // Count the number of established main and spare connections.
        int numConnected =
            covert.slots.where((s) => s.covConn?.connection != null).length;
        int numSpareConnected =
            covert.spareConnections.where((c) => c.connection != null).length;

        // Update the status based on connection counts.
        _updateStatus(
          status: FusionStatus.running,
          info: "Setting up Tor connections "
              "($numConnected+$numSpareConnected out"
              " of ${serverParams.numComponents})",
        );

        // Wait for 1 second before re-checking.
        await Future<void>.delayed(Duration(seconds: 1));

        // Check the health of the CovertSubmitter and overall system.
        covert.checkOk();

        if (_checkStop(connection, covert)) {
          throw FusionStopRequested();
        }
      }
    } catch (e) {
      // Stop the CovertSubmitter and re-throw the error.
      covert.stop();
      rethrow;
    }

    // Return the CovertSubmitter instance.
    return covert;
  }

  /// Runs a round of the Fusion protocol.
  /// Returns the txid of a successfully submitted txn, otherwise null.
  ///
  /// This method takes care of various steps in the Fusion protocol round,
  /// including receiving and validating server messages, creating commitments,
  /// and submitting components.
  ///
  /// [covert] is a `CovertSubmitter` instance used for covert submissions.
  Future<String?> runRound({
    required int roundCount,
    required CovertSubmitter covert,
    required Connection connection,
    required coin.Chain network,
  }) async {
    Utilities.debugPrint("START OF RUN ROUND");

    // Initial round status and timeout calculation.
    _updateStatus(
      status: FusionStatus.running,
      info: "Starting round $roundCount",
    );

    int timeoutInSeconds =
        (2 * Protocol.WARMUP_SLOP + Protocol.STANDARD_TIMEOUT).toInt();

    // Await the start of round message from the server.
    GeneratedMessage msg = await Comms.recvPb(
      [ReceiveMessages.startRound],
      connection: connection,
      covert: false,
      timeout: Duration(seconds: timeoutInSeconds),
    );

    /// The time when the covert timer was started.
    final covertT0 = DateTime.now().millisecondsSinceEpoch / 1000;

    /// Returns the time since the covert timer was started in seconds.
    double covertClock() =>
        (DateTime.now().millisecondsSinceEpoch / 1000) - covertT0;

    // Check if the received message is a ServerMessage.
    if (msg is! ServerMessage) {
      throw FusionError('Expected a ServerMessage');
    }

    // Retrieve the StartRound message from the ServerMessage.
    StartRound startRoundMsg = msg.startround;

    Int64 roundTime = startRoundMsg.serverTime;

    // Validate the server's time against our local time.
    final clockMismatch = roundTime -
        Int64((DateTime.now().millisecondsSinceEpoch / 1000).round());

    if (clockMismatch.abs() > Int64(Protocol.MAX_CLOCK_DISCREPANCY.toInt())) {
      throw FusionError(
          "Clock mismatch too large: ${clockMismatch.toInt().toStringAsPrecision(3)}.");
    }

    // Check that the warmup time was as expected.
    final lag = covertT0 -
        (_tFusionBegin.millisecondsSinceEpoch / 1000) -
        Protocol.WARMUP_TIME;
    if (lag.abs() > Protocol.WARMUP_SLOP) {
      throw FusionError(
          "Warmup period too different from expectation (|${lag.toStringAsFixed(3)}s| > ${Protocol.WARMUP_SLOP.toStringAsFixed(3)}s).");
    }
    _tFusionBegin = DateTime.now();

    Utilities.debugPrint(
        "round starting at ${DateTime.now().millisecondsSinceEpoch / 1000}");

    // Calculate fees and sums for inputs and outputs.
    final inputFees = _allocatedOutputs!.inputs.fold(
      BigInt.zero,
      (sum, input) =>
          sum +
          BigInt.from(
            Utilities.componentFee(
                Utilities.sizeOfInput(Uint8List.fromList(input.pubKey)),
                _serverParams!.componentFeeRate),
          ),
    );

    final outputFees = BigInt.from(
      _registerAndWaitResult!.outputs.length *
          Utilities.componentFee(
            34, // 34 is the size of a P2PKH output.
            _serverParams!.componentFeeRate,
          ),
    ); // See https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash_plugins/fusion/fusion.py#L820

    final sumIn = _allocatedOutputs!.inputs.fold(
      BigInt.zero,
      (sum, e) => sum + BigInt.from(e.value),
    );
    final sumOut = _registerAndWaitResult!.outputs
        .fold(BigInt.zero, (sum, e) => sum + BigInt.from(e.value));

    // Calculate total and excess fee for safety checks.
    final totalFee = sumIn - sumOut;
    final excessFee = totalFee - inputFees - outputFees;

    final safetyExcessFee =
        _allocatedOutputs!.safetyExcessFees[_registerAndWaitResult!.tier];
    if (safetyExcessFee == null) {
      throw Exception(
          "Safety excess fee not found for tier=${_registerAndWaitResult!.tier}");
    }

    // Perform the safety checks!
    final safeties = [
      sumIn == _allocatedOutputs!.safetySumIn,
      excessFee == BigInt.from(safetyExcessFee),
      excessFee <= BigInt.from(Protocol.MAX_EXCESS_FEE),
      totalFee <= BigInt.from(Protocol.MAX_FEE),
    ];

    // Abort the round if the safety checks fail.
    if (!safeties.every((element) => element)) {
      throw Exception(
          "(BUG!) Funds re-check failed -- aborting for safety. ${safeties.toString()}");
    }

    // Extract round public key and blind nonce points from the server message.
    final roundPubKey = startRoundMsg.roundPubkey;
    final blindNoncePoints = startRoundMsg.blindNoncePoints;
    if (blindNoncePoints.length != _serverParams!.numComponents) {
      throw FusionError('blind nonce miscount');
    }

    // Generate components and related data
    int numBlanks = _serverParams!.numComponents -
        _allocatedOutputs!.inputs.length -
        _registerAndWaitResult!.outputs.length;
    final genComponentsResults = OutputHandling.genComponents(
      network,
      numBlanks,
      _allocatedOutputs!.inputs,
      _registerAndWaitResult!.outputs,
      _serverParams!.componentFeeRate,
    );

    // Initialize lists to store various parts of the component data.
    final List<Uint8List> myCommitments = [];
    final List<int> myComponentSlots = [];
    final List<Uint8List> myComponents = [];
    final List<Proof> myProofs = [];
    final List<Uint8List> privKeys = [];

    // Populate the lists with data from the generated components.
    for (final result in genComponentsResults.results) {
      myCommitments.add(result.commitment);
      myComponentSlots.add(result.counter);
      myComponents.add(result.component);
      myProofs.add(result.proof);
      privKeys.add(result.privateKey);
    }
    // Sanity checks on the generated components.

    Utilities.debugPrint("excessFee=$excessFee");
    Utilities.debugPrint(
        "genComponentsResults.sumAmounts=${genComponentsResults.sumAmounts}");

    assert(excessFee == genComponentsResults.sumAmounts);
    assert(myComponents.toSet().length == myComponents.length); // no duplicates

    // Generate blind signature requests (see schnorr from Electron-Cash's schnorr.py)
    /*
    final blindSigRequests = blindNoncePoints.map((e) => Schnorr.BlindSignatureRequest(roundPubKey, e, sha256(myComponents.elementAt(e)))).toList();
    */

    Utilities.debugPrint("Generating blind signature requests.");
    List<BlindSignatureRequest> blindSigRequests =
        List.generate(blindNoncePoints.length, (index) {
      final R = blindNoncePoints[index];
      final m = myComponents[index];
      final messageHash = Utilities.sha256(m);

      return BlindSignatureRequest(
        pubkey: Uint8List.fromList(roundPubKey),
        R: Uint8List.fromList(R),
        messageHash: messageHash,
      );
    });
    Utilities.debugPrint("Generated blind signature requests.");

    /*
    Utilities.debugPrint("RETURNING EARLY FROM run round .....");
    return true;
    */

    // Perform pre-submission checks and prepare a random number for later use.
    final randomNumber = Utilities.getRandomBytes(32);
    covert.checkOk();
    if (_checkStop(connection, covert)) {
      throw FusionStopRequested();
    }

    Utilities.debugPrint("Sending initial commitments etc.");

    final playerCommit = PlayerCommit(
      initialCommitments: myCommitments,
      excessFee: Int64.parseHex(excessFee.toHex),
      pedersenTotalNonce: genComponentsResults.pedersenTotalNonce,
      randomNumberCommitment: Utilities.sha256(randomNumber),
      blindSigRequests: blindSigRequests.map((r) => r.request).toList(),
    );

    checkPlayerCommit(
      playerCommit,
      _serverParams!.minExcessFee,
      _serverParams!.maxExcessFee,
      _serverParams!.numComponents,
    );

    // Send initial commitments, fees, and other data to the server.
    await Comms.sendPb(
      connection,
      ClientMessage()..playercommit = playerCommit,
    );

    Utilities.debugPrint("Awaiting signature responses from the server...");

    // Await blind signature responses from the server
    msg = await Comms.recvPb(
      [ReceiveMessages.blindSigResponses],
      connection: connection,
      covert: false,
      timeout: Duration(seconds: Protocol.T_START_COMPS),
    );

    // Handle the cases where msg is not of type BlindSigResponses.
    if (msg is! ServerMessage) {
      throw Exception('Unexpected message type: ${msg.runtimeType}');
    }
    final fieldInfo = msg.info_.byName[ReceiveMessages.blindSigResponses];
    if (fieldInfo == null) {
      throw Exception('Unexpected message type: ${msg.whichMsg()}');
    }

    final BlindSigResponses blindSigResponses = (msg).blindsigresponses;

    // Validate type and length of the received message and perform a sanity-check on it.
    assert(blindSigResponses.scalars.length == blindSigRequests.length);

    final blindSigs = List.generate(
      blindSigRequests.length,
      (index) {
        return blindSigRequests[index].finalize(
          Uint8List.fromList(blindSigResponses.scalars[index]),
          check: true,
        );
      },
    );

    Utilities.debugPrint("Waiting for covert component submission phase...");

    // Sleep until the covert component phase really starts, to catch covert connection failures.
    double remainingTime = Protocol.T_START_COMPS - covertClock();
    if (remainingTime < 0) {
      throw FusionError('Arrived at covert-component phase too slowly.');
    }
    await Future<void>.delayed(Duration(seconds: remainingTime.floor()));

    // Our final check to leave the fusion pool, before we start telling our
    // components. This is much more annoying since it will cause the round
    // to fail, but since we would end up killing the round anyway then it's
    // best for our privacy if we just leave now.
    // (This also is our first call to check_connected.)
    covert.checkConnected();

    // Start covert component submissions
    Utilities.debugPrint("starting covert component submission");
    _updateStatus(
      status: FusionStatus.running,
      info: "covert submission: components",
    );

    // If we fail after this point, we want to stop connections gradually and
    // randomly. We don't want to stop them all at once, since if we had already
    // provided our input components then it would be a leak to have them all drop at once.
    covert.setStopTime((covertT0 + Protocol.T_START_CLOSE).toInt());

    // Schedule covert submissions.
    List<CovertComponent?> messages = List.filled(myComponents.length, null);

    for (int i = 0; i < myComponents.length; i++) {
      messages[myComponentSlots[i]] = CovertComponent(
          roundPubkey: roundPubKey,
          signature: blindSigs[i],
          component: myComponents[i]);
    }
    if (messages.any((element) => element == null)) {
      throw FusionError('Messages list includes null values.');
    }

    for (final cc in messages) {
      checkCovertComponent(
        cc!,
        Uint8List.fromList(roundPubKey),
        _serverParams!.componentFeeRate,
        network,
      );
    }

    final targetDateTime = DateTime.fromMillisecondsSinceEpoch(
        ((covertT0 + Protocol.T_START_COMPS) * 1000).toInt());
    covert.scheduleSubmissions(targetDateTime, messages);

    // While submitting, we download the (large) full commitment list.
    msg = await Comms.recvPb(
      [ReceiveMessages.allCommitments],
      connection: connection,
      covert: false,
      timeout: Duration(seconds: Protocol.T_START_SIGS.toInt()),
    );

    // Handle the cases where msg is not of type allCommitments.
    if (msg is! ServerMessage) {
      throw Exception('Unexpected message type: ${msg.runtimeType}');
    }
    final fieldInfo2 = msg.info_.byName[ReceiveMessages.allCommitments];
    if (fieldInfo2 == null) {
      throw Exception('Unexpected message type: ${msg.whichMsg()}');
    }

    final allCommitmentsMsg = msg.allcommitments;
    List<InitialCommitment> allCommitments =
        allCommitmentsMsg.initialCommitments.map((commitmentBytes) {
      return InitialCommitment.fromBuffer(commitmentBytes);
    }).toList();

    // Quick check on the commitment list.
    if (allCommitments.toSet().length != allCommitments.length) {
      throw FusionError('Commitments list includes duplicates.');
    }

    // Check that all of our commitments are in the list.
    //
    // Convert allCommitments to a list of Uint8List for comparison.
    List<Uint8List> allCommitmentsBytes =
        allCommitments.map((commitment) => commitment.writeToBuffer()).toList();

    // Initialize a list to store the indexes of our commitments.
    List<int> myCommitmentIndexes = [];

    // Populate the list with the indexes of our commitments.
    for (var c in myCommitments) {
      // Search for the index of the commitment in the list of all commitments.
      final int index =
          allCommitmentsBytes.indexWhere((element) => element.equals(c));

      if (index == -1) {
        throw FusionError(
            'One or more of my commitments missing. Did not find ${c.toHex}.');
      }
      // Add the index to the list of indexes.
      myCommitmentIndexes.add(index);
    }

    remainingTime = Protocol.T_START_SIGS - covertClock();
    if (remainingTime < 0) {
      throw FusionError('took too long to download commitments list');
    }

    // Once all components are received, the server shares them with us:
    msg = await Comms.recvPb(
      [ReceiveMessages.shareCovertComponents],
      connection: connection,
      covert: false,
      timeout: Duration(seconds: Protocol.T_START_SIGS.toInt()),
    );

    // Handle the cases where msg is not of type shareCovertComponents.
    if (msg is! ServerMessage) {
      throw Exception('Unexpected message type: ${msg.runtimeType}');
    }
    final fieldInfo3 = msg.info_.byName[ReceiveMessages.shareCovertComponents];
    if (fieldInfo3 == null) {
      throw Exception('Unexpected message type: ${msg.whichMsg()}');
    }

    final shareCovertComponentsMsg = msg.sharecovertcomponents;
    List<List<int>> allComponents = shareCovertComponentsMsg.components;

    // Critical check on server's response timing.
    if (covertClock() > Protocol.T_START_SIGS) {
      throw FusionError('Shared components message arrived too slowly.');
    }

    covert.checkDone();

    final List<int> myComponentIndexes = [];

    try {
      myComponentIndexes.addAll(
        myComponents.map(
          (c) => allComponents.indexWhere(
            (e) => Uint8List.fromList(e).equals(c),
          ),
        ),
      );

      if (myComponentIndexes.contains(-1)) {
        throw FusionError('One or more of my components missing. (1)');
      }
    } on StateError {
      throw FusionError('One or more of my components missing. (2)');
    }

    // TODO check the components list and see if there are enough inputs/outputs
    // for there to be significant privacy.
    //
    // This is also a TODO in the Python reference: https://github.com/Electron-Cash/Electron-Cash/blob/397f43c848e270a7405795c4643a2805d872675f/electroncash_plugins/fusion/fusion.py#L936-L937

    List<List<int>> allCommitmentsInts = allCommitments
        .map((commitment) => commitment.writeToBuffer().toList())
        .toList();
    List<int> sessionHash = Utilities.calcRoundHash(
        _registerAndWaitResult!.lastHash,
        roundPubKey,
        roundTime.toInt(),
        allCommitmentsInts,
        allComponents);

    // Validate session hash to prevent mismatch error.
    if (!shareCovertComponentsMsg.sessionHash.equals(sessionHash)) {
      throw FusionError(
          'Session hash mismatch (bug)!  Expected $sessionHash, found ${shareCovertComponentsMsg.sessionHash}');
    }

    final Set<int> badComponentIndexes = {};

    // Handle covert signature submission.
    Utilities.debugPrint(
        "shareCovertComponentsMsg.skipSignatures: ${shareCovertComponentsMsg.skipSignatures}");
    if (!shareCovertComponentsMsg.skipSignatures) {
      Utilities.debugPrint("starting covert signature submission");
      _updateStatus(
        status: FusionStatus.running,
        info: "covert submission: signatures",
      );

      // Check for duplicate server components.
      if (allComponents.toSet().length != allComponents.length) {
        throw FusionError('Server component list includes duplicates.');
      }

      // Build transaction from components and session hash.
      final txData = Transaction.txFromComponents(
        allComponents,
        sessionHash,
        network,
      );

      // Initialize list to store covert transaction signature messages.
      List<CovertTransactionSignature?> covertTransactionSignatureMessages =
          List<CovertTransactionSignature?>.filled(myComponents.length, null);

      // Sign the covert transaction.
      for (int i = 0; i < txData.inputAndCompIndexes.length; i++) {
        final data = txData.inputAndCompIndexes[i];
        final inp = data.input;

        // Skip if not my input.
        final int myCompIdx = myComponentIndexes.indexOf(data.compIndex);
        if (myCompIdx == -1) continue; // not my input

        // Extract public and private keys.
        final pubKey = inp.pubkeys!.first!; // cast/convert to PublicKey?
        final sec = await _getPrivateKeyForPubKey(pubKey);

        // Calculate sigHash for signing.
        final preimageBytes = txData.tx.serializePreimageBytes(
          i,
          network: network,
          nHashType: 0x41,
          useCache: true,
        );
        final sigHash = Utilities.doubleSha256(preimageBytes);

        // Generate signature.
        final sig = Utilities.schnorrSign(
          sec,
          sigHash,
        );

        // Store the covert transaction signature
        covertTransactionSignatureMessages[myComponentSlots[myCompIdx]] =
            CovertTransactionSignature(txsignature: sig, whichInput: i);
      }

      // Schedule covert submissions.
      DateTime covertT0DateTime = DateTime.fromMillisecondsSinceEpoch(
          covertT0.toInt() * 1000); // covertT0 is in seconds
      covert.scheduleSubmissions(
          covertT0DateTime
              .add(Duration(seconds: Protocol.T_START_SIGS.toInt())),
          covertTransactionSignatureMessages);

      final timeout = Duration(
          seconds: Protocol.T_EXPECTING_CONCLUSION -
              Protocol.TS_EXPECTING_COVERT_COMPONENTS);
      msg = await Comms.recvPb(
        [ReceiveMessages.fusionResult],
        connection: connection,
        covert: false,
        timeout: timeout,
      );

      // Critical check on server's response timing.
      if (covertClock() > Protocol.T_EXPECTING_CONCLUSION) {
        throw FusionError('Fusion result message arrived too slowly.');
      }

      // Verify if the covert operation was successful.
      covert.checkDone();

      // Handle the cases where msg is not of type FusionResult.
      if (msg is! ServerMessage) {
        throw Exception('Unexpected message type: ${msg.runtimeType}');
      }
      final fieldInfo4 = msg.info_.byName[ReceiveMessages.fusionResult];
      if (fieldInfo4 == null) {
        throw Exception('Unexpected message type: ${msg.whichMsg()}');
      }

      // Retrieve the FusionResult message from the ServerMessage.
      final fusionResultMsg = msg.fusionresult;

      // Check if the fusion operation was successful.
      if (fusionResultMsg.ok) {
        List<List<int>> allSigs = fusionResultMsg.txsignatures;

        final List<bitbox.Input> bInputs = [];
        final List<bitbox.Output> bOutputs = [];

        // Assemble and complete the transaction.
        if (allSigs.length != txData.tx.inputs.length) {
          throw FusionError('Server gave wrong number of signatures.');
        }
        for (int i = 0; i < allSigs.length; i++) {
          List<int> sigBytes = allSigs[i];
          if (sigBytes.length != 64) {
            throw FusionError('server relayed bad signature');
          }
          bitbox.Input inp = txData.inputAndCompIndexes[i].input;

          // Build P2PKH scriptSig placeholder with just the pubkey push.
          // The actual signature is set separately via inp.signatures.
          final pubKeyBytes = coin.PublicKey.fromHex(
            inp.pubkeys![0]!.toHex,
          ).bytes;
          final p2pkh =
              coin.PayToPubKeyHash(coin.hash160(pubKeyBytes));
          inp.script = p2pkh.compiled;
          inp.signatures = [
            Uint8List.fromList([
              ...sigBytes,
              0x41,
            ]),
          ];
          bInputs.add(inp);
        }

        for (final o in txData.tx.outputs) {
          bOutputs.add(
            bitbox.Output(
              value: o.value,
              script: o.scriptPubKey,
            ),
          );
        }

        final txn = bitbox.Transaction(
          txData.tx.version.toInt(),
          txData.tx.locktime.toInt(),
          bInputs,
          bOutputs,
        );

        // Finalize transaction details and update wallet label.

        final txHex = txn.toHex();
        final lastTxId =
            txn.getId(); // Converted to instance variable vs. previously-
        // local variable to allow for waiting for tx to be broadcast.

        try {
          final broadcastTxid = await _broadcastTransaction(txHex);

          assert(broadcastTxid == lastTxId);

          // round success
          return lastTxId;
        } catch (e, s) {
          Utilities.debugPrint("BROADCAST FAILED: $e\n$s");

          if (e.toString().contains("txn-mempool-conflict")) {
            // tx was already broadcast by another player
            // round success
            return lastTxId;
          } else {
            rethrow;
          }
        }
      } else {
        // If not successful, identify bad components.
        badComponentIndexes.clear();
        badComponentIndexes.addAll(fusionResultMsg.badComponents);
        if (badComponentIndexes
            .intersection(myComponentIndexes.toSet())
            .isNotEmpty) {
          Utilities.debugPrint(
              "bad components: $badComponentIndexes mine: $myComponentIndexes");
          throw FusionError("server thinks one of my components is bad!");
        }
      }
    } else {
      // Case where 'skip_signatures' is True.
      // this should be empty already sooooo
      badComponentIndexes.clear();
    }

    Utilities.debugPrint("badComponentIndexes: $badComponentIndexes");

    if (_checkStop(connection, covert)) {
      throw FusionStopRequested();
    }

    // Begin Blame phase logic.

    // Set the time when this phase of the protocol should stop.
    covert.setStopTime((covertT0 + Protocol.T_START_CLOSE_BLAME).floor());

    // Update status to indicate that proofs are being sent.
    _updateStatus(
      status: FusionStatus.running,
      info: "Round failed: sending proofs",
    );
    Utilities.debugPrint("sending proofs");

    // Create a list of commitment indexes, but leaving out mine.
    List<int> othersCommitmentIdxes = [];
    for (int i = 0; i < allCommitments.length; i++) {
      if (!myCommitmentIndexes.contains(i)) {
        othersCommitmentIdxes.add(i);
      }
    }

    Utilities.debugPrint("othersCommitmentIdxes: $othersCommitmentIdxes");

    // Ensure that the count is accurate.
    int N = othersCommitmentIdxes.length;
    if (N != allCommitments.length - myCommitments.length) {
      throw FusionError(
          "Fusion failed with bad commitment count -- I have ${myCommitments.length} commitments, but there are ${allCommitments.length} total commitments.");
    }
    if (N == 0) {
      throw FusionError(
          "Fusion failed with only me as player -- I can only blame myself.");
    }

    // Determine to whom the proofs should be sent.
    List<InitialCommitment> dstCommits = [];
    for (int i = 0; i < myCommitments.length; i++) {
      dstCommits.add(allCommitments[
          othersCommitmentIdxes[Utilities.randPosition(randomNumber, N, i)]]);
    }

    Utilities.debugPrint("dstCommits: $dstCommits");

    // Generate the encrypted proofs.
    List<Uint8List> encryptedProofs = [];

    // Loop through all the destination commitments to generate encrypted proofs.
    for (int i = 0; i < dstCommits.length; i++) {
      InitialCommitment msg = dstCommits[i];
      Proof proof = myProofs[i];
      proof.componentIdx = myComponentIndexes[i];

      try {
        // Encrypt the proof using the communication key.
        final encryptedData = await encrypt(
          proof.writeToBuffer(),
          Uint8List.fromList(msg.communicationKey),
          padToLength: 80,
        );
        encryptedProofs.add(encryptedData);
      } on EncryptionFailed catch (e, s) {
        Utilities.debugPrint("$e\n$s");
        // The communication key was bad (probably invalid x coordinate).
        // We will just send a blank.  They can't even blame us since there is no private key! :)
        encryptedProofs.add(Uint8List(0));
      } catch (e, s) {
        Utilities.debugPrint("$e\n$s");
        rethrow;
      }
    }

    Utilities.debugPrint("encryptedProofs: $encryptedProofs");
    Utilities.debugPrint("randomNumber: $randomNumber");

    // Send the encrypted proofs and the random number used to the server.
    await Comms.sendPb(
      connection,
      ClientMessage()
        ..myproofslist = MyProofsList(
          encryptedProofs: encryptedProofs,
          randomNumber: randomNumber,
        ),
    );

    // Update the status to indicate that the program is in the process of checking proofs.
    _updateStatus(
      status: FusionStatus.running,
      info: "Round failed: checking proofs",
    );

    // Receive the list of proofs from the other parties
    Utilities.debugPrint("receiving proofs");
    msg = await Comms.recvPb(
      [ReceiveMessages.theirProofsList],
      connection: connection,
      covert: false,
      timeout: Duration(seconds: (2 * Protocol.STANDARD_TIMEOUT).round()),
    );

    // Initialize a list to store proofs that should be blamed for failure.
    List<Blames_BlameProof> blames = [];

    // Initialize a counter to keep track of the number of valid input components found.
    int countInputs = 0;

    // Cast the received message to TheirProofsList for type safety.
    TheirProofsList proofsList = (msg as ServerMessage).theirproofslist;

    // Iterate over each received proof to validate or blame them.
    for (var i = 0; i < proofsList.proofs.length; i++) {
      TheirProofsList_RelayedProof rp = proofsList.proofs[i];
      final Uint8List commitmentBlob;
      final Uint8List privKey;
      try {
        // Obtain private key and commitment information for the current proof.
        privKey = privKeys[rp.dstKeyIdx];
        commitmentBlob = allCommitments[rp.srcCommitmentIdx].writeToBuffer();
      } on RangeError catch (_) {
        // If the indices are invalid, throw an error.
        throw FusionError("Server relayed bad proof indices");
      }

      final List<int> sKey;
      final Uint8List proofBlob;

      try {
        // Decrypt the proof, storing the decrypted data and the symmetric key used.
        final result = await decrypt(
          Uint8List.fromList(rp.encryptedProof),
          Uint8List.fromList(privKey),
        );
        proofBlob = result.decrypted;
        sKey = result.symmetricKey;
      } on Exception catch (_) {
        // If decryption fails, add the proof to the blame list.
        Utilities.debugPrint("found an undecryptable proof");
        blames.add(
          Blames_BlameProof(
            whichProof: i,
            privkey: privKey,
            blameReason: 'undecryptable',
          ),
        );
        continue;
      }

      // Parsing the received commitment.
      InitialCommitment commitment = InitialCommitment();
      try {
        commitment
            .mergeFromBuffer(commitmentBlob); // Method to parse protobuf data.
      } on FormatException catch (_) {
        // If the commitment data is invalid, throw an error.
        throw FusionError("Server relayed bad commitment");
      }

      InputComponent? inpComp;

      try {
        // Validate the proof internally, adding it to the list of validated proofs if it's valid.
        inpComp = validateProofInternal(
          proofBlob,
          commitment,
          allComponents,
          badComponentIndexes.toList(),
          _serverParams!.componentFeeRate,
          network,
        );
      } on Exception catch (e) {
        // If the proof is invalid, add it to the blame list.
        Utilities.debugPrint("found an erroneous proof: ${e.toString()}");
        final blameProof = Blames_BlameProof();
        blameProof.whichProof = i;
        blameProof.sessionKey = sKey;
        blameProof.blameReason = e.toString();
        blames.add(blameProof);
        continue;
      }

      // If inpComp is not null, this means the proof was valid.
      if (inpComp != null) {
        countInputs++;
        try {
          // Perform additional validation by checking against the blockchain.
          await Utilities.checkInputElectrumX(inpComp, false, _checkUtxoExists);
        } on Exception catch (e) {
          // If the input component doesn't match the blockchain, add the proof to the blame list.
          Utilities.debugPrint(
            "found a bad input [${rp.srcCommitmentIdx}]: "
            "$e (${(Uint8List.fromList(inpComp.prevTxid.reversed.toList())).toHex}:${inpComp.prevIndex})",
          );

          final blameProof = Blames_BlameProof();
          blameProof.whichProof = i;
          blameProof.sessionKey = sKey;
          blameProof.blameReason = 'input does not match blockchain: $e';
          blameProof.needLookupBlockchain = true;
          blames.add(blameProof);
        } catch (e) {
          // If we can't check against the blockchain for some reason, log a message.
          Utilities.debugPrint(
            "verified an input internally, but was unable to check it against blockchain: $e",
          );
        }
      }
    }
    Utilities.debugPrint(
        "checked ${proofsList.proofs.length} proofs, $countInputs of them inputs");

    // Send the blame list to the server
    await Comms.sendPb(
      connection,
      ClientMessage()..blames = Blames(blames: blames),
    );
    Utilities.debugPrint("sending blames");

    // Update the status to indicate that the program is waiting for the round to restart.
    _updateStatus(
      status: FusionStatus.running,
      info: "Awaiting restart",
    );

    // Await the final 'restartround' message. It might take some time
    // to arrive since other players might be slow, and then the server
    // itself needs to check blockchain.
    await Comms.recvPb(
      [ReceiveMessages.restartRound],
      connection: connection,
      covert: false,
      timeout: Duration(
          seconds: 2 *
              (Protocol.STANDARD_TIMEOUT.round() +
                  Protocol.BLAME_VERIFY_TIME.round())),
    );

    // Return null to trigger another runRound
    return null;
  } // /run_round()
}
