import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with the Silentium API
class SilentiumApi {
  final String baseUrl;
  final http.Client _client;

  SilentiumApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Close the HTTP client when done
  void dispose() {
    _client.close();
  }

  /// Get the latest block height from the chain tip
  Future<int> getLatestBlockHeight() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/chain/tip'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['height'] as int;
    } else {
      throw Exception(
        'Failed to get latest block height: ${response.statusCode}',
      );
    }
  }

  /// Get scalars for a specific block height
  /// Returns a list of scalar hex strings
  Future<List<String>> getScalarsForBlock(int height) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/v1/block/$height/scalars'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<String>.from(data['scalars'] as List);
    } else if (response.statusCode == 404) {
      // Block not found or no scalars available
      return [];
    } else {
      throw Exception('Failed to get scalars: ${response.statusCode}');
    }
  }

  /// Ping the API to check if it's available
  Future<bool> isAvailable() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/v1/chain/tip'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
