import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:stackwallet/dto/ordinals/ordinals_response.dart';
import 'package:stackwallet/dto/ordinals/feed_response.dart';
import 'package:stackwallet/dto/ordinals/inscription_response.dart';
import 'package:stackwallet/dto/ordinals/sat_response.dart';
import 'package:stackwallet/dto/ordinals/transaction_response.dart';
import 'package:stackwallet/dto/ordinals/output_response.dart';
import 'package:stackwallet/dto/ordinals/address_response.dart';
import 'package:stackwallet/dto/ordinals/block_response.dart';
import 'package:stackwallet/dto/ordinals/content_response.dart';
import 'package:stackwallet/dto/ordinals/preview_response.dart';

class OrdinalsAPI {
  static final OrdinalsAPI _instance = OrdinalsAPI._internal();

  factory OrdinalsAPI({required String baseUrl}) {
    _instance.baseUrl = baseUrl;
    return _instance;
  }

  OrdinalsAPI._internal();

  late String baseUrl;

  Future<OrdinalsResponse> _getResponse(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return OrdinalsResponse(data: _validateJson(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }

  Map<String, dynamic> _validateJson(String responseBody) {
    final parsed = jsonDecode(responseBody);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    } else {
      throw const FormatException('Invalid JSON format');
    }
  }

  Future<FeedResponse> getLatestInscriptions() async {
    final response = await _getResponse('/feed');
    return FeedResponse.fromJson(response);
  }

  Future<InscriptionResponse> getInscriptionDetails(String inscriptionId) async {
    final response = await _getResponse('/inscription/$inscriptionId');
    return InscriptionResponse.fromJson(response);
  }

  Future<SatResponse> getSatDetails(int satNumber) async {
    final response = await _getResponse('/sat/$satNumber');
    return SatResponse.fromJson(response);
  }

  Future<TransactionResponse> getTransaction(String transactionId) async {
    final response = await _getResponse('/tx/$transactionId');
    return TransactionResponse.fromJson(response);
  }

  Future<OutputResponse> getTransactionOutputs(String transactionId) async {
    final response = await _getResponse('/output/$transactionId');
    return OutputResponse.fromJson(response);
  }

  Future<AddressResponse> getInscriptionsByAddress(String address) async {
    final response = await _getResponse('/address/$address');
    return AddressResponse.fromJson(response);
  }

  Future<BlockResponse> getBlock(int blockNumber) async {
    final response = await _getResponse('/block/$blockNumber');
    return BlockResponse.fromJson(response);
  }

  Future<ContentResponse> getInscriptionContent(String inscriptionId) async {
    final response = await _getResponse('/content/$inscriptionId');
    return ContentResponse.fromJson(response);
  }

  Future<PreviewResponse> getInscriptionPreview(String inscriptionId) async {
    final response = await _getResponse('/preview/$inscriptionId');
    return PreviewResponse.fromJson(response);
  }
}
