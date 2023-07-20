import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:stackwallet/dto/ordinals/address_inscription_response.dart';
import 'package:stackwallet/dto/ordinals/litescribe_response.dart';

class LitescribeAPI {
  static final LitescribeAPI _instance = LitescribeAPI._internal();

  factory LitescribeAPI({required String baseUrl}) {
    _instance.baseUrl = baseUrl;
    return _instance;
  }

  LitescribeAPI._internal();

  late String baseUrl;

  Future<LitescribeResponse> _getResponse(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return LitescribeResponse(data: _validateJson(response.body));
    } else {
      throw Exception('LitescribeAPI _getResponse exception: Failed to load data');
    }
  }

  Map<String, dynamic> _validateJson(String responseBody) {
    final parsed = jsonDecode(responseBody);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    } else {
      throw const FormatException('LitescribeAPI _validateJson exception: Invalid JSON format');
    }
  }

  Future<AddressInscriptionResponse> getInscriptionsByAddress(String address, {int cursor = 0, int size = 1000}) async { // size = 1000 = hardcoded limit as default limit to inscriptions returned from API call, TODO increase limit if returned inscriptions = limit
    final response = await _getResponse('/address/inscriptions?address=$address&cursor=$cursor&size=$size');
    try {
      return AddressInscriptionResponse.fromJson(response.data as Map<String, dynamic>);
    } catch(e) {
      throw const FormatException('LitescribeAPI getInscriptionsByAddress exception: AddressInscriptionResponse.fromJson failure');
    }
  }
}