import 'dart:async';

import 'package:zcash_flutter/zcash_flutter.dart' as zcash;

import '../../../models/node_model.dart';
import '../../crypto_currency/crypto_currency.dart';

typedef ZcashLightwalletdClientFactory = ZcashLightwalletdClient Function(
  ZcashEndpoint endpoint,
);

abstract interface class ZcashLightwalletdClient {
  Future<zcash.LightdInfo> getInfo();

  Future<int> getTipHeight();

  Future<void> close();
}

abstract interface class ZcashLightwalletdSyncClient
    implements ZcashLightwalletdClient {
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(int start, int end);

  Future<zcash.TreeState> getTreeState(int height);

  Future<String?> getBlockHash(int height);
}

class ZcashEndpoint {
  const ZcashEndpoint({
    required this.host,
    required this.port,
    required this.useTls,
    required this.network,
  });

  factory ZcashEndpoint.fromNode(
    NodeModel node,
    CryptoCurrencyNetwork network,
  ) {
    final value = node.host.trim();
    if (value.isEmpty) {
      throw ArgumentError('Zcash node host must not be empty');
    }
    if (node.port < 1 || node.port > 65535) {
      throw ArgumentError('Zcash node port must be between 1 and 65535');
    }

    final hasScheme = value.contains('://');
    final uri = Uri.tryParse(
      hasScheme ? value : '${node.useSSL ? 'https' : 'http'}://$value',
    );
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError('Invalid Zcash node host');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('Zcash nodes require an HTTP or HTTPS endpoint');
    }
    if ((uri.scheme == 'https') != node.useSSL) {
      throw ArgumentError('Zcash node scheme conflicts with its TLS setting');
    }
    if (uri.hasPort && uri.port != node.port) {
      throw ArgumentError('Zcash node URI port conflicts with its node port');
    }

    return ZcashEndpoint(
      host: uri.host,
      port: node.port,
      useTls: node.useSSL,
      network: network,
    );
  }

  final String host;
  final int port;
  final bool useTls;
  final CryptoCurrencyNetwork network;

  @override
  bool operator ==(Object other) =>
      other is ZcashEndpoint &&
      other.host == host &&
      other.port == port &&
      other.useTls == useTls &&
      other.network == network;

  @override
  int get hashCode => Object.hash(host, port, useTls, network);
}

class ZcashSessionReadiness {
  const ZcashSessionReadiness({required this.info, required this.tipHeight});

  final zcash.LightdInfo info;
  final int tipHeight;
}

class ZcashNetworkMismatchException implements Exception {
  const ZcashNetworkMismatchException({
    required this.expected,
    required this.actual,
  });

  final String expected;
  final String actual;

  @override
  String toString() =>
      'ZcashNetworkMismatchException: expected $expected, got $actual';
}

class ZcashReadinessTimeoutException implements Exception {
  const ZcashReadinessTimeoutException({
    required this.phase,
    required this.timeout,
  });

  final String phase;
  final Duration timeout;

  @override
  String toString() =>
      'ZcashReadinessTimeoutException: $phase exceeded $timeout';
}

class ZcashAccountSession {
  ZcashAccountSession({
    required this.network,
    ZcashLightwalletdClientFactory? clientFactory,
    this.requestTimeout = const Duration(seconds: 5),
  }) : _clientFactory = clientFactory ?? _productionClient;

  final CryptoCurrencyNetwork network;
  final Duration requestTimeout;
  final ZcashLightwalletdClientFactory _clientFactory;

  ZcashLightwalletdClient? _client;
  int _generation = 0;
  int _replacementRequest = 0;
  bool _closed = false;

  /// Changes whenever the active endpoint changes or closes, invalidating work
  /// prepared against an earlier account session.
  int get generation => _generation;

  ZcashLightwalletdSyncClient? get syncClient {
    final client = _client;
    return client is ZcashLightwalletdSyncClient ? client : null;
  }

  Future<ZcashSessionReadiness> replaceNode(NodeModel node) async {
    if (_closed) {
      throw StateError('The Zcash account session is closed');
    }
    final replacementRequest = ++_replacementRequest;
    final replacement = _clientFactory(ZcashEndpoint.fromNode(node, network));
    late final ZcashSessionReadiness readiness;
    try {
      readiness = await _readiness(replacement);
    } catch (_) {
      await _closeClient(replacement);
      rethrow;
    }
    if (_closed || replacementRequest != _replacementRequest) {
      await _closeClient(replacement);
      throw StateError('The Zcash account session replacement was superseded');
    }

    final previous = _client;
    _client = replacement;
    _generation++;
    await _closeClient(previous);
    return readiness;
  }

  Future<bool> ping() async {
    if (_closed) return false;
    final client = _client;
    if (client == null) return false;
    try {
      await _readiness(client);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ZcashSessionReadiness> _readiness(
    ZcashLightwalletdClient client,
  ) async {
    late final zcash.LightdInfo info;
    try {
      info = await client.getInfo().timeout(requestTimeout);
    } on TimeoutException {
      throw ZcashReadinessTimeoutException(
        phase: 'getLightdInfo',
        timeout: requestTimeout,
      );
    }
    final expectedChainName = switch (network) {
      CryptoCurrencyNetwork.main => 'main',
      CryptoCurrencyNetwork.test => 'test',
      // Lightwalletd's protocol exposes only `main` and `test`. Regtest uses
      // the `test` identity, so chainName alone cannot distinguish those two.
      CryptoCurrencyNetwork.regtest => 'test',
      CryptoCurrencyNetwork.stage || CryptoCurrencyNetwork.test4 =>
        throw StateError('Unsupported Zcash network: $network'),
    };
    if (info.chainName != expectedChainName) {
      throw ZcashNetworkMismatchException(
        expected: expectedChainName,
        actual: info.chainName,
      );
    }
    late final int tipHeight;
    try {
      tipHeight = await client.getTipHeight().timeout(requestTimeout);
    } on TimeoutException {
      throw ZcashReadinessTimeoutException(
        phase: 'getTipHeight',
        timeout: requestTimeout,
      );
    }
    return ZcashSessionReadiness(info: info, tipHeight: tipHeight);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _replacementRequest++;
    final client = _client;
    _client = null;
    if (client != null) _generation++;
    await _closeClient(client);
  }

  Future<void> _closeClient(ZcashLightwalletdClient? client) async {
    if (client == null) return;
    try {
      await client.close().timeout(requestTimeout);
    } catch (_) {
      // Closing is best effort after the active reference has been removed.
    }
  }

  static ZcashLightwalletdClient _productionClient(ZcashEndpoint endpoint) =>
      _ProductionZcashLightwalletdClient(
        zcash.LightwalletdClient(
          host: endpoint.host,
          port: endpoint.port,
          useTls: endpoint.useTls,
        ),
      );
}

class _ProductionZcashLightwalletdClient
    implements ZcashLightwalletdSyncClient {
  _ProductionZcashLightwalletdClient(this._client);

  final zcash.LightwalletdClient _client;

  @override
  Future<zcash.LightdInfo> getInfo() => _client.getInfo();

  @override
  Future<int> getTipHeight() => _client.getTipHeight();

  @override
  Future<zcash.ZcashLightwalletdScanSource> getBlockRange(
    int start,
    int end,
  ) async => zcash.ZcashLightwalletdScanSource(
    await _client.getBlockRangeByHeight(start, end).toList(),
  );

  @override
  Future<zcash.TreeState> getTreeState(int height) async => zcash
      .treeStateFromLightwalletd(await _client.getTreeStateAtHeight(height));

  @override
  Future<String?> getBlockHash(int height) async {
    try {
      return (await getBlockRange(height, height)).lastBlockHash;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> close() => _client.close();
}
