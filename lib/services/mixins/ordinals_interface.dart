import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/isar/ordinal.dart';
import 'package:stackwallet/services/litescribe_api.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

mixin OrdinalsInterface {
  late final String _walletId;
  late final Coin _coin;
  late final MainDB _db;

  void initOrdinalsInterface({
    required String walletId,
    required Coin coin,
    required MainDB db,
  }) {
    _walletId = walletId;
    _coin = coin;
    _db = db;
  }

  final LitescribeAPI litescribeAPI =
      LitescribeAPI(baseUrl: 'https://litescribe.io/api');

  Future<void> refreshInscriptions() async {
    final uniqueAddresses = await _db
        .getUTXOs(_walletId)
        .filter()
        .addressIsNotNull()
        .distinctByAddress()
        .addressProperty()
        .findAll();
    final inscriptions =
        await _getInscriptionDataFromAddresses(uniqueAddresses.cast<String>());

    final ords = inscriptions
        .map((e) => Ordinal.fromInscriptionData(e, _walletId))
        .toList();

    await _db.isar.writeTxn(() async {
      await _db.isar.ordinals
          .where()
          .filter()
          .walletIdEqualTo(_walletId)
          .deleteAll();
      await _db.isar.ordinals.putAll(ords);
    });
  }

  Future<List<InscriptionData>> _getInscriptionDataFromAddresses(
      List<String> addresses) async {
    List<InscriptionData> allInscriptions = [];
    for (String address in addresses) {
      try {
        var inscriptions =
            await litescribeAPI.getInscriptionsByAddress(address);
        allInscriptions.addAll(inscriptions);
      } catch (e) {
        throw Exception("Error fetching inscriptions for address $address: $e");
      }
    }
    return allInscriptions;
  }

  // check if an inscription is in a given <UTXO> output
  Future<bool> inscriptionInOutput(UTXO output) async {
    if (output.address != null) {
      var inscriptions =
          await litescribeAPI.getInscriptionsByAddress("${output.address}");
      if (inscriptions.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } else {
      throw UnimplementedError(
          'TODO look up utxo without address. utxo->txid:output->address');
    }
  }

  // check if an inscription is in a given <UTXO> output
  Future<bool> inscriptionInAddress(String address) async {
    var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
    if (inscriptions.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}
