import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stackwallet/dto/ordinals/inscription_data.dart';
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
      throw Exception(
          'LitescribeAPI _getResponse exception: Failed to load data');
    }
  }

  Map<String, dynamic> _validateJson(String responseBody) {
    final parsed = jsonDecode(responseBody);
    if (parsed is Map<String, dynamic>) {
      return parsed;
    } else {
      throw const FormatException(
          'LitescribeAPI _validateJson exception: Invalid JSON format');
    }
  }

  Future<List<InscriptionData>> getInscriptionsByAddress(String address,
      {int cursor = 0, int size = 1000}) async {
    // size param determines how many inscriptions are returned per response
    // default of 1000 is used to cover most addresses (I assume)
    // if the total number of inscriptions at the address exceeds the length of the list of inscriptions returned, another call with a higher size is made
    final int defaultLimit = 1000;
    final response = await _getResponse(
        '/address/inscriptions?address=$address&cursor=$cursor&size=$size');

    // Check if the number of returned inscriptions equals the limit
    final int total = response.data['result']['total'] as int;

    int currentSize = 0;
    if (total == 0) {
      return <InscriptionData>[];
    }

    final list = response.data['result']!['list'];
    currentSize = list.length as int;

    if (currentSize == size && currentSize < total) {
      // If the number of returned inscriptions equals the limit and there are more inscriptions available,
      // increment the cursor and make the next API call to fetch the remaining inscriptions.
      final int newCursor = cursor + size;
      return getInscriptionsByAddress(address, cursor: newCursor, size: size);
    } else {
      try {
        // Iterate through the list and create InscriptionData objects from each element
        final List<InscriptionData> inscriptions = (list as List<dynamic>)
            .map((json) =>
                InscriptionData.fromJson(json as Map<String, dynamic>))
            .toList();

        return inscriptions;
      } catch (e) {
        throw const FormatException(
            'LitescribeAPI getInscriptionsByAddress exception: AddressInscriptionResponse.fromJson failure');
      }
    }
  }
}
