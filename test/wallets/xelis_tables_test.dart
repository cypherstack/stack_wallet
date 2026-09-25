import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/xelis_wallet.dart';
import 'package:stackwallet/wallets/wallet/intermediate/lib_xelis_wallet.dart';
import 'package:stackwallet/wl_gen/interfaces/lib_xelis_interface.dart';

class TableSecrets extends Fake implements SecureStorageInterface {
  final values = <String, String>{};
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    switch (invocation.memberName) {
      case #read:
        return Future<String?>.value(values[key]);
      case #write:
        values[key] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      default:
        return super.noSuchMethod(invocation);
    }
  }
}

class TableNative extends Fake implements LibXelisInterface {
  bool fullPresent = false;
  int updates = 0;
  Completer<void>? started;
  Completer<void>? release;
  @override
  Future<bool> hasTables({
    required String precomputedTablesPath,
    // Matches the existing LibXelisInterface parameter name.
    // ignore: non_constant_identifier_names
    required bool stack_l1Low,
  }) async => fullPresent;

  @override
  Future<void> updateTables({
    required String precomputedTablesPath,
    // Matches the existing LibXelisInterface parameter name.
    // ignore: non_constant_identifier_names
    required bool stack_l1Low,
  }) async {
    updates++;
    if (!(started?.isCompleted ?? true)) started!.complete();
    await release?.future;
    if (!stack_l1Low) fullPresent = true;
  }
}

class TableWallet extends XelisWallet {
  TableWallet(TableNative native, TableSecrets secrets)
    : super(CryptoCurrencyNetwork.test, native: native) {
    secureStorageInterface = secrets;
  }
  @override
  Future<String> getPrecomputedTablesPath() async => 'isolated-table-test';
}

void main() {
  test(
    'two wallets share one table generation and report it in flight',
    () async {
      final native = TableNative()
        ..started = Completer<void>()
        ..release = Completer<void>();
      final secrets = TableSecrets();
      final first = TableWallet(native, secrets);
      final second = TableWallet(native, secrets);
      final operation = first.updateTablesToDesiredSize();
      final joined = second.updateTablesToDesiredSize();
      expect(identical(operation, joined), isTrue);
      await native.started!.future;
      expect((await second.getTableState()).isGenerating, isTrue);
      native.release!.complete();
      await Future.wait([operation, joined]);
      expect(native.updates, 1);
      final state = await second.getTableState();
      expect(state.isGenerating, isFalse);
      expect(state.currentSize, XelisTableSize.full);
      await second.updateTablesToDesiredSize();
      expect(native.updates, 1);
    },
  );

  test(
    'generation failure reaches all callers and permits a fresh attempt',
    () async {
      final native = TableNative()
        ..started = Completer<void>()
        ..release = Completer<void>();
      final secrets = TableSecrets();
      final first = TableWallet(native, secrets);
      final second = TableWallet(native, secrets);
      final failure = StateError('table generation failed');
      final firstCheck = expectLater(
        first.updateTablesToDesiredSize(),
        throwsA(same(failure)),
      );
      final secondCheck = expectLater(
        second.updateTablesToDesiredSize(),
        throwsA(same(failure)),
      );
      await native.started!.future;
      native.release!.completeError(failure);
      await Future.wait([firstCheck, secondCheck]);
      expect((await first.getTableState()).isGenerating, isFalse);
      expect(native.updates, 1);
      native.release = null;
      await second.updateTablesToDesiredSize();
      expect(native.updates, 2);
      expect((await first.getTableState()).currentSize, XelisTableSize.full);
    },
  );

  test(
    'stale persisted flags cannot hide missing tables or block generation',
    () async {
      final native = TableNative();
      final secrets = TableSecrets()
        ..values['xelis_has_full_tables'] = 'true'
        ..values['xelis_generating_tables'] = 'true';
      final wallet = TableWallet(native, secrets);
      final state = await wallet.getTableState();
      expect(state.currentSize, XelisTableSize.low);
      expect(state.isGenerating, isFalse);
      await wallet.updateTablesToDesiredSize();
      expect(native.updates, 1);
      expect((await wallet.getTableState()).currentSize, XelisTableSize.full);
    },
  );

  test(
    'finishing generation preserves a preference changed by another wallet',
    () async {
      final native = TableNative()
        ..started = Completer<void>()
        ..release = Completer<void>();
      final secrets = TableSecrets();
      final first = TableWallet(native, secrets);
      final second = TableWallet(native, secrets);
      final operation = first.updateTablesToDesiredSize();
      await native.started!.future;
      await second.setTableState(
        const XelisTableState(
          isGenerating: true,
          desiredSize: XelisTableSize.low,
        ),
      );
      native.release!.complete();
      await operation;
      final state = await first.getTableState();
      expect(state.desiredSize, XelisTableSize.low);
      expect(state.isGenerating, isFalse);
      expect(secrets.values['xelis_wants_full_tables'], 'false');
    },
  );
}
