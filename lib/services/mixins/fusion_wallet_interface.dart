import 'dart:async';
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
  late final Future<Address> Function() _getNextUnusedChangeAddress;
  late final CachedElectrumX Function() _getWalletCachedElectrumX;
  late final Future<int> Function({
    required String address,
  }) _getTxCountForAddress;
  late final Future<int> Function() _getChainHeight;

  /// Initializes the FusionWalletInterface mixin.
  ///
  /// This function must be called before any other functions in this mixin.
  Future<void> initFusionInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
    required Future<Address> Function() getNextUnusedChangeAddress,
    required CachedElectrumX Function() getWalletCachedElectrumX,
    required Future<int> Function({
      required String address,
    }) getTxCountForAddress,
    required Future<int> Function() getChainHeight,
    required Future<String?> mnemonic,
    required Future<String?> mnemonicPassphrase,
    required btcdart.NetworkType network,
  }) async {
    // Set passed in wallet data.
    _walletId = walletId;
    _coin = coin;
    _db = db;
    _getNextUnusedChangeAddress = getNextUnusedChangeAddress;
    _torService = FusionTorService.sharedInstance;
    _getWalletCachedElectrumX = getWalletCachedElectrumX;
    _getTxCountForAddress = getTxCountForAddress;
    _getChainHeight = getChainHeight;
    _mnemonic = mnemonic;
    _mnemonicPassphrase = mnemonicPassphrase;
    _network = network;
  }

  // callback to update the ui state object
  void _updateStatus(fusion.FusionStatus fusionStatus) {
    switch (fusionStatus) {
      case fusion.FusionStatus.setup:
        _uiState?.connecting = CashFusionStatus.running;
        break;
      case fusion.FusionStatus.waiting:
        _uiState?.connecting = CashFusionStatus.success;
        _uiState?.outputs = CashFusionStatus.success;
        break;
      case fusion.FusionStatus.connecting:
        _uiState?.connecting = CashFusionStatus.waiting;
        break;
      case fusion.FusionStatus.running:
        _uiState?.connecting = CashFusionStatus.success;
        _uiState?.fusing = CashFusionStatus.running;
        break;
      case fusion.FusionStatus.complete:
        _uiState?.fusing = CashFusionStatus.success;
        _uiState?.complete = CashFusionStatus.success;
        break;
      case fusion.FusionStatus.failed:
        _uiState?.fusing = CashFusionStatus.failed;
        _uiState?.complete = CashFusionStatus.failed;
        break;
      case fusion.FusionStatus.exception:
        _uiState?.fusing = CashFusionStatus.failed;
        _uiState?.complete = CashFusionStatus.failed;
        break;
      case fusion.FusionStatus.reset:
        _uiState?.outputs = CashFusionStatus.waiting;
        _uiState?.peers = CashFusionStatus.waiting;
        _uiState?.connecting = CashFusionStatus.waiting;
        _uiState?.fusing = CashFusionStatus.waiting;
        _uiState?.complete = CashFusionStatus.waiting;
        _uiState?.fusionState = CashFusionStatus.waiting;
        break;
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
    } catch (_) {
      throw Exception("Derivation path for pubkey=$pubKey could not be found");
    }
  }

  /// Creates a new reserved change address.
  Future<Address> _createNewReservedChangeAddress() async {
    // _getNextUnusedChangeAddress() grabs the latest unused change address
    // from the wallet.
    // CopyWith to mark it as a fusion reserved change address
    final address = (await _getNextUnusedChangeAddress())
        .copyWith(otherData: kReservedFusionAddress);

    // Make sure the address is in the database as reserved for Fusion.
    final _address = await _db.getAddress(_walletId, address.value);
    if (_address != null) {
      await _db.updateAddress(_address, address);
    } else {
      await _db.putAddress(address);
    }

    return address;
  }

  /// Returns a list of unused reserved change addresses.
  ///
  /// If there are not enough unused reserved change addresses, new ones are created.
  Future<List<fusion.Address>> _getUnusedReservedChangeAddresses(
    int numberOfAddresses,
  ) async {
    // Fetch all reserved change addresses.
    final List<Address> reservedChangeAddresses = await _db
        .getAddresses(_walletId)
        .filter()
        .otherDataEqualTo(kReservedFusionAddress)
        .and()
        .subTypeEqualTo(AddressSubType.change)
        .findAll();

    // Initialize a list of unused reserved change addresses.
    final List<Address> unusedAddresses = [];

    // check addresses for tx history
    for (final address in reservedChangeAddresses) {
      // first check in db to avoid unnecessary network calls
      final txCountInDB = await _db
          .getTransactions(_walletId)
          .filter()
          .address((q) => q.valueEqualTo(address.value))
          .count();
      if (txCountInDB == 0) {
        // double check via electrumx
        // _getTxCountForAddress can throw!
        final count = await _getTxCountForAddress(address: address.value);
        if (count == 0) {
          unusedAddresses.add(address);
        }
      }
    }

    // If there are not enough unused reserved change addresses, create new ones.
    while (unusedAddresses.length < numberOfAddresses) {
      unusedAddresses.add(await _createNewReservedChangeAddress());
    }

    // Return the list of unused reserved change addresses.
    return unusedAddresses.sublist(0, numberOfAddresses).map((e) {
      final bool fusionReserved = e.otherData == kReservedFusionAddress;

      return fusion.Address(
        address: e.value,
        publicKey: e.publicKey,
        fusionReserved: fusionReserved,
        derivationPath: fusion.DerivationPath(
          e.derivationPath!.value,
        ),
      );
    }).toList();
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
  Future<void> fuse() async {
    // Initial attempt for CashFusion integration goes here.
    final mainFusionObject = fusion.Fusion(fusion.FusionParams());

    // Pass wallet functions to the Fusion object
    await mainFusionObject.initFusion(
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
    );

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
          .anyOf<String, QueryBuilder<Address, Address, QAfterFilterCondition>>(
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
    return await mainFusionObject.fuse(
      inputsFromWallet: coinList,
      network:
          _coin.isTestNet ? fusion.Utilities.testNet : fusion.Utilities.mainNet,
    );
  }

  Future<void> refreshFusion() {
    // TODO
    throw UnimplementedError(
        "TODO refreshFusion eg look up number of fusion participants connected/coordinating");
  }

  /// Testing ground for iterating thru the UI state.
  ///
  /// TODO remove this, just for development.
  Future<void> stepThruUiStates() async {
    // Define the list of states.
    final List<fusion.FusionStatus> states = [
      fusion.FusionStatus.setup,
      fusion.FusionStatus.waiting,
      fusion.FusionStatus.connecting,
      fusion.FusionStatus.running,
      fusion.FusionStatus.complete,
      fusion.FusionStatus.failed,
      fusion.FusionStatus.exception,
      fusion.FusionStatus.reset,
    ];

    // Iterate through the list of states, waiting one second between each.
    for (final state in states) {
      // Set the connecting status to the current state.
      _updateStatus(state);

      // Wait one second.
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
