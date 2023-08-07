import 'dart:io';

import 'package:fusiondart/fusiondart.dart';
import 'package:fusiondart/src/models/address.dart' as fusion_address;
import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/logger.dart';

mixin FusionInterface {
  // passed in wallet data
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;

  // passed in wallet functions
  late final Future<String> Function() _getCurrentChangeAddress;

  void initFusionInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
    required Future<String> Function() getCurrentChangeAddress,
  }) {
    _walletId = walletId;
    _coin = coin;
    _db = db;
    _getCurrentChangeAddress = getCurrentChangeAddress;
  }

  static List<Address> reserve_change_addresses(int number_addresses) {
    // TODO
    // get current change address
    // get int number_addresses next addresses
    return [];
  }

  static List<Address> unreserve_change_address(Address addr) {
    //implement later based on wallet.
    return [];
  }

  void fuse() async {
    // Initial attempt for CashFusion integration goes here.
    Fusion mainFusionObject = Fusion();

    // add stack utxos
    List<UTXO> utxos = await _db.getUTXOs(_walletId).findAll();
    await mainFusionObject.add_coins_from_wallet(utxos
        .map((e) => (txid: e.txid, vout: e.vout, value: e.value))
        .toList());

    // add stack change address
    final String currentChangeAddress = await _getCurrentChangeAddress();
    // cast from String to Address
    final Address? changeAddress =
        await _db.getAddress(_walletId, currentChangeAddress);
    // cast from Stack's Address to Fusiondart's Address
    final fusion_address.Address fusionChangeAddress =
        changeAddress!.toFusionAddress();
    await mainFusionObject.addChangeAddress(fusionChangeAddress);
    Logging.instance.log(
      "FusionInterface fuse() changeAddress: $changeAddress",
      level: LogLevel.Info,
    );

    // fuse utxos
    await mainFusionObject.fusion_run();
    //print ("DEBUG FUSION bitcoincash_wallet.dart 1202");

    /*
    print("DEBUG: Waiting for any potential incoming data...");
    try {
      await Future.delayed(Duration(seconds: 5)); // wait for 5 seconds
    }
    catch (e) {
      print (e);
    }
    print("DEBUG: Done waiting.");
    */

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
  }

  Future<void> refreshFusion() {
    // TODO
    throw UnimplementedError(
        "TODO refreshFusion eg look up number of fusion participants connected/coordinating");
  }
}
