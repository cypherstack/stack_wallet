import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/models/address.dart' as fusion_address;
import 'package:fusiondart/src/models/input.dart' as fusion_input;
import 'package:fusiondart/src/models/output.dart' as fusion_output;
import 'package:fusiondart/src/models/transaction.dart' as fusion_tx;
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/services/fusion_tor_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/extensions/impl/string.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

const String kReservedFusionAddress = "reserved_fusion_address";

/// A mixin for the BitcoinCashWallet class that adds CashFusion functionality.
mixin FusionWalletInterface {
  // Passed in wallet data.
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;
  late final FusionTorService _torService;

  // Passed in wallet functions.
  late final Future<Address> Function() _getNextUnusedChangeAddress;
  late final CachedElectrumX Function() _getWalletCachedElectrumX;

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
  }) async {
    // Set passed in wallet data.
    _walletId = walletId;
    _coin = coin;
    _db = db;
    _getNextUnusedChangeAddress = getNextUnusedChangeAddress;
    _torService = FusionTorService.sharedInstance;
    _getWalletCachedElectrumX = getWalletCachedElectrumX;
  }

  /// Returns a list of all addresses in the wallet.
  Future<List<fusion_address.Address>> getFusionAddresses() async {
    List<Address> _addresses = await _db.getAddresses(_walletId).findAll();
    return _addresses.map((address) => address.toFusionAddress()).toList();
  }

  /// Returns a list of all transactions in the wallet for the given address.
  Future<List<fusion_tx.Transaction>> getTransactionsByAddress(
      String address) async {
    final _txs = await _db.getTransactions(_walletId).findAll();

    // Use Future.wait to await all the futures in the set and then convert it to a set.
    final resultSet = await Future.wait(
      _txs.map(
        (tx) => tx.toFusionTransaction(
          dbInstance: _db,
          cachedElectrumX: _getWalletCachedElectrumX(),
        ),
      ),
    );

    return resultSet;
  }

  /// Returns a list of all UTXOs in the wallet for the given address.
  Future<List<fusion_input.Input>> getInputsByAddress(String address) async {
    final _utxos = await _db.getUTXOsByAddress(_walletId, address).findAll();

    List<Future<fusion_input.Input>> futureInputs = _utxos
        .map(
          (utxo) => utxo.toFusionInput(
            walletId: _walletId,
            dbInstance: _db,
          ),
        )
        .toList();

    return await Future.wait(futureInputs);
  }

  /// Creates a new reserved change address.
  Future<fusion_address.Address> createNewReservedChangeAddress() async {
    // _getNextUnusedChangeAddress() grabs the latest unused change address
    // from the wallet.
    // CopyWith to mark it as a fusion reserved change address
    final address = (await _getNextUnusedChangeAddress())
        .copyWith(otherData: kReservedFusionAddress);

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
  Future<List<fusion_address.Address>> getUnusedReservedChangeAddresses(
    int numberOfAddresses,
  ) async {
    // Fetch all transactions that have been sent to a reserved change address.
    final txns = await _db
        .getTransactions(_walletId)
        .filter()
        .address((q) => q
            .otherDataEqualTo(kReservedFusionAddress)
            .and()
            .subTypeEqualTo(AddressSubType.change))
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
        .and()
        .subTypeEqualTo(AddressSubType.change)
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
    final mainFusionObject = Fusion(
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
      getSocksProxyAddress: getSocksProxyAddress,
    );

    // Add stack UTXOs.
    final List<UTXO> walletUtxos = await _db.getUTXOs(_walletId).findAll();
    final List<
        ({
          String txid,
          int vout,
          int value,
          List<int> pubKey,
        })> coinList = [];

    // Loop through UTXOs, checking and adding valid ones.
    for (final utxo in walletUtxos) {
      // Check if address is available.
      if (utxo.address == null) {
        // TODO we could continue here (and below during scriptPubKey validation) instead of throwing.
        throw Exception("UTXO ${utxo.txid}:${utxo.vout} address is null");
      }

      // Find public key.
      Map<String, dynamic> tx =
          await _getWalletCachedElectrumX().getTransaction(
        coin: _coin,
        txHash: utxo.txid,
        verbose: true,
      );

      // Check if scriptPubKey is available.
      final scriptPubKeyHex =
          tx["vout"]?[utxo.vout]?["scriptPubKey"]?["hex"] as String?;
      if (scriptPubKeyHex == null) {
        throw Exception(
          "hex in scriptPubKey of vout index ${utxo.vout} in transaction is null",
        );
      }

      // Assign scriptPubKey to pubKey.  TODO verify this is correct.
      List<int> pubKey = scriptPubKeyHex.toUint8ListFromHex;

      // Add UTXO to coinList.
      coinList.add((
        txid: utxo.txid,
        vout: utxo.vout,
        value: utxo.value,
        pubKey: pubKey
      ));
    }

    // Add Stack UTXOs.
    await mainFusionObject.addCoinsFromWallet(coinList);

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

/// An extension of Stack Wallet's Address class that adds CashFusion functionality.
extension FusionAddress on Address {
  fusion_address.Address toFusionAddress() {
    if (derivationPath == null) {
      // throw Exception("Fusion Addresses require a derivation path");
      // TODO calculate a derivation path if it is null.
    }

    return fusion_address.Address(
      addr: value,
      publicKey: publicKey,
      derivationPath: fusion_address.DerivationPath(
        derivationPath?.value ?? "", // TODO fix null derivation path.
      ),
    );
  }
}

/// An extension of Stack Wallet's UTXO class that adds CashFusion functionality.
///
/// This class is used to convert Stack Wallet's UTXO class to FusionDart's
/// Input and Output classes.
extension FusionUTXO on UTXO {
  /// Fetch the public key of an address stored in the database.
  Future<Address> _getAddressPubkey({
    required String address,
    required String walletId,
    required MainDB dbInstance,
  }) async {
    final Address? addr = await dbInstance.getAddress(walletId, address);

    if (addr == null) {
      throw Exception("Address not found");
    }

    return addr;
  }

  /// Converts a Stack Wallet UTXO to a FusionDart Input.
  Future<fusion_input.Input> toFusionInput({
    required String walletId,
    required MainDB dbInstance,
  }) async {
    if (address == null) {
      throw Exception("toFusionInput Address is null");
    }

    try {
      final Address addr = await _getAddressPubkey(
        address: address!,
        walletId: walletId,
        dbInstance: dbInstance,
      );

      if (addr.publicKey.isEmpty) {
        throw Exception("Public key for fetched address is empty");
      }

      return fusion_input.Input(
        prevTxid: utf8.encode(txid),
        prevIndex: vout,
        pubKey: addr.publicKey,
        amount: value,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Converts a Stack Wallet UTXO to a FusionDart Output.
  Future<fusion_output.Output> toFusionOutput({
    required String walletId,
    required MainDB dbInstance,
  }) async {
    if (address == null) {
      throw Exception("toFutionOutput Address is null");
    }

    // Search isar for address to get pubKey.
    final Address addr = await _getAddressPubkey(
      address: address!,
      walletId: walletId,
      dbInstance: dbInstance,
    );

    if (addr.publicKey.isEmpty) {
      throw Exception("Public key for fetched address is empty");
    }

    if (addr.derivationPath == null) {
      throw Exception("Derivation path for fetched address is empty");
    }

    return fusion_output.Output(
      addr: fusion_address.Address(
        addr: address!,
        publicKey: addr.publicKey,
        derivationPath: fusion_address.DerivationPath(
          addr.derivationPath!.value,
        ),
      ),
      value: value,
    );
  }
}

/// An extension of Stack Wallet's Transaction class that adds CashFusion functionality.
extension FusionTransaction on Transaction {
  /// Fetch the public key of an address stored in the database.
  Future<String?> _getAddressDerivationPathString({
    required String address,
    required MainDB dbInstance,
  }) async {
    final Address? addr = await dbInstance.getAddress(walletId, address);

    return addr?.derivationPath?.value;
  }

  // WIP.
  Future<fusion_tx.Transaction> toFusionTransaction({
    required CachedElectrumX cachedElectrumX,
    required MainDB dbInstance,
  }) async {
    // Initialize Fusion Dart's Transaction object.
    fusion_tx.Transaction fusionTransaction = fusion_tx.Transaction();

    // WIP.
    fusionTransaction.Inputs = await Future.wait(inputs.map((input) async {
      // Find input amount.
      Map<String, dynamic> _tx = await cachedElectrumX.getTransaction(
        coin: Coin.bitcoincash,
        txHash: input.txid,
        verbose: true,
      );

      if (_tx.isEmpty) {
        throw Exception("Transaction not found for input: ${input.txid}");
      }

      // Check if output amount is available.
      final txVoutAmount = Decimal.tryParse(
        _tx["vout"]?[input.vout]?["value"].toString() ?? "",
      );
      if (txVoutAmount == null) {
        throw Exception(
          "Output value at index ${input.vout} in transaction ${input.txid} not found",
        );
      }

      final scriptPubKeyHex =
          _tx["vout"]?[input.vout]?["scriptPubKey"]?["hex"] as String?;
      if (scriptPubKeyHex == null) {
        throw Exception(
          "scriptPubKey of vout index ${input.vout} in transaction is null",
        );
      }

      // Assign vout value to amount.
      final value = Amount.fromDecimal(
        txVoutAmount,
        fractionDigits: Coin.bitcoincash.decimals,
      );

      return fusion_input.Input(
        prevTxid: utf8.encode(input.txid),
        prevIndex: input.vout,
        pubKey: scriptPubKeyHex.toUint8ListFromHex,
        amount: value.raw.toInt(),
      );
    }).toList());

    fusionTransaction.Outputs = await Future.wait(outputs.map((output) async {
      // TODO: maybe only need one of these but IIRC scriptPubKeyAddress is required for bitcoincash transactions?
      if (output.scriptPubKeyAddress.isEmpty) {
        throw Exception("isar model output.scriptPubKeyAddress is empty!");
      }
      if (output.scriptPubKey == null || output.scriptPubKey!.isEmpty) {
        throw Exception("isar model output.scriptPubKey is null or empty!");
      }

      final outputAddress = output.scriptPubKeyAddress;
      final outputAddressScriptPubKey = output.scriptPubKey!.toUint8ListFromHex;

      // fetch address derivation path
      final derivationPathString = await _getAddressDerivationPathString(
        address: outputAddress,
        dbInstance: dbInstance,
      );

      final fusion_address.DerivationPath? derivationPath;
      if (derivationPathString == null) {
        // TODO: check on this:
        // The address is not an address of this wallet and in that case we
        // cannot know the derivation path
        derivationPath = null;
      } else {
        derivationPath = fusion_address.DerivationPath(
          derivationPathString,
        );
      }

      return fusion_output.Output(
        addr: fusion_address.Address(
          addr: output.scriptPubKeyAddress,
          publicKey: outputAddressScriptPubKey,
          derivationPath: derivationPath,
        ),
        value: output.value,
      );
    }).toList());

    return fusionTransaction;
  }
}
