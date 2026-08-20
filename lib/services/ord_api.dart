import 'dart:convert';
import 'dart:io';

import '../app_config.dart';
import '../networking/http.dart';
import '../utilities/prefs.dart';
import 'tor_service.dart';

class OrdAPI {
  final String baseUrl;
  final HTTP _client = const HTTP();

  OrdAPI({required this.baseUrl});

  static const _jsonHeaders = {'Accept': 'application/json'};

  ({InternetAddress host, int port})? get _proxyInfo =>
      !AppConfig.hasFeature(AppFeature.tor)
      ? null
      : Prefs.instance.useTor
      ? TorService.sharedInstance.getProxyInfo()
      : null;

  /// Check an output for inscriptions.
  /// Returns the list of inscription IDs found on the output, or empty list.
  Future<List<String>> getInscriptionIdsForOutput(String txid, int vout) async {
    final response = await _client.get(
      url: Uri.parse('$baseUrl/output/$txid:$vout'),
      headers: _jsonHeaders,
      proxyInfo: _proxyInfo,
    );

    if (response.code != 200) {
      throw Exception(
        'OrdAPI getInscriptionIdsForOutput failed: '
        'status=${response.code}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final inscriptions = json['inscriptions'] as List<dynamic>?;

    if (inscriptions == null || inscriptions.isEmpty) {
      return [];
    }

    return inscriptions.cast<String>();
  }

  /// Fetch full inscription metadata by ID.
  Future<Map<String, dynamic>> getInscriptionData(String inscriptionId) async {
    final response = await _client.get(
      url: Uri.parse('$baseUrl/inscription/$inscriptionId'),
      headers: _jsonHeaders,
      proxyInfo: _proxyInfo,
    );

    if (response.code != 200) {
      throw Exception(
        'OrdAPI getInscriptionData failed: '
        'status=${response.code}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Build the content URL for an inscription.
  String contentUrl(String inscriptionId) => '$baseUrl/content/$inscriptionId';
}
