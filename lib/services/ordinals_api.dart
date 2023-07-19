import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:stackwallet/dto/ordinals/feed_response.dart';
import 'package:stackwallet/dto/ordinals/inscription_response.dart';
import 'package:stackwallet/dto/ordinals/sat_response.dart';

class OrdinalsAPI {
  final String baseUrl;

  OrdinalsAPI({required this.baseUrl});

  Future<Map<String, dynamic>> _getResponse(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return _validateJson(response.body);
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
}
