import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bitcoindart/bitcoindart.dart' as btcdart;
import 'package:fusiondart/fusiondart.dart' as fusion;
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/models/fusion_progress_ui_state.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/pages_desktop_specific/cashfusion/sub_widgets/fusion_dialog.dart';
import 'package:stackwallet/services/fusion_tor_service.dart';
import 'package:stackwallet/utilities/bip32_utils.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

const String kReservedFusionAddress = "reserved_fusion_address";

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

  // TODO update defaults
  static const DEFAULTS = FusionInfo(
    host: "cashfusion.stackwallet.com",
    port: 8787,
    ssl: false,
    rounds: 0, // 0 is continuous
  );

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

/// A mixin for the BitcoinCashWallet class that adds CashFusion functionality.
mixin FusionWalletInterface {
  // Passed in wallet data.
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;
  late final FusionTorService _torService;
  late final Future<String?> _mnemonic;
  late final Future<String?> _mnemonicPassphrase;
  late final btcdart.NetworkType _network;

  // setting values on this should notify any listeners (the GUI)
  FusionProgressUIState? _uiState;
  FusionProgressUIState get uiState {
    if (_uiState == null) {
      throw Exception("FusionProgressUIState has not been set for $_walletId");
    }
    return _uiState!;
  }

  set uiState(FusionProgressUIState state) {
    if (_uiState != null) {
      throw Exception("FusionProgressUIState was already set for $_walletId");
    }
    _uiState = state;
  }

  // Passed in wallet functions.
  late final Future<List<Address>> Function({int numberOfAddresses})
      _getNextUnusedChangeAddresses;
  late final CachedElectrumX Function() _getWalletCachedElectrumX;
  late final Future<int> Function() _getChainHeight;
  late final Future<void> Function() _updateWalletUTXOS;

  // Fusion object.
  fusion.Fusion? _mainFusionObject;
  bool _stopRequested = false;

  /// An int storing the number of successfully completed fusion rounds.
  int _completedFuseCount = 0;

  /// An int storing the number of failed fusion rounds.
  int _failedFuseCount = 0;

  /// The maximum number of consecutive failed fusion rounds before stopping.
  int get maxFailedFuseCount => 5;

  /// Initializes the FusionWalletInterface mixin.
  ///
  /// This function must be called before any other functions in this mixin.
  Future<void> initFusionInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
    required Future<List<Address>> Function({int numberOfAddresses})
        getNextUnusedChangeAddress,
    required CachedElectrumX Function() getWalletCachedElectrumX,
    required Future<int> Function() getChainHeight,
    required Future<void> Function() updateWalletUTXOS,
    required Future<String?> mnemonic,
    required Future<String?> mnemonicPassphrase,
    required btcdart.NetworkType network,
  }) async {
    // Set passed in wallet data.
    _walletId = walletId;
    _coin = coin;
    _db = db;
    _getNextUnusedChangeAddresses = getNextUnusedChangeAddress;
    _torService = FusionTorService.sharedInstance;
    _getWalletCachedElectrumX = getWalletCachedElectrumX;
    _getChainHeight = getChainHeight;
    _updateWalletUTXOS = updateWalletUTXOS;
    _mnemonic = mnemonic;
    _mnemonicPassphrase = mnemonicPassphrase;
    _network = network;
  }

  // callback to update the ui state object
  void _updateStatus({required fusion.FusionStatus status, String? info}) {
    switch (status) {
      case fusion.FusionStatus.connecting:
        _uiState?.connecting = CashFusionState(
            status: CashFusionStatus.running,
            info:
                null); // We only want to show error messages for failed states.
        break;
      case fusion.FusionStatus.setup:
        _uiState?.connecting =
            CashFusionState(status: CashFusionStatus.success, info: null);
        _uiState?.outputs =
            CashFusionState(status: CashFusionStatus.running, info: null);
        break;
      case fusion.FusionStatus.waiting:
        _uiState?.outputs =
            CashFusionState(status: CashFusionStatus.success, info: null);
        _uiState?.peers =
            CashFusionState(status: CashFusionStatus.running, info: null);
        break;
      case fusion.FusionStatus.running:
        _uiState?.peers =
            CashFusionState(status: CashFusionStatus.success, info: null);
        _uiState?.fusing =
            CashFusionState(status: CashFusionStatus.running, info: null);
        break;
      case fusion.FusionStatus.complete:
        _uiState?.fusing =
            CashFusionState(status: CashFusionStatus.success, info: null);
        _uiState?.complete =
            CashFusionState(status: CashFusionStatus.success, info: null);
        break;
      case fusion.FusionStatus.failed:
        // _uiState?.fusing = CashFusionStatus.failed;
        // _uiState?.complete =
        //     CashFusionState(status: CashFusionStatus.failed, info: info);

        failCurrentUiState(info);

        break;
      case fusion.FusionStatus.exception:
        // _uiState?.complete =
        //     CashFusionState(status: CashFusionStatus.failed, info: info);

        failCurrentUiState(info);
        break;
      case fusion.FusionStatus.reset:
        _uiState?.outputs =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        _uiState?.peers =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        _uiState?.connecting =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        _uiState?.fusing =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        _uiState?.complete =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        _uiState?.fusionState =
            CashFusionState(status: CashFusionStatus.waiting, info: info);
        break;
    }
  }

  void failCurrentUiState(String? info) {
    // Check each _uiState value to see if it is running.  If so, set it to failed.
    if (_uiState?.connecting.status == CashFusionStatus.running) {
      _uiState?.connecting =
          CashFusionState(status: CashFusionStatus.failed, info: info);
      return;
    }
    if (_uiState?.outputs.status == CashFusionStatus.running) {
      _uiState?.outputs =
          CashFusionState(status: CashFusionStatus.failed, info: info);
      return;
    }
    if (_uiState?.peers.status == CashFusionStatus.running) {
      _uiState?.peers =
          CashFusionState(status: CashFusionStatus.failed, info: info);
      return;
    }
    if (_uiState?.fusing.status == CashFusionStatus.running) {
      _uiState?.fusing =
          CashFusionState(status: CashFusionStatus.failed, info: info);
      return;
    }
    if (_uiState?.complete.status == CashFusionStatus.running) {
      _uiState?.complete =
          CashFusionState(status: CashFusionStatus.failed, info: info);
      return;
    }
  }

  /// Returns a list of all transactions in the wallet for the given address.
  Future<List<Map<String, dynamic>>> _getTransactionsByAddress(
    String address,
  ) async {
    final txidList =
        await _db.getTransactions(_walletId).txidProperty().findAll();

    final futures = txidList.map(
      (e) => _getWalletCachedElectrumX().getTransaction(
        txHash: e,
        coin: _coin,
      ),
    );

    return await Future.wait(futures);
  }

  Future<Uint8List> _getPrivateKeyForPubKey(List<int> pubKey) async {
    // can't directly query for equal lists in isar so we need to fetch
    // all addresses then search in dart
    try {
      final derivationPath = (await _db
              .getAddresses(_walletId)
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

      final node = await Bip32Utils.getBip32Node(
        (await _mnemonic)!,
        (await _mnemonicPassphrase)!,
        _network,
        derivationPath,
      );

      return node.privateKey!;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
      throw Exception("Derivation path for pubkey=$pubKey could not be found");
    }
  }

  /// Reserve an address for fusion.
  Future<Address> _reserveAddress(Address address) async {
    address = address.copyWith(otherData: kReservedFusionAddress);

    // Make sure the address is updated in the database as reserved for Fusion.
    final _address = await _db.getAddress(_walletId, address.value);
    if (_address != null) {
      await _db.updateAddress(_address, address);
    } else {
      await _db.putAddress(address);
    }

    return address;
  }

  /// un reserve a fusion reserved address.
  /// If [address] is not reserved nothing happens
  Future<Address> _unReserveAddress(Address address) async {
    if (address.otherData != kReservedFusionAddress) {
      return address;
    }

    final updated = address.copyWith(otherData: null);

    // Make sure the address is updated in the database.
    await _db.updateAddress(address, updated);

    return updated;
  }

  /// Returns a list of unused reserved change addresses.
  ///
  /// If there are not enough unused reserved change addresses, new ones are created.
  Future<List<fusion.Address>> _getUnusedReservedChangeAddresses(
    int numberOfAddresses,
  ) async {
    final unusedChangeAddresses = await _getNextUnusedChangeAddresses(
      numberOfAddresses: numberOfAddresses,
    );

    // Initialize a list of unused reserved change addresses.
    final List<Address> unusedReservedAddresses = [];
    for (final address in unusedChangeAddresses) {
      unusedReservedAddresses.add(await _reserveAddress(address));
    }

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

  int _torStartCount = 0;

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

  // Initial attempt for CashFusion integration goes here.

  /// Fuse the wallet's UTXOs.
  ///
  /// This function is called when the user taps the "Fuse" button in the UI.
  Future<void> fuse({
    required FusionInfo fusionInfo,
  }) async {
    // Initial attempt for CashFusion integration goes here.

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
    );

    // Instantiate a Fusion object with custom parameters.
    _mainFusionObject = fusion.Fusion(serverParams);

    // Pass wallet functions to the Fusion object
    await _mainFusionObject!.initFusion(
      getTransactionsByAddress: _getTransactionsByAddress,
      getUnusedReservedChangeAddresses: _getUnusedReservedChangeAddresses,
      getSocksProxyAddress: _getSocksProxyAddress,
      getChainHeight: _getChainHeight,
      updateStatusCallback: _updateStatus,
      getTransactionJson: (String txid) async =>
          await _getWalletCachedElectrumX().getTransaction(
        coin: _coin,
        txHash: txid,
      ),
      getPrivateKeyForPubKey: _getPrivateKeyForPubKey,
      broadcastTransaction: (String txHex) => _getWalletCachedElectrumX()
          .electrumXClient
          .broadcastTransaction(rawTx: txHex),
      unReserveAddresses: (List<fusion.Address> addresses) async {
        final List<Future<void>> futures = [];
        for (final addr in addresses) {
          futures.add(
            _db.getAddress(_walletId, addr.address).then(
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
      await _updateWalletUTXOS();

      // Add unfrozen stack UTXOs.
      final List<UTXO> walletUtxos = await _db
          .getUTXOs(_walletId)
          .filter()
          .isBlockedEqualTo(false)
          .and()
          .addressIsNotNull()
          .findAll();

      final List<fusion.UtxoDTO> coinList = [];
      // Loop through UTXOs, checking and adding valid ones.
      for (final utxo in walletUtxos) {
        final String addressString = utxo.address!;
        final List<String> possibleAddresses = [addressString];

        if (bitbox.Address.detectFormat(addressString) ==
            bitbox.Address.formatCashAddr) {
          possibleAddresses.add(bitbox.Address.toLegacyAddress(addressString));
        } else {
          possibleAddresses.add(bitbox.Address.toCashAddress(addressString));
        }

        // Fetch address to get pubkey
        final addr = await _db
            .getAddresses(_walletId)
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
        await _mainFusionObject!.fuse(
          inputsFromWallet: coinList,
          network: _coin.isTestNet
              ? fusion.Utilities.testNet
              : fusion.Utilities.mainNet,
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

        // If we fail too many times in a row, stop trying.
        if (_failedFuseCount >= maxFailedFuseCount) {
          _updateStatus(
              status: fusion.FusionStatus.failed,
              info: "Failed $maxFailedFuseCount times in a row, stopping.");
          _stopRequested = true;
          _uiState?.failed = true;
        }
      }
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
