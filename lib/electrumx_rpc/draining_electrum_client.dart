import 'dart:async';

import 'package:electrum_adapter/electrum_adapter.dart';

/// A superseded connection finishes its outstanding RPCs before closing.
/// Every adapter helper, including subscription setup, uses this request hook.
/// Explicit close still cancels immediately for revocation and shutdown.
mixin DrainingElectrumClient on ElectrumClient {
  int _requests = 0;
  bool _retiring = false;

  Future<void> retire() async {
    _retiring = true;
    if (_requests == 0) await close();
  }

  @override
  Future<dynamic> requestWithTimeout(
    String method, {
    dynamic parameters,
    Duration? timeout,
  }) {
    _requests++;
    try {
      final pending = super.requestWithTimeout(
        method,
        parameters: parameters,
        timeout: timeout,
      );
      // Keep the original future: subscription setup relies on the adapter's
      // synchronous completion ordering relative to following notifications.
      unawaited(
        pending.then<void>(
          (_) => _requestFinished(),
          onError: (Object _) => _requestFinished(),
        ),
      );
      return pending;
    } catch (_) {
      _requestFinished();
      rethrow;
    }
  }

  void _requestFinished() {
    if (--_requests == 0 && _retiring) close().ignore();
  }
}

class ManagedElectrumClient extends ElectrumClient with DrainingElectrumClient {
  ManagedElectrumClient(
    super.channel,
    super.host,
    super.port,
    super.useSSL,
    super.proxyInfo, {
    required super.requestTimeout,
  });
}

class ManagedFiroElectrumClient extends FiroElectrumClient
    with DrainingElectrumClient {
  ManagedFiroElectrumClient(
    super.channel,
    super.host,
    super.port,
    super.useSSL,
    super.proxyInfo, {
    required super.requestTimeout,
  });
}
