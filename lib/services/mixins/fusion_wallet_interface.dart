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
  ///
  /// Returns a `Future<void>` that resolves when Tor has been started.
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
  void updateStatus(fusion.FusionStatus fusionStatus) {
    // TODO: this
    // set _uiState states
  }

  /// Returns a list of all owned p2pkh addresses in the wallet.
  Future<List<fusion.Address>> getFusionAddresses() async {
    List<Address> _addresses = await _db
        .getAddresses(_walletId)
        .filter()
        .typeEqualTo(AddressType.p2pkh)
        .and()
        .group((q) => q
            .subTypeEqualTo(AddressSubType.receiving)
            .or()
            .subTypeEqualTo(AddressSubType.change))
        .findAll();

    return _addresses.map((address) => address.toFusionAddress()).toList();
  }

  /// Returns a list of all transactions in the wallet for the given address.
  Future<List<Map<String, dynamic>>> getTransactionsByAddress(
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

  Future<Uint8List> getPrivateKeyForPubKey(List<int> pubKey) async {
    // can't directly query for equal lists in isar so we need to fetch
    // all addresses then search in dart
    try {
      final derivationPath = (await getFusionAddresses())
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
  Future<fusion.Address> createNewReservedChangeAddress() async {
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

    return address.toFusionAddress();
  }

  /// Returns a list of unused reserved change addresses.
  ///
  /// If there are not enough unused reserved change addresses, new ones are created.
  Future<List<fusion.Address>> getUnusedReservedChangeAddresses(
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
    final List<fusion.Address> unusedAddresses = [];

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
          unusedAddresses.add(address.toFusionAddress());
        }
      }
    }

    // If there are not enough unused reserved change addresses, create new ones.
    while (unusedAddresses.length < numberOfAddresses) {
      unusedAddresses.add(await createNewReservedChangeAddress());
    }

    // Return the list of unused reserved change addresses.
    return unusedAddresses.sublist(0, numberOfAddresses);
  }

  int _torStartCount = 0;

  /// Returns the current Tor proxy address.
  Future<({InternetAddress host, int port})> getSocksProxyAddress() async {
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
      return await getSocksProxyAddress();
    }
  }

  // Initial attempt for CashFusion integration goes here.

  /// Fuse the wallet's UTXOs.
  ///
  /// This function is called when the user taps the "Fuse" button in the UI.
  ///
  /// Returns:
  ///   A `Future<void>` that resolves when the fusion operation is finished.
  Future<void> fuse() async {
    // Initial attempt for CashFusion integration goes here.
    final mainFusionObject = fusion.Fusion(fusion.FusionParams());

    // Pass wallet functions to the Fusion object
    await mainFusionObject.initFusion(
      getAddresses: getFusionAddresses,
      getTransactionsByAddress: getTransactionsByAddress,
      getUnusedReservedChangeAddresses: getUnusedReservedChangeAddresses,
      getSocksProxyAddress: getSocksProxyAddress,
      getChainHeight: _getChainHeight,
      updateStatusCallback: updateStatus,
      getTransactionJson: (String txid) async =>
          await _getWalletCachedElectrumX().getTransaction(
        coin: _coin,
        txHash: txid,
      ),
      getPrivateKeyForPubKey: getPrivateKeyForPubKey,
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
}

/// An extension of Stack Wallet's Address class that adds CashFusion functionality.
extension FusionAddress on Address {
  fusion.Address toFusionAddress() {
    if (derivationPath == null) {
      // throw Exception("Fusion Addresses require a derivation path");
      // TODO calculate a derivation path if it is null.
    }

    final bool fusionReserved = otherData == kReservedFusionAddress;

    return fusion.Address(
      address: value,
      publicKey: publicKey,
      fusionReserved: fusionReserved,
      derivationPath: fusion.DerivationPath(
        derivationPath?.value ?? "", // TODO fix null derivation path.
      ),
    );
  }
}
