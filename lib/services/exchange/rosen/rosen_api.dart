import 'dart:convert';

import '../../../app_config.dart';
import '../../../networking/http.dart';
import '../../../utilities/prefs.dart';
import '../../tor_service.dart';
import 'rosen_fees.dart';

export 'rosen_fees.dart';

class RosenApi {
  RosenApi._();

  static final instance = RosenApi._();

  // Rosen mainnet config 7.1.1, verified against app.rosen.tech on 2026-09-17.
  // https://github.com/rosen-bridge/ui/blob/dev/apps/rosen/configs/generate.mjs
  static const rsFiroContract = '0x2744ea5ac9b11cb5e3cd63d3a88e858336aeddc2';
  static const firoLockAddress = 'aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y';
  static const ethereumLockAddress =
      '0x451698faa07fc68301af622a3ad42205f13c6e4b';
  static const tokenDecimals = 8;
  static const _ergoFiroToken =
      '581d7df25808881b2b8b9b4e03e2f637c46a94f74a69a5da36434125bacb4e08';
  static const _minimumFeeToken =
      'e2ed4d64393222db666f20e67803e9e6fbe6d64531e14ff52ddd95615b0cbf17';

  final _client = const HTTP();

  Future<dynamic> _get(Uri url) async {
    final response = await _client
        .get(
          url: url,
          headers: {'Accept': 'application/json'},
          connectionTimeout: const Duration(seconds: 20),
          proxyInfo:
              AppConfig.hasFeature(AppFeature.tor) && Prefs.instance.useTor
              ? TorService.sharedInstance.getProxyInfo()
              : null,
        )
        .timeout(const Duration(seconds: 30));
    if (response.code != 200) {
      throw StateError('Rosen API returned HTTP ${response.code}');
    }
    return jsonDecode(response.body);
  }

  Future<RosenQuote> quote({
    required bool fromFiro,
    required BigInt amount,
    int? sourceHeight,
  }) async {
    // The funding wallet supplies its chain tip; discovery uses Rosen's scanners.
    var height = sourceHeight;
    if (height == null) {
      final heights =
          await _get(Uri.https('app.rosen.tech', '/api/v1/heights')) as List;
      final source = fromFiro ? 'firo' : 'ethereum';
      height = int.parse(
        heights
            .singleWhere((entry) => entry['network'] == source)['height']
            .toString(),
      );
    }
    final candidates = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final result =
          await _get(
                Uri.https(
                  'api.ergoplatform.com',
                  '/api/v1/boxes/unspent/byTokenId/$_minimumFeeToken',
                  {'offset': '$offset', 'limit': '100'},
                ),
              )
              as Map;
      final items = result['items'] as List;
      for (final item in items) {
        final assets = item['assets'] as List;
        if (assets.length == 2 &&
            assets.any((asset) => asset['tokenId'] == _minimumFeeToken) &&
            assets.any((asset) => asset['tokenId'] == _ergoFiroToken) &&
            item['spentTransactionId'] == null &&
            item['mainChain'] == true) {
          candidates.add(Map<String, dynamic>.from(item as Map));
        }
      }
      offset += items.length;
      if (offset >= int.parse(result['total'].toString())) break;
      if (items.isEmpty || offset > 10000) {
        throw const FormatException('Incomplete Rosen fee configuration');
      }
    }
    if (candidates.length != 1) {
      throw StateError('Expected one active Rosen FIRO fee configuration');
    }
    final registers = Map<String, dynamic>.from(
      candidates.single['additionalRegisters'] as Map,
    );
    final quote = RosenQuote.fromRegisters(
      registers,
      fromFiro: fromFiro,
      height: height,
      amount: amount,
    );
    // Refuse a quote whose fees are scheduled to change during confirmation.
    final next = RosenQuote.fromRegisters(
      registers,
      fromFiro: fromFiro,
      height: height + (fromFiro ? 10 : 50),
      amount: amount,
    );
    if (quote.bridgeFee != next.bridgeFee ||
        quote.networkFee != next.networkFee) {
      throw StateError('Rosen fees are changing. Please try again shortly.');
    }
    return quote;
  }

  /// An unobserved source transaction remains pending, including across restarts.
  Future<Map<String, dynamic>?> getEvent(String sourceTxId) async {
    if (!RegExp(r'^(0x)?[0-9a-fA-F]{64}$').hasMatch(sourceTxId)) {
      throw const FormatException('Invalid Rosen source transaction ID');
    }
    final normalized = sourceTxId.toLowerCase().replaceFirst(
      RegExp(r'^0x'),
      '',
    );
    final result =
        await _get(
              Uri.https('app.rosen.tech', '/api/v1/events', {
                'sourceTxId*': normalized,
                'limit': '100',
              }),
            )
            as Map;
    final matches = (result['items'] as List)
        .where(
          (item) =>
              item['sourceTxId'] is String &&
              (item['sourceTxId'] as String).toLowerCase().replaceFirst(
                    RegExp(r'^0x'),
                    '',
                  ) ==
                  normalized,
        )
        .toList();
    if (matches.length > 1) {
      throw StateError('Multiple Rosen events for this source transaction');
    }
    return matches.isEmpty
        ? null
        : Map<String, dynamic>.from(matches.single as Map);
  }
}
