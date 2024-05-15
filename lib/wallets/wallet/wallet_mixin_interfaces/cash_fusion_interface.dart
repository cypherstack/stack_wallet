import 'dart:convert';
import 'dart:io';

import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:flutter/foundation.dart';
import 'package:fusiondart/fusiondart.dart' as fusion;
import 'package:isar/isar.dart';
import 'package:stackwallet/models/fusion_progress_ui_state.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/services/fusion_tor_service.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoincash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/ecash.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/coin_control_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';

const String kReservedFusionAddress = "reserved_fusion_address";

final kFusionServerInfoDefaults = Map<String, FusionInfo>.unmodifiable({
  Bitcoincash(CryptoCurrencyNetwork.main).identifier: const FusionInfo(
    host: "fusion.servo.cash",
    port: 8789,
    ssl: true,
    // host: "cashfusion.stackwallet.com",
    // port: 8787,
    // ssl: false,
    rounds: 0, // 0 is continuous
  ),
  Bitcoincash(CryptoCurrencyNetwork.test).identifier: const FusionInfo(
    host: "fusion.servo.cash",
    port: 8789,
    ssl: true,
    // host: "cashfusion.stackwallet.com",
    // port: 8787,
    // ssl: false,
    rounds: 0, // 0 is continuous
  ),
  Ecash(CryptoCurrencyNetwork.main).identifier: const FusionInfo(
    host: "fusion.tokamak.cash",
    port: 8788,
    ssl: true,
    rounds: 0, // 0 is continuous
  ),
});

class FusionInfo {
  final String host;
  final int port;
  final bool ssl;

  /// set to 0 for continuous
  final int rounds;

  const FusionInfo({
    required this.host,
    required this.port,
    required this.ssl,
    required this.rounds,
  }) : assert(rounds >= 0);

  factory FusionInfo.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return FusionInfo(
      host: json['host'] as String,
      port: json['port'] as int,
      ssl: json['ssl'] as bool,
      rounds: json['rounds'] as int,
    );
  }

  String toJsonString() {
    return jsonEncode({
      'host': host,
      'port': port,
      'ssl': ssl,
      'rounds': rounds,
    });
  }

  @override
  String toString() {
    return toJsonString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FusionInfo &&
        other.host == host &&
        other.port == port &&
        other.ssl == ssl &&
        other.rounds == rounds;
  }

  @override
  int get hashCode {
    return Object.hash(
      host.hashCode,
      port.hashCode,
      ssl.hashCode,
      rounds.hashCode,
    );
  }
}

mixin CashFusionInterface<T extends ElectrumXCurrencyInterface>
    on CoinControlInterface<T>, ElectrumXInterface<T> {
  final _torService = FusionTorService.sharedInstance;

  // setting values on this should notify any listeners (the GUI)
  FusionProgressUIState? _uiState;
  FusionProgressUIState get uiState {
    if (_uiState == null) {
      throw Exception("FusionProgressUIState has not been set for $walletId");
    }
    return _uiState!;
  }

  set uiState(FusionProgressUIState state) {
    if (_uiState != null) {
      throw Exception("FusionProgressUIState was already set for $walletId");
    }
    _uiState = state;
  }

  int _torStartCount = 0;

  // Fusion object.
  fusion.Fusion? _mainFusionObject;
  bool _stopRequested = false;

  /// An int storing the number of successfully completed fusion rounds.
  int _completedFuseCount = 0;

  /// An int storing the number of failed fusion rounds.
  int _failedFuseCount = 0;

  /// The maximum number of consecutive failed fusion rounds before stopping.
  int get maxFailedFuseCount => 5;

  // callback to update the ui state object
  void _updateStatus({required fusion.FusionStatus status, String? info}) {
    switch (status) {
      case fusion.FusionStatus.connecting:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.running, info: null),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: true);
        break;
      case fusion.FusionStatus.setup:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.running, info: null),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: true);
        break;
      case fusion.FusionStatus.waiting:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.running, info: null),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: true);
        break;
      case fusion.FusionStatus.running:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.running, info: null),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.waiting, info: null),
            shouldNotify: true);
        break;
      case fusion.FusionStatus.complete:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.success, info: null),
            shouldNotify: true);
        break;
      case fusion.FusionStatus.failed:
        failCurrentUiState(info);
        break;
      case fusion.FusionStatus.exception:
        failCurrentUiState(info);
        break;
      case fusion.FusionStatus.reset:
        _uiState?.setConnecting(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);
        _uiState?.setOutputs(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);
        _uiState?.setPeers(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);
        _uiState?.setFusing(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);
        _uiState?.setComplete(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);

        _uiState?.setFusionState(
            CashFusionState(status: CashFusionStatus.waiting, info: info),
            shouldNotify: false);

        _uiState?.setFailed(false, shouldNotify: true);
        break;
    }
  }

  void failCurrentUiState(String? info) {
    // Check each _uiState value to see if it is running.  If so, set it to failed.
    if (_uiState?.connecting.status == CashFusionStatus.running) {
      _uiState?.setConnecting(
          CashFusionState(status: CashFusionStatus.failed, info: info),
          shouldNotify: true);
      return;
    }
    if (_uiState?.outputs.status == CashFusionStatus.running) {
      _uiState?.setOutputs(
          CashFusionState(status: CashFusionStatus.failed, info: info),
          shouldNotify: true);
      return;
    }
    if (_uiState?.peers.status == CashFusionStatus.running) {
      _uiState?.setPeers(
          CashFusionState(status: CashFusionStatus.failed, info: info),
          shouldNotify: true);
      return;
    }
    if (_uiState?.fusing.status == CashFusionStatus.running) {
      _uiState?.setFusing(
          CashFusionState(status: CashFusionStatus.failed, info: info),
          shouldNotify: true);
      return;
    }
    if (_uiState?.complete.status == CashFusionStatus.running) {
      _uiState?.setComplete(
          CashFusionState(status: CashFusionStatus.failed, info: info),
          shouldNotify: true);
      return;
    }
  }

  /// Returns a list of all transactions in the wallet for the given address.
  Future<List<Map<String, dynamic>>> _getTransactionsByAddress(
    String address,
  ) async {
    final txidList =
        await mainDB.getTransactions(walletId).txidProperty().findAll();

    final futures = txidList.map(
      (e) => electrumXCachedClient.getTransaction(
        txHash: e,
        cryptoCurrency: info.coin,
      ),
    );

    return await Future.wait(futures);
  }

  Future<Uint8List> _getPrivateKeyForPubKey(List<int> pubKey) async {
    // can't directly query for equal lists in isar so we need to fetch
    // all addresses then search in dart
    try {
      final derivationPath = (await mainDB
              .getAddresses(walletId)
              .filter()
              .typeEqualTo(AddressType.p2pkh)
              .and()
              .derivationPathIsNotNull()
              .and()
              .group((q) => q
                  .subTypeEqualTo(AddressSubType.receiving)
                  .or()
                  .subTypeEqualTo(AddressSubType.change))
              .findAll())
          .firstWhere((e) => e.publicKey.toString() == pubKey.toString())
          .derivationPath!
          .value;

      final root = await getRootHDNode();

      return root.derivePath(derivationPath).privateKey.data;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
      throw Exception("Derivation path for pubkey=$pubKey could not be found");
    }
  }

  /// Reserve an address for fusion.
  Future<List<Address>> _reserveAddresses(Iterable<Address> addresses) async {
    if (addresses.isEmpty) {
      return [];
    }

    final updatedAddresses = addresses
        .map((e) => e.copyWith(otherData: kReservedFusionAddress))
        .toList();

    await mainDB.isar.writeTxn(() async {
      for (final newAddress in updatedAddresses) {
        final oldAddress = await mainDB.getAddress(
          newAddress.walletId,
          newAddress.value,
        );

        if (oldAddress != null) {
          newAddress.id = oldAddress.id;
          await mainDB.isar.addresses.delete(oldAddress.id);
        }

        await mainDB.isar.addresses.put(newAddress);
      }
    });

    return updatedAddresses;
  }

  /// un reserve a fusion reserved address.
  /// If [address] is not reserved nothing happens
  Future<Address> _unReserveAddress(Address address) async {
    if (address.otherData != kReservedFusionAddress) {
      return address;
    }

    final updated = address.copyWith(otherData: null);

    // Make sure the address is updated in the database.
    await mainDB.updateAddress(address, updated);

    return updated;
  }

  /// Returns a list of unused reserved change addresses.
  ///
  /// If there are not enough unused reserved change addresses, new ones are created.
  Future<List<fusion.Address>> _getUnusedReservedChangeAddresses(
    int numberOfAddresses,
  ) async {
    final unusedChangeAddresses = await _getUnusedChangeAddresses(
      numberOfAddresses: numberOfAddresses,
    );

    // Initialize a list of unused reserved change addresses.
    final List<Address> unusedReservedAddresses = unusedChangeAddresses
        .where((e) => e.otherData == kReservedFusionAddress)
        .toList();

    unusedReservedAddresses.addAll(await _reserveAddresses(
        unusedChangeAddresses.where((e) => e.otherData == null)));

    // Return the list of unused reserved change addresses.
    return unusedReservedAddresses
        .map(
          (e) => fusion.Address(
            address: e.value,
            publicKey: e.publicKey,
            fusionReserved: true,
            derivationPath: fusion.DerivationPath(
              e.derivationPath!.value,
            ),
          ),
        )
        .toList();
  }

  Future<List<Address>> _getUnusedChangeAddresses({
    int numberOfAddresses = 1,
  }) async {
    if (numberOfAddresses < 1) {
      throw ArgumentError.value(
        numberOfAddresses,
        "numberOfAddresses",
        "Must not be less than 1",
      );
    }

    final changeAddresses = await mainDB.isar.addresses
        .buildQuery<Address>(
          whereClauses: [
            IndexWhereClause.equalTo(
              indexName: r"walletId",
              value: [walletId],
            ),
          ],
          filter: changeAddressFilterOperation,
          sortBy: [
            const SortProperty(
              property: r"derivationIndex",
              sort: Sort.desc,
            ),
          ],
        )
        .findAll();

    final List<Address> unused = [];

    for (final addr in changeAddresses) {
      if (await _isUnused(addr.value)) {
        unused.add(addr);
        if (unused.length == numberOfAddresses) {
          return unused;
        }
      }
    }

    // if not returned by now, we need to create more addresses
    int countMissing = numberOfAddresses - unused.length;

    while (countMissing > 0) {
      // generate next change address
      await generateNewChangeAddress();

      // grab address
      final address = (await getCurrentChangeAddress())!;

      // check if it has been used before adding
      if (await _isUnused(address.value)) {
        unused.add(address);
        countMissing--;
      }
    }

    return unused;
  }

  Future<bool> _isUnused(String address) async {
    final txCountInDB = await mainDB
        .getTransactions(walletId)
        .filter()
        .address((q) => q.valueEqualTo(address))
        .count();
    if (txCountInDB == 0) {
      // double check via electrumx
      // _getTxCountForAddress can throw!
      // final count = await getTxCount(address: address);
      // if (count == 0) {
      return true;
      // }
    }

    return false;
  }

  /// Returns the current Tor proxy address.
  Future<({InternetAddress host, int port})> _getSocksProxyAddress() async {
    if (_torStartCount > 5) {
      // something is quite broken so stop trying to recursively fetch
      // start up tor and fetch proxy info
      throw Exception(
        "Fusion interface attempted to start tor $_torStartCount times and failed!",
      );
    }

    try {
      final info = _torService.getProxyInfo();

      // reset counter before return info;
      _torStartCount = 0;

      return info;
    } catch (_) {
      // tor is probably not running so lets fix that
      final torDir = await StackFileSystem.applicationTorDirectory();
      _torService.init(torDataDirPath: torDir.path);

      // increment start attempt count
      _torStartCount++;

      await _torService.start();

      // try again to fetch proxy info
      return await _getSocksProxyAddress();
    }
  }

  Future<bool> _checkUtxoExists(
    String address,
    String prevTxid,
    int prevIndex,
  ) async {
    final scriptHash = cryptoCurrency.addressToScriptHash(address: address);

    final utxos = await electrumXClient.getUTXOs(scripthash: scriptHash);

    for (final utxo in utxos) {
      if (utxo["tx_hash"] == prevTxid && utxo["tx_pos"] == prevIndex) {
        return true;
      }
    }

    return false;
  }

  // Initial attempt for CashFusion integration goes here.

  /// Fuse the wallet's UTXOs.
  ///
  /// This function is called when the user taps the "Fuse" button in the UI.
  Future<void> fuse({
    required FusionInfo fusionInfo,
  }) async {
    // Initial attempt for CashFusion integration goes here.

    try {
      _updateStatus(status: fusion.FusionStatus.reset);
      _updateStatus(
        status: fusion.FusionStatus.connecting,
        info: "Connecting to the CashFusion server.",
      );

      // Use server host and port which ultimately come from text fields.
      fusion.FusionParams serverParams = fusion.FusionParams(
        serverHost: fusionInfo.host,
        serverPort: fusionInfo.port,
        serverSsl: fusionInfo.ssl,
        genesisHashHex: cryptoCurrency.genesisHash,
        enableDebugPrint: kDebugMode,
        torForOvert: prefs.useTor,
        mode: fusion.FusionMode.normal,
      );

      // Instantiate a Fusion object with custom parameters.
      _mainFusionObject = fusion.Fusion(serverParams);

      // Pass wallet functions to the Fusion object
      await _mainFusionObject!.initFusion(
        getTransactionsByAddress: _getTransactionsByAddress,
        getUnusedReservedChangeAddresses: _getUnusedReservedChangeAddresses,
        getSocksProxyAddress: _getSocksProxyAddress,
        getChainHeight: fetchChainHeight,
        updateStatusCallback: _updateStatus,
        checkUtxoExists: _checkUtxoExists,
        getTransactionJson: (String txid) async =>
            await electrumXCachedClient.getTransaction(
          cryptoCurrency: info.coin,
          txHash: txid,
        ),
        getPrivateKeyForPubKey: _getPrivateKeyForPubKey,
        broadcastTransaction: (String txHex) =>
            electrumXClient.broadcastTransaction(rawTx: txHex),
        unReserveAddresses: (List<fusion.Address> addresses) async {
          final List<Future<void>> futures = [];
          for (final addr in addresses) {
            futures.add(
              mainDB.getAddress(walletId, addr.address).then(
                (address) async {
                  if (address == null) {
                    // matching address not found in db so cannot mark as unreserved
                    // just ignore I guess. Should never actually happen in practice.
                    // Might be useful check in debugging cases?
                    return;
                  } else {
                    await _unReserveAddress(address);
                  }
                },
              ),
            );
          }
          await Future.wait(futures);
        },
      );

      // Reset internal and UI counts and flag.
      _completedFuseCount = 0;
      _uiState?.fusionRoundsCompleted = 0;
      _failedFuseCount = 0;
      _uiState?.fusionRoundsFailed = 0;
      _stopRequested = false;

      bool shouldFuzeAgain() {
        if (fusionInfo.rounds <= 0) {
          // ignore count if continuous
          return !_stopRequested;
        } else {
          // not continuous
          // check to make sure we aren't doing more fusions than requested
          return !_stopRequested && _completedFuseCount < fusionInfo.rounds;
        }
      }

      while (shouldFuzeAgain()) {
        if (_completedFuseCount > 0 || _failedFuseCount > 0) {
          _updateStatus(status: fusion.FusionStatus.reset);
          _updateStatus(
            status: fusion.FusionStatus.connecting,
            info: "Connecting to the CashFusion server.",
          );
        }

        //   refresh wallet utxos
        await updateUTXOs();

        // Add unfrozen stack UTXOs.
        final List<UTXO> walletUtxos = await mainDB
            .getUTXOs(walletId)
            .filter()
            .isBlockedEqualTo(false)
            .and()
            .addressIsNotNull()
            .findAll();

        final List<fusion.UtxoDTO> coinList = [];
        // Loop through UTXOs, checking and adding valid ones.
        for (final utxo in walletUtxos) {
          final String addressString = utxo.address!;
          final Set<String> possibleAddresses = {};

          if (bitbox.Address.detectFormat(addressString) ==
              bitbox.Address.formatCashAddr) {
            possibleAddresses.add(addressString);
            possibleAddresses.add(
              bitbox.Address.toLegacyAddress(addressString),
            );
          } else {
            possibleAddresses.add(addressString);
            possibleAddresses.add(convertAddressString(addressString));
          }

          // Fetch address to get pubkey
          final addr = await mainDB
              .getAddresses(walletId)
              .filter()
              .anyOf<String,
                      QueryBuilder<Address, Address, QAfterFilterCondition>>(
                  possibleAddresses, (q, e) => q.valueEqualTo(e))
              .and()
              .group((q) => q
                  .subTypeEqualTo(AddressSubType.change)
                  .or()
                  .subTypeEqualTo(AddressSubType.receiving))
              .and()
              .typeEqualTo(AddressType.p2pkh)
              .findFirst();

          // depending on the address type in the query above this can be null
          if (addr == null) {
            // A utxo object should always have a non null address.
            // If non found then just ignore the UTXO (aka don't fuse it)
            Logging.instance.log(
              "Ignoring utxo=$utxo for address=\"$addressString\" while selecting UTXOs for Fusion",
              level: LogLevel.Info,
            );
            continue;
          }

          final dto = fusion.UtxoDTO(
            txid: utxo.txid,
            vout: utxo.vout,
            value: utxo.value,
            address: utxo.address!,
            pubKey: addr.publicKey,
          );

          // Add UTXO to coinList.
          coinList.add(dto);
        }

        // Fuse UTXOs.
        try {
          if (coinList.isEmpty) {
            throw Exception("Started with no coins");
          }

          await _mainFusionObject!.fuse(
            inputsFromWallet: coinList,
            network: cryptoCurrency.networkParams,
          );

          // Increment the number of successfully completed fusion rounds.
          _completedFuseCount++;

          // Do the same for the UI state.  This also resets the failed count (for
          // the UI state only).
          _uiState?.incrementFusionRoundsCompleted();

          // Also reset the failed count here.
          _failedFuseCount = 0;
        } catch (e, s) {
          Logging.instance.log(
            "$e\n$s",
            level: LogLevel.Error,
          );
          // just continue on attempt failure

          // Increment the number of failed fusion rounds.
          _failedFuseCount++;

          // Do the same for the UI state.
          _uiState?.incrementFusionRoundsFailed();

          // If we have no coins, stop trying.
          if (coinList.isEmpty ||
              e.toString().contains("Started with no coins")) {
            _updateStatus(
                status: fusion.FusionStatus.failed,
                info: "Started with no coins, stopping.");
            _stopRequested = true;
            _uiState?.setFailed(true, shouldNotify: true);
          }

          // If we fail too many times in a row, stop trying.
          if (_failedFuseCount >= maxFailedFuseCount) {
            _updateStatus(
                status: fusion.FusionStatus.failed,
                info: "Failed $maxFailedFuseCount times in a row, stopping.");
            _stopRequested = true;
            _uiState?.setFailed(true, shouldNotify: true);
          }
        }
      }
    } catch (e, s) {
      Logging.instance.log(
        "$e\n$s",
        level: LogLevel.Error,
      );

      // Stop the fusion process and update the UI state.
      await _mainFusionObject?.stop();
      _mainFusionObject = null;
      _uiState?.setRunning(false, shouldNotify: true);
    }
  }

  /// Stop the fusion process.
  ///
  /// This function is called when the user taps the "Cancel" button in the UI
  /// or closes the fusion progress dialog.
  Future<void> stop() async {
    _stopRequested = true;
    await _mainFusionObject?.stop();
  }
}
