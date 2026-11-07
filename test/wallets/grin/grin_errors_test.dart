import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/exceptions/wallet/insufficient_balance_exception.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/supporting/grin/grin_errors.dart';

import '../support/grin_fakes.dart';

/// Runs [body] and returns everything printed, which is where Logging goes
/// in tests.
Future<String> captureLogs(Future<void> Function() body) async {
  final out = StringBuffer();
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => out.writeln(line),
    ),
  );
  return out.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sanitizeGrinError', () {
    test('no library message in any user string', () {
      for (var code = 1; code <= 23; code++) {
        final error = grinError(
          code,
          details: {'slate_id': 'slate-x', 'wallet_dir': '/secret/dir'},
        );
        final safe = sanitizeGrinError(error);
        expect(safe.toString(), isNot(contains(remoteText)), reason: '$code');
        expect(safe.toString(), isNot(contains('/secret/dir')));
        expect(describeGrinError(error), isNot(contains(remoteText)));
        if (code == 10) {
          expect(safe, isA<InsufficientBalanceException>());
        } else {
          final wallet = safe as GrinWalletException;
          expect(wallet.code, code);
          expect(wallet.slateId, 'slate-x');
          expect(wallet.type, error.runtimeType.toString());
        }
      }
    });

    test('a node error with a slate id means finalized, not broadcast', () {
      final safe = sanitizeGrinError(
        grinError(9, details: {'slate_id': 's'}),
      ) as GrinWalletException;
      expect(safe.finalizedNotBroadcast, isTrue);
      expect(
        (sanitizeGrinError(
          grinError(9),
        ) as GrinWalletException).finalizedNotBroadcast,
        isFalse,
      );
    });

    test('other errors keep only their type', () {
      final safe = sanitizeGrinError(const FormatException(remoteText));
      expect(safe.toString(), isNot(contains(remoteText)));
      expect(safe.toString(), contains('FormatException'));
    });
  });

  group('wallet calls', () {
    late Directory dataRoot;
    late Directory isarRoot;
    late Isar isar;
    late GrinHarness h;

    setUpAll(() async => dataRoot = await setUpGrinTests());
    tearDownAll(() => dataRoot.delete(recursive: true));
    setUp(() async {
      isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
      isar = await openTestIsar(isarRoot);
      h = await GrinHarness.create();
    });
    tearDown(() async {
      await h.dispose();
      await isar.close();
      await isarRoot.delete(recursive: true);
    });

    test('failures surface and log without remote text, slatepacks, the '
        'mnemonic or the password', () async {
      final shown = <String>[];
      final logs = await captureLogs(() async {
        await h.wallet.init();
        final api = h.backend.api;
        final password = h.backend.creates.single.password;

        api.sendError = grinError(19);
        api.estimateError = null;
        try {
          await h.wallet.confirmSend(
            txData: TxData(
              recipients: [
                TxRecipient(
                  address: 'grin1friend',
                  amount: Amount(rawValue: BigInt.from(5), fractionDigits: 9),
                  isChange: false,
                  addressType: AddressType.mimbleWimble,
                ),
              ],
            ),
          );
        } catch (e) {
          shown.add('$e');
        }

        h.backend.nodeError = grinError(9);
        try {
          await h.wallet.updateChainHeight();
        } catch (e) {
          shown.add('$e');
        }

        api.decoded = null;
        try {
          await h.wallet.inspectSlatepack(
            'BEGINSLATEPACK. secret-slate ENDSLATEPACK.',
          );
        } catch (e) {
          shown.add('$e');
        }

        shown.add(
          await h.wallet.cancelPendingTransactionAndPost('missing-slate'),
        );

        final s1 = await h.wallet.receiveSlatepack(
          'BEGINSLATEPACK. incoming ENDSLATEPACK.',
        );
        expect(s1.state, SlateState.s2);

        expect(password, isNotEmpty);
        shown.add(password);
      });

      final password = shown.removeLast();
      expect(shown, hasLength(4));
      for (final text in [...shown, logs]) {
        expect(text, isNot(contains(remoteText)));
        expect(text, isNot(contains('SLATEPACK')));
        expect(text, isNot(contains('abandon')));
        expect(text, isNot(contains(password)));
        expect(text, isNot(contains('secret-slate')));
      }
    });

    test('logs never print a node API secret', () async {
      final logs = await captureLogs(() async {
        h.wallet.node = grinNode(secret: 'node-api-secret');
        await h.wallet.init();
        h.backend.nodeError = grinError(9);
        try {
          await h.wallet.updateChainHeight();
        } catch (_) {}
        await h.wallet.updateNode();
      });
      expect(logs, isNot(contains('node-api-secret')));
    });
  });
}
