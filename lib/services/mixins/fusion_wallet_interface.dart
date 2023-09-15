import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/models/address.dart' as fusion_address;
import 'package:fusiondart/src/models/input.dart' as fusion_input;
import 'package:fusiondart/src/models/transaction.dart' as fusion_tx;
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';

const String kReservedFusionAddress = "reserved_fusion_address";

/// A mixin for the BitcoinCashWallet class that adds CashFusion functionality.
mixin FusionWalletInterface {
  // Passed in wallet data.
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;
  late final TorService _torService;

  // Passed in wallet functions.
  late final Future<Address> Function(
    int chain,
    int index,
    DerivePathType derivePathType,
  ) _generateAddressForChain;

  void initFusionInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
    required Future<Address> Function(
      int,
      int,
      DerivePathType,
    ) generateAddressForChain,
  }) {
    _walletId = walletId;
    _coin = coin;
    _db = db;
    _generateAddressForChain = generateAddressForChain;
    _torService = TorService.sharedInstance;

    // Start the Tor service if it's not already running.
    // TODO fix this.  It will cause all Stack Wallet traffic to start being routed
    // through Tor, which is not what we want.
    if (_torService.proxyInfo.port == -1) {
      // -1 indicates that the proxy is not running.
      // Initialize the ffi lib instance if it hasn't already been set.
      _torService.init();

      // Start the Tor service.
      //
      // TODO should we await this?  At this point I don't want to make this init function async.
      // The risk would be that the Tor service is not started before the Fusion library tries to
      // connect to it.
      unawaited(_torService.start());
    }
  }

  /// Returns a list of all addresses in the wallet.
  Future<List<fusion_address.Address>> getFusionAddresses() async {
    List<Address> _addresses = await _db.getAddresses(_walletId).findAll();
    return _addresses.map((address) => address.toFusionAddress()).toList();
  }

  /// Returns a list of all transactions in the wallet for the given address.
  Future<Set<fusion_tx.Transaction>> getTransactionsByAddress(
      String address) async {
    var _txs = await _db.getTransactions(_walletId).findAll();

    return _txs
        .map((tx) => tx.toFusionTransaction())
        .toSet(); // TODO feed in proper public key
  }

  /// Returns a list of all UTXOs in the wallet for the given address.
  Future<List<fusion_input.Input>> getInputsByAddress(String address) async {
    var _utxos = await _db.getUTXOsByAddress(_walletId, address).findAll();

    return _utxos
        .map((utxo) => utxo.toFusionInput(
            pubKey: utf8.encode('0000'))) // TODO feed in proper public key
        .toList();
  }

  /// Creates a new reserved change address.
  Future<fusion_address.Address> createNewReservedChangeAddress() async {
    int? highestChangeIndex = await _db
        .getAddresses(_walletId)
        .filter()
        .typeEqualTo(AddressType.p2pkh)
        .subTypeEqualTo(AddressSubType.change)
        .derivationPath((q) => q.not().valueStartsWith("m/44'/0'"))
        .sortByDerivationIndexDesc()
        .derivationIndexProperty()
        .findFirst();

    Address address = await _generateAddressForChain(
      1, // change chain
      highestChangeIndex ?? 0,
      DerivePathTypeExt.primaryFor(_coin),
    );
    address = address.copyWith(otherData: kReservedFusionAddress);

    // TODO if we really want to be sure it's not used, call electrumx and check it

    Address? _address = await _db.getAddress(_walletId, address.value);
    if (_address != null) {
      // throw Exception("Address already exists");
      await _db.updateAddress(_address, address);
    } else {
      await _db.putAddress(address);
    }

    return address.toFusionAddress();
  }

  /// Returns a list of unused reserved change addresses.
  ///
  /// If there are not enough unused reserved change addresses, new ones are created.
  Future<List<fusion_address.Address>> getUnusedReservedChangeAddresses(
    int numberOfAddresses,
  ) async {
    // Fetch all transactions that have been sent to a reserved change address.
    final txns = await _db
        .getTransactions(_walletId)
        .filter()
        .address((q) => q.otherDataEqualTo(kReservedFusionAddress))
        .findAll();

    // Fetch all addresses that have been used in a transaction.
    final List<String> usedAddresses = txns
        .where((e) => e.address.value != null)
        .map((e) => e.address.value!.value)
        .toList(growable: false);

    // Fetch all reserved change addresses.
    final List<Address> addresses = await _db
        .getAddresses(_walletId)
        .filter()
        .otherDataEqualTo(kReservedFusionAddress)
        .findAll();

    // Initialize a list of unused reserved change addresses.
    final List<fusion_address.Address> unusedAddresses = [];

    // Add any unused reserved change addresses to the list.
    for (final address in addresses) {
      if (!usedAddresses.contains(address.value)) {
        unusedAddresses.add(address.toFusionAddress());
      }
    }

    // If there are not enough unused reserved change addresses, create new ones.
    if (unusedAddresses.length < numberOfAddresses) {
      for (int i = unusedAddresses.length; i < numberOfAddresses; i++) {
        unusedAddresses.add(await createNewReservedChangeAddress());
      }
    }

    // Return the list of unused reserved change addresses.
    return unusedAddresses;
  }

  /// Returns the current Tor proxy address.
  Future<({InternetAddress host, int port})> getSocksProxyAddress() async {
    /*
    // Start the Tor service if it's not already running.
    if (_torService.proxyInfo.port == -1) { // -1 indicates that the proxy is not running.
      await _torService.start(); // We already unawaited this in initFusionInterface...
    }
     */

    // TODO make sure we've properly awaited the Tor service starting before
    // returning the proxy address.

    // Return the proxy address.
    return _torService.proxyInfo;
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
    Fusion mainFusionObject = Fusion(
      getAddresses: () => getFusionAddresses(),
      getTransactionsByAddress: (String address) =>
          getTransactionsByAddress(address),
      getInputsByAddress: (String address) => getInputsByAddress(address),
      // createNewReservedChangeAddress: () => createNewReservedChangeAddress(),
      getUnusedReservedChangeAddresses: (int numberOfAddresses) =>
          getUnusedReservedChangeAddresses(numberOfAddresses),
      getSocksProxyAddress: () => getSocksProxyAddress(),
    );

    // Pass wallet functions to the Fusion object
    mainFusionObject.initFusion(
        getAddresses: getFusionAddresses,
        getTransactionsByAddress: getTransactionsByAddress,
        getInputsByAddress: getInputsByAddress,
        /*createNewReservedChangeAddress: createNewReservedChangeAddress,*/
        getUnusedReservedChangeAddresses: getUnusedReservedChangeAddresses,
        getSocksProxyAddress: getSocksProxyAddress);

    // Add stack UTXOs.
    List<UTXO> utxos = await _db.getUTXOs(_walletId).findAll();

    await mainFusionObject.addCoinsFromWallet(
        utxos.map((e) => (e.txid, e.vout, e.value)).toList());

    // Fuse UTXOs.
    return await mainFusionObject.fuse();
    //print ("DEBUG FUSION bitcoincash_wallet.dart 1202");

    // TODO remove or fix code below.

    /*
    print("DEBUG: Waiting for any potential incoming data...");
    try {
      await Future.delayed(Duration(seconds: 5)); // wait for 5 seconds
    }
    catch (e) {
      print (e);
    }
    print("DEBUG: Done waiting.");

    bool mydebug1 = false;
    if (mydebug1 == true) {
      var serverIp = '167.114.119.46';
      var serverPort = 8787;

      List<int> frame = [
        118,
        91,
        232,
        180,
        228,
        57,
        109,
        207,
        0,
        0,
        0,
        45,
        10,
        43,
        10,
        7,
        97,
        108,
        112,
        104,
        97,
        49,
        51,
        18,
        32,
        111,
        226,
        140,
        10,
        182,
        241,
        179,
        114,
        193,
        166,
        162,
        70,
        174,
        99,
        247,
        79,
        147,
        30,
        131,
        101,
        225,
        90,
        8,
        156,
        104,
        214,
        25,
        0,
        0,
        0,
        0,
        0
      ];
      print("lets try to connect to a socket again");
      var socket = await Socket.connect(serverIp, serverPort);

      print('Connected to the server.');
      socket.add(frame);
      print('Sent frame: $frame');

      socket.listen((data) {
        print('Received from server: $data');
      }, onDone: () {
        print('Server closed connection.');
        socket.destroy();
      }, onError: (error) {
        print('Error: $error');
        socket.destroy();
      });
    }

    // await _checkCurrentChangeAddressesForTransactions();
    // await _checkCurrentReceivingAddressesForTransactions();
    */
  }

  Future<void> refreshFusion() {
    // TODO
    throw UnimplementedError(
        "TODO refreshFusion eg look up number of fusion participants connected/coordinating");
  }
}
