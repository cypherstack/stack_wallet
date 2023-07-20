import 'dart:async';

import 'package:isar/isar.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/utxo.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

// ord-litecoin-specific imports
// import 'package:stackwallet/dto/ordinals/feed_response.dart';
// import 'package:stackwallet/dto/ordinals/inscription_response.dart';
// import 'package:stackwallet/dto/ordinals/sat_response.dart';
// import 'package:stackwallet/dto/ordinals/transaction_response.dart';
// import 'package:stackwallet/dto/ordinals/output_response.dart';
// import 'package:stackwallet/dto/ordinals/address_response.dart';
// import 'package:stackwallet/dto/ordinals/block_response.dart';
// import 'package:stackwallet/dto/ordinals/content_response.dart';
// import 'package:stackwallet/dto/ordinals/preview_response.dart';
// import 'package:stackwallet/services/ordinals_api.dart';

import 'package:stackwallet/services/litescribe_api.dart';
import 'package:stackwallet/dto/ordinals/inscription_data.dart';

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

  // Future<List<InscriptionData>> getInscriptionsByAddress(String address) async {
  //   try {
  //     var response = await litescribeAPI.getInscriptionsByAddress(address);
  //     // print("Found ${response.result.total} inscription${response.result.total > 1 ? 's' : ''} at address $address"); // TODO disable (POC)
  //     return response.result.list;
  //   } catch (e) {
  //     throw Exception('Error in OrdinalsInterface getInscriptionsByAddress: $e');
  //   }
  // }

  void refreshInscriptions() async {
    List<dynamic> _inscriptions;
    final utxos = await _db.getUTXOs(_walletId).findAll();
    final uniqueAddresses = getUniqueAddressesFromUTXOs(utxos);
    _inscriptions = await getInscriptionsFromAddresses(uniqueAddresses);
    // TODO save inscriptions to isar which gets watched by a FutureBuilder/StreamBuilder
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

  Future<List<InscriptionData>> getInscriptionsFromAddresses(List<String> addresses) async {
    List<InscriptionData> allInscriptions = [];
    for (String address in addresses) {
      try {
        var inscriptions = await litescribeAPI.getInscriptionsByAddress(address);
        print("Found ${inscriptions.length} inscription${inscriptions.length > 1 ? 's' : ''} at address $address");
        allInscriptions.addAll(inscriptions);
      } catch (e) {
        print("Error fetching inscriptions for address $address: $e");
      }
    }
    return allInscriptions;
  }

/* // ord-litecoin interface
  final OrdinalsAPI ordinalsAPI = OrdinalsAPI(baseUrl: 'https://ord-litecoin.stackwallet.com');

  Future<FeedResponse> fetchLatestInscriptions() async {
    try {
      final feedResponse = await ordinalsAPI.getLatestInscriptions();
      // Process the feedResponse data as needed
      // print('Latest Inscriptions:');
      // for (var inscription in feedResponse.inscriptions) {
      //   print('Title: ${inscription.title}, Href: ${inscription.href}');
      // }
      return feedResponse;
    } catch (e) {
      // Handle errors
      throw Exception('Error in OrdinalsInterface fetchLatestInscriptions: $e');
    }
  }

  Future<InscriptionResponse> getInscriptionDetails(String inscriptionId) async {
    try {
      return await ordinalsAPI.getInscriptionDetails(inscriptionId);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptionDetails: $e');
    }
  }

  Future<SatResponse> getSatDetails(int satNumber) async {
    try {
      return await ordinalsAPI.getSatDetails(satNumber);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getSatDetails: $e');
    }
  }

  Future<TransactionResponse> getTransaction(String transactionId) async {
    try {
      print(1);
      return await ordinalsAPI.getTransaction(transactionId);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getTransaction: $e');
    }
  }

  Future<OutputResponse> getTransactionOutputs(String transactionId) async {
    try {
      return await ordinalsAPI.getTransactionOutputs(transactionId);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getTransactionOutputs: $e');
    }
  }

  Future<AddressResponse> getInscriptionsByAddress(String address) async {
    try {
      return await ordinalsAPI.getInscriptionsByAddress(address);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptionsByAddress: $e');
    }
  }

  Future<BlockResponse> getBlock(int blockNumber) async {
    try {
      return await ordinalsAPI.getBlock(blockNumber);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getBlock: $e');
    }
  }

  Future<ContentResponse> getInscriptionContent(String inscriptionId) async {
    try {
      return await ordinalsAPI.getInscriptionContent(inscriptionId);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptionContent: $e');
    }
  }

  Future<PreviewResponse> getInscriptionPreview(String inscriptionId) async {
    try {
      return await ordinalsAPI.getInscriptionPreview(inscriptionId);
    } catch (e) {
      throw Exception('Error in OrdinalsInterface getInscriptionPreview: $e');
    }
  }
  */ // /ord-litecoin interface
}