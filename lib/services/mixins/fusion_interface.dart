import 'dart:io';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/services/cashfusion/fusion.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

mixin FusionInterface {
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;

  void initFusionInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
  }) {
    _walletId = walletId;
    _coin = coin;
    _db = db;
  }

  void fuse() async {
    // Initial attempt for CashFusion integration goes here.

    // await _updateUTXOs();
    List<UTXO> utxos = await _db.getUTXOs(_walletId).findAll();
    Fusion mainFusionObject = Fusion();
    await mainFusionObject.add_coins_from_wallet(utxos);
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
    throw UnimplementedError("TODO refreshFusion eg look up number of fusion participants connected/coordinating");
  }
}
