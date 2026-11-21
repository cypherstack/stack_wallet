import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:regtest_support/regtest_support.dart';

import '../../integration_test/regtest_support/stack_wallet_fixture.dart';

void main() {
  test('delivers the device endpoint before creating a wallet', () async {
    final events = <String>[];
    final environment = _Environment(events);
    final backend = _Resource('backend', events);
    final wallets = _WalletFactory(events);
    final fixture =
        await StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
          environmentFactory: () async => environment,
          backendFactory: (environment, cancellation) async {
            events.add('initialize backend');
            return backend;
          },
          endpointInjector:
              (environment, endpoint, audience, cancellation) async {
                events.add('inject ${audience.name} $endpoint');
              },
          endpointAudience: StackEndpointAudience.device,
          walletFactory: wallets,
        );

    await fixture.configure(Uri.parse('https://10.0.2.2:9067'));
    final wallet = await fixture.create('alice');

    expect(wallet.name, 'alice');
    expect(events, [
      'initialize backend',
      'inject device https://10.0.2.2:9067',
      'create alice',
    ]);

    await fixture.close();
    expect(events.sublist(3), [
      'close wallet alice',
      'close backend',
      'close environment',
    ]);
    await fixture.close();
    expect(events.length, 6);
  });

  test('cleans the environment when backend initialization fails', () async {
    final events = <String>[];
    final environment = _Environment(events);

    await expectLater(
      StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
        environmentFactory: () async => environment,
        backendFactory: (environment, cancellation) async {
          throw StateError('backend failed');
        },
        endpointInjector: (
          environment,
          endpoint,
          audience,
          cancellation,
        ) async {},
        walletFactory: _WalletFactory(events),
      ),
      throwsStateError,
    );

    expect(events, ['close environment']);
  });

  test('preserves startup failure when cleanup also fails', () async {
    final events = <String>[];

    await expectLater(
      StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
        environmentFactory: () async => _ThrowingCloseEnvironment(events),
        backendFactory: (environment, cancellation) async {
          throw StateError('backend failed');
        },
        endpointInjector: (
          environment,
          endpoint,
          audience,
          cancellation,
        ) async {},
        walletFactory: _WalletFactory(events),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'backend failed',
        ),
      ),
    );
    expect(events, ['close environment']);
  });

  test(
    'late backend completion after timeout is closed without leaking',
    () async {
      final events = <String>[];
      final backendCompleter = Completer<RegtestResource>();
      final environment = _Environment(events);

      await expectLater(
        StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
          environmentFactory: () async => environment,
          backendFactory: (environment, cancellation) =>
              backendCompleter.future,
          endpointInjector: (
            environment,
            endpoint,
            audience,
            cancellation,
          ) async {},
          walletFactory: _WalletFactory(events),
          operationTimeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<StackFixtureTimeoutException>()),
      );

      backendCompleter.complete(_Resource('late backend', events));
      await pumpEventQueue();
      expect(events, ['close environment', 'close late backend']);
    },
  );

  test('unsupported transfer capabilities fail explicitly', () async {
    final events = <String>[];
    final fixture =
        await StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
          environmentFactory: () async => _Environment(events),
          backendFactory: (environment, cancellation) async =>
              _Resource('backend', events),
          endpointInjector: (
            environment,
            endpoint,
            audience,
            cancellation,
          ) async {},
          walletFactory: _WalletFactory(events),
        );
    await fixture.configure(Uri.parse('http://127.0.0.1:9067'));
    final wallet = await fixture.create('alice');

    expect(fixture.diagnostics(maxLines: 2).split('\n'), hasLength(2));

    await expectLater(
      fixture.receiver(wallet, 'new-pool'),
      throwsA(
        isA<StackRegtestCapabilityUnavailableException>().having(
          (error) => error.capability,
          'capability',
          'receiver',
        ),
      ),
    );
    await fixture.close();
  });

  test('bundle endpoint selector separates host and device delivery', () {
    final bundle = EndpointBundle.mapHost(
      hostEndpoints: {'lightwalletd': Uri.parse('http://127.0.0.1:9067')},
      deviceHost: '10.0.2.2',
    );

    expect(
      selectStackEndpoint(
        bundle,
        name: 'lightwalletd',
        audience: StackEndpointAudience.host,
      ).host,
      '127.0.0.1',
    );
    expect(
      selectStackEndpoint(
        bundle,
        name: 'lightwalletd',
        audience: StackEndpointAudience.device,
      ).host,
      '10.0.2.2',
    );
  });

  test(
    'close waits for an in-flight wallet acquisition and then cleans it',
    () async {
      final events = <String>[];
      final wallets = _BlockingWalletFactory(events);
      final fixture =
          await StackWalletRegtestFixture.open<_Wallet, Uri, String, String>(
            environmentFactory: () async => _Environment(events),
            backendFactory: (environment, cancellation) async =>
                _Resource('backend', events),
            endpointInjector: (
              environment,
              endpoint,
              audience,
              cancellation,
            ) async {},
            walletFactory: wallets,
          );
      await fixture.configure(Uri.parse('http://127.0.0.1:9067'));

      final create = fixture.create('late wallet');
      final close = fixture.close();
      var closeCompleted = false;
      unawaited(close.whenComplete(() => closeCompleted = true));
      await pumpEventQueue();
      expect(closeCompleted, isFalse);

      wallets.creation.complete(const _Wallet('late wallet'));
      await create;
      await close;
      expect(events, [
        'close wallet late wallet',
        'close backend',
        'close environment',
      ]);
    },
  );
}

final class _Wallet {
  const _Wallet(this.name);

  final String name;
}

final class _WalletFactory implements StackRegtestWalletFactory<_Wallet> {
  _WalletFactory(this.events);

  final List<String> events;

  @override
  Future<void> close(_Wallet wallet) async {
    events.add('close wallet ${wallet.name}');
  }

  @override
  Future<_Wallet> create(String name, RegtestCancellation cancellation) async {
    events.add('create $name');
    return _Wallet(name);
  }

  @override
  Future<_Wallet> reopen(
    _Wallet wallet,
    RegtestCancellation cancellation,
  ) async => _Wallet(wallet.name);

  @override
  Future<_Wallet> restore(
    String name,
    String recoveryMaterial,
    RegtestCancellation cancellation,
  ) async => _Wallet(name);
}

final class _BlockingWalletFactory
    implements StackRegtestWalletFactory<_Wallet> {
  _BlockingWalletFactory(this.events);

  final List<String> events;
  final creation = Completer<_Wallet>();

  @override
  Future<void> close(_Wallet wallet) async {
    events.add('close wallet ${wallet.name}');
  }

  @override
  Future<_Wallet> create(String name, RegtestCancellation cancellation) =>
      creation.future;

  @override
  Future<_Wallet> reopen(
    _Wallet wallet,
    RegtestCancellation cancellation,
  ) async => _Wallet(wallet.name);

  @override
  Future<_Wallet> restore(
    String name,
    String recoveryMaterial,
    RegtestCancellation cancellation,
  ) async => _Wallet(name);
}

base class _Environment implements RegtestResource {
  _Environment(this.events);

  final List<String> events;

  @override
  String diagnostics({int maxLines = 100}) => 'environment diagnostics';

  @override
  String get name => 'environment';

  @override
  Future<void> close() async {
    events.add('close environment');
  }
}

final class _ThrowingCloseEnvironment extends _Environment {
  _ThrowingCloseEnvironment(super.events);

  @override
  Future<void> close() async {
    await super.close();
    throw StateError('cleanup failed');
  }
}

final class _Resource implements RegtestResource {
  _Resource(this.name, this.events);

  @override
  final String name;

  final List<String> events;

  @override
  Future<void> close() async {
    events.add('close $name');
  }

  @override
  String diagnostics({int maxLines = 100}) => '$name diagnostics';
}
