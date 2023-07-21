import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/models/ordinal.dart';
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
    print('init');
    _walletId = walletId;
    _coin = coin;
    _db = db;
  }
  final LitescribeAPI litescribeAPI = LitescribeAPI(baseUrl: 'https://litescribe.io/api');

  void refreshInscriptions() async {
    List<dynamic> _inscriptions;
    final utxos = await _db.getUTXOs(_walletId).findAll();
    final uniqueAddresses = getUniqueAddressesFromUTXOs(utxos);
    _inscriptions = await getInscriptionDataFromAddresses(uniqueAddresses);
    // TODO save inscriptions to isar which gets watched by a FutureBuilder/StreamBuilder
  }

  Future<List<InscriptionData>> getInscriptionData() async {
    try {
      final utxos = await _db.getUTXOs(_walletId).findAll();
      final uniqueAddresses = getUniqueAddressesFromUTXOs(utxos);
      return await getInscriptionDataFromAddresses(uniqueAddresses);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptions: $e');
    }
  }

  Future<List<Ordinal>> getOrdinals() async {
    try {
      final utxos = await _db.getUTXOs(_walletId).findAll();
      final uniqueAddresses = getUniqueAddressesFromUTXOs(utxos);
      return await getOrdinalsFromAddresses(uniqueAddresses);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getOrdinals: $e');
    }
  }

  List<String> getUniqueAddressesFromUTXOs(List<UTXO> utxos) {
    final Set<String> uniqueAddresses = <String>{};
    for (var utxo in utxos) {
      if (utxo.address != null) {
        uniqueAddresses.add(utxo.address!);
      }
    }
    return uniqueAddresses.toList();
  }

  Future<List<InscriptionData>> getInscriptionDataFromAddress(String address) async {
    List<InscriptionData> allInscriptions = [];
    try {
      var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
      allInscriptions.addAll(inscriptions);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptionsByAddress: $e');
    }
    return allInscriptions;
  }

  Future<List<InscriptionData>> getInscriptionDataFromAddresses(List<String> addresses) async {
    List<InscriptionData> allInscriptions = [];
    for (String address in addresses) {
      try {
        var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
        allInscriptions.addAll(inscriptions);
      } catch (e) {
        print("Error fetching inscriptions for address $address: $e");
      }
    }
    return allInscriptions;
  }

  Future<List<Ordinal>> getOrdinalsFromAddress(String address) async {
    try {
      var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
      return inscriptions.map((data) => Ordinal.fromInscriptionData(data)).toList();
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getOrdinalsFromAddress: $e');
    }
  }

  Future<List<Ordinal>> getOrdinalsFromAddresses(List<String> addresses) async {
    List<Ordinal> allOrdinals = [];
    for (String address in addresses) {
      try {
        var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
        allOrdinals.addAll(inscriptions.map((data) => Ordinal.fromInscriptionData(data)));
      } catch (e) {
        print("Error fetching inscriptions for address $address: $e");
      }
    }
    return allOrdinals;
  }
}