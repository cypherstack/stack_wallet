import 'dart:async';

import 'package:regtest_support/regtest_support.dart';

/// Whether an endpoint must be reachable from the test host or from the app
/// process/device under test.
enum StackEndpointAudience { host, device }

/// Selects one named endpoint without conflating host and device reachability.
Uri selectStackEndpoint(
  EndpointBundle bundle, {
  required String name,
  required StackEndpointAudience audience,
}) => switch (audience) {
  StackEndpointAudience.host => bundle.host(name),
  StackEndpointAudience.device => bundle.device(name),
};

final class StackFixtureTimeoutException implements Exception {
  const StackFixtureTimeoutException({
    required this.operation,
    required this.timeout,
    required this.diagnostics,
  });

  final String operation;
  final Duration timeout;
  final String diagnostics;

  @override
  String toString() =>
      'StackFixtureTimeoutException: $operation did not complete within '
      '$timeout\n$diagnostics';
}

/// Raised instead of pretending that a wallet supports an unimplemented
/// receiver, synchronization, observation, or send operation.
final class StackRegtestCapabilityUnavailableException implements Exception {
  const StackRegtestCapabilityUnavailableException(this.capability);

  final String capability;

  @override
  String toString() =>
      'StackRegtestCapabilityUnavailableException: $capability is not '
      'configured for this wallet fixture';
}

/// Coin-specific wallet construction using Stack's ordinary wallet lifecycle.
///
/// Implementations own the distinction between new-wallet material and
/// recovery material. [reopen] must release the old handle before returning
/// the replacement, matching [WalletRegtestDriver.restart].
abstract interface class StackRegtestWalletFactory<Wallet> {
  Future<Wallet> create(String name, RegtestCancellation cancellation);

  Future<Wallet> restore(
    String name,
    String recoveryMaterial,
    RegtestCancellation cancellation,
  );

  Future<Wallet> reopen(Wallet wallet, RegtestCancellation cancellation);

  Future<void> close(Wallet wallet);
}

/// Optional transaction surface supplied only after a coin implements the
/// corresponding production wallet methods.
abstract interface class StackRegtestTransferCapabilities<
  Wallet,
  Pool,
  NativePrepared
> {
  Future<String> receiver(Wallet wallet, Pool pool);

  Future<void> synchronize(Wallet wallet);

  Future<WalletObservation<Pool>> observe(Wallet wallet);

  Future<PreparedTransfer<Pool, NativePrepared>> prepare(
    Wallet wallet,
    TransferRequest<Pool> request,
  );

  Future<TransferReceipt<Pool>> confirm(
    Wallet wallet,
    PreparedTransfer<Pool, NativePrepared> prepared,
  );
}

typedef StackFixtureEnvironmentFactory = Future<RegtestResource> Function();

typedef StackBackendFactory = Future<RegtestResource> Function(
  RegtestResource environment,
  RegtestCancellation cancellation,
);

typedef StackEndpointInjector<Endpoint> = Future<void> Function(
  RegtestResource environment,
  Endpoint endpoint,
  StackEndpointAudience audience,
  RegtestCancellation cancellation,
);

/// A reusable Stack-side adapter for typed regtest scenarios.
///
/// Three shapes were considered: lifecycle callbacks alone, this typed driver,
/// and a scenario-specific wrapper. The typed driver keeps cleanup centralized
/// while allowing scenarios to remain in `regtest_support`; optional transfer
/// capabilities prevent this fixture from fabricating coin behavior.
final class StackWalletRegtestFixture<Wallet, Endpoint, Pool, NativePrepared>
    implements WalletRegtestDriver<Wallet, Endpoint, Pool, NativePrepared> {
  StackWalletRegtestFixture._(
    this._environment,
    this._backend, {
    required this._endpointInjector,
    required this._endpointAudience,
    required this._walletFactory,
    required this._transferCapabilities,
    required this._operationTimeout,
  });

  static Future<
    StackWalletRegtestFixture<Wallet, Endpoint, Pool, NativePrepared>
  >
  open<Wallet, Endpoint, Pool, NativePrepared>({
    required StackFixtureEnvironmentFactory environmentFactory,
    required StackBackendFactory backendFactory,
    required StackEndpointInjector<Endpoint> endpointInjector,
    required StackRegtestWalletFactory<Wallet> walletFactory,
    StackEndpointAudience endpointAudience = StackEndpointAudience.host,
    StackRegtestTransferCapabilities<Wallet, Pool, NativePrepared>?
    transferCapabilities,
    Duration operationTimeout = const Duration(seconds: 30),
  }) async {
    if (operationTimeout <= Duration.zero) {
      throw ArgumentError.value(
        operationTimeout,
        'operationTimeout',
        'must be positive',
      );
    }

    final environment = await environmentFactory();
    RegtestResource? backend;
    try {
      backend = await _acquireBounded<RegtestResource>(
        operation: 'initialize backend',
        timeout: operationTimeout,
        diagnostics: environment.diagnostics,
        start: (cancellation) => backendFactory(environment, cancellation),
        closeLateValue: (resource) => resource.close(),
      );
      return StackWalletRegtestFixture._(
        environment,
        backend,
        endpointInjector: endpointInjector,
        endpointAudience: endpointAudience,
        walletFactory: walletFactory,
        transferCapabilities: transferCapabilities,
        operationTimeout: operationTimeout,
      );
    } catch (error, stack) {
      if (backend != null) {
        try {
          await backend.close();
        } catch (_) {
          // Preserve the startup failure; successful fixtures report cleanup
          // failures from close().
        }
      }
      try {
        await environment.close();
      } catch (_) {
        // Preserve the startup failure.
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  final RegtestResource _environment;
  final RegtestResource _backend;
  final StackEndpointInjector<Endpoint> _endpointInjector;
  final StackEndpointAudience _endpointAudience;
  final StackRegtestWalletFactory<Wallet> _walletFactory;
  final StackRegtestTransferCapabilities<Wallet, Pool, NativePrepared>?
  _transferCapabilities;
  final Duration _operationTimeout;
  final List<Wallet> _wallets = [];

  bool _configured = false;
  bool _closed = false;
  int _activeOperations = 0;
  Completer<void>? _operationsDrained;
  Future<void>? _closeFuture;

  @override
  String get name => 'Stack wallet fixture';

  @override
  Future<void> configure(Endpoint endpoint) => _withOperation(() async {
    await _runBounded<void>(
      'inject endpoint',
      (cancellation) => _endpointInjector(
        _environment,
        endpoint,
        _endpointAudience,
        cancellation,
      ),
    );
    _configured = true;
  });

  @override
  Future<Wallet> create(String name) => _acquireWallet(
    'create wallet',
    (cancellation) => _walletFactory.create(name, cancellation),
  );

  @override
  Future<Wallet> restore(String name, String recoveryMaterial) =>
      _acquireWallet(
        'restore wallet',
        (cancellation) =>
            _walletFactory.restore(name, recoveryMaterial, cancellation),
      );

  Future<Wallet> _acquireWallet(
    String operation,
    Future<Wallet> Function(RegtestCancellation cancellation) start,
  ) => _withOperation(() async {
    final wallet = await _runBounded(
      operation,
      start,
      closeLateValue: _walletFactory.close,
    );
    _wallets.add(wallet);
    return wallet;
  }, requireReady: true);

  @override
  Future<Wallet> restart(Wallet wallet) => _withOperation(() async {
    final index = _wallets.indexWhere(
      (candidate) => identical(candidate, wallet),
    );
    if (index < 0) {
      throw StateError('Cannot restart a wallet not owned by this fixture');
    }
    final replacement = await _runBounded(
      'restart wallet',
      (cancellation) => _walletFactory.reopen(wallet, cancellation),
      closeLateValue: _walletFactory.close,
    );
    _wallets[index] = replacement;
    return replacement;
  }, requireReady: true);

  @override
  Future<void> closeWallet(Wallet wallet) => _withOperation(() async {
    final index = _wallets.indexWhere(
      (candidate) => identical(candidate, wallet),
    );
    if (index < 0) return;
    _wallets.removeAt(index);
    await _walletFactory.close(wallet);
  });

  StackRegtestTransferCapabilities<Wallet, Pool, NativePrepared> _capability(
    String name,
  ) {
    _requireReady();
    final capabilities = _transferCapabilities;
    if (capabilities == null) {
      throw StackRegtestCapabilityUnavailableException(name);
    }
    return capabilities;
  }

  @override
  Future<String> receiver(Wallet wallet, Pool pool) => _withOperation(
    () => _capability('receiver').receiver(wallet, pool),
    requireReady: true,
  );

  @override
  Future<void> synchronize(Wallet wallet) => _withOperation(
    () => _capability('synchronize').synchronize(wallet),
    requireReady: true,
  );

  @override
  Future<WalletObservation<Pool>> observe(Wallet wallet) => _withOperation(
    () => _capability('observe').observe(wallet),
    requireReady: true,
  );

  @override
  Future<PreparedTransfer<Pool, NativePrepared>> prepare(
    Wallet wallet,
    TransferRequest<Pool> request,
  ) => _withOperation(
    () => _capability('prepare').prepare(wallet, request),
    requireReady: true,
  );

  @override
  Future<TransferReceipt<Pool>> confirm(
    Wallet wallet,
    PreparedTransfer<Pool, NativePrepared> prepared,
  ) => _withOperation(
    () => _capability('confirm').confirm(wallet, prepared),
    requireReady: true,
  );

  @override
  String diagnostics({int maxLines = 100}) {
    if (maxLines < 0) {
      throw ArgumentError.value(maxLines, 'maxLines', 'must not be negative');
    }
    final text = [
      'configured=$_configured closed=$_closed wallets=${_wallets.length}',
      '${_environment.name}:\n${_environment.diagnostics(maxLines: maxLines)}',
      '${_backend.name}:\n${_backend.diagnostics(maxLines: maxLines)}',
    ].join('\n');
    final lines = text.split('\n');
    return lines
        .skip(lines.length > maxLines ? lines.length - maxLines : 0)
        .join('\n');
  }

  @override
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    _closed = true;
    if (_activeOperations > 0) {
      _operationsDrained = Completer<void>();
      await _operationsDrained!.future;
    }
    Object? firstError;
    StackTrace? firstStack;

    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }

    for (final wallet in _wallets.reversed) {
      await attempt(() => _walletFactory.close(wallet));
    }
    _wallets.clear();
    await attempt(_backend.close);
    await attempt(_environment.close);

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStack!);
    }
  }

  Future<T> _runBounded<T>(
    String operation,
    Future<T> Function(RegtestCancellation cancellation) start, {
    Future<void> Function(T value)? closeLateValue,
  }) => _acquireBounded(
    operation: operation,
    timeout: _operationTimeout,
    diagnostics: diagnostics,
    start: start,
    closeLateValue: closeLateValue,
  );

  Future<T> _withOperation<T>(
    Future<T> Function() operation, {
    bool requireReady = false,
  }) async {
    if (requireReady) {
      _requireReady();
    } else {
      _requireOpen();
    }
    _activeOperations++;
    try {
      return await operation();
    } finally {
      _activeOperations--;
      if (_activeOperations == 0 &&
          !(_operationsDrained?.isCompleted ?? true)) {
        _operationsDrained!.complete();
      }
    }
  }

  void _requireOpen() {
    if (_closed) throw StateError('Stack wallet fixture is closed');
  }

  void _requireReady() {
    _requireOpen();
    if (!_configured) {
      throw StateError(
        'Configure the wallet endpoint before wallet operations',
      );
    }
  }

  static Future<T> _acquireBounded<T>({
    required String operation,
    required Duration timeout,
    required String Function({int maxLines}) diagnostics,
    required Future<T> Function(RegtestCancellation cancellation) start,
    Future<void> Function(T value)? closeLateValue,
  }) async {
    final cancellation = RegtestCancellation();
    final future = start(cancellation);
    var timedOut = false;
    if (closeLateValue != null) {
      final lateCleanup = future.then<void>((value) async {
        if (timedOut) await closeLateValue(value);
      }, onError: (Object _, StackTrace __) {});
      unawaited(lateCleanup.catchError((Object _, StackTrace __) {}));
    }
    try {
      return await future.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          cancellation.cancel();
          throw StackFixtureTimeoutException(
            operation: operation,
            timeout: timeout,
            diagnostics: diagnostics(maxLines: 100),
          );
        },
      );
    } on TimeoutException {
      timedOut = true;
      cancellation.cancel();
      throw StackFixtureTimeoutException(
        operation: operation,
        timeout: timeout,
        diagnostics: diagnostics(maxLines: 100),
      );
    }
  }
}
