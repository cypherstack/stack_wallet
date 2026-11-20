import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/all_transactions_v2_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_card.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/transaction_note_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../sample_data/theme_json.dart';

void main() {
  final originalPlatform = Util.layoutPlatform;
  tearDown(() => Util.layoutPlatform = originalPlatform);

  for (final testCase in [
    (name: 'mobile', platform: FakePlatform(operatingSystem: 'android')),
    (name: 'desktop', platform: FakePlatform(operatingSystem: 'linux')),
  ]) {
    testWidgets('${testCase.name} partial transaction UI shows unknown facts', (
      tester,
    ) async {
      Util.layoutPlatform = testCase.platform;
      final transaction = _partialTransaction();

      await tester.pumpWidget(
        _harness(TransactionCardV2(transaction: transaction)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.textContaining('0.00000123'), findsOneWidget);

      await tester.pumpWidget(
        _harness(
          TransactionV2DetailsView(
            transaction: transaction,
            walletId: transaction.walletId,
            coin: _coin,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Unknown'), findsWidgets);
      expect(find.text('Transaction data'), findsOneWidget);
      expect(find.text('Transaction fee'), findsOneWidget);
      expect(find.text('Memo'), findsOneWidget);
      expect(find.text('Transaction version'), findsOneWidget);
    });
  }

  testWidgets('unknown wallet amount is not derived from incomplete data', (
    tester,
  ) async {
    Util.layoutPlatform = FakePlatform(operatingSystem: 'android');
    final transaction = _partialTransaction(includeWalletNet: false);

    await tester.pumpWidget(
      _harness(TransactionCardV2(transaction: transaction)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Unknown'), findsNWidgets(2));
  });

  testWidgets('desktop table shows an unknown timestamp', (tester) async {
    Util.layoutPlatform = FakePlatform(operatingSystem: 'linux');
    final transaction = _partialTransaction();

    await tester.pumpWidget(
      _harness(
        DesktopTransactionCardRow(
          transaction: transaction,
          walletId: transaction.walletId,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Unknown'), findsOneWidget);
  });
}

final _coin = Bitcoin(CryptoCurrencyNetwork.main);

TransactionV2 _partialTransaction({bool includeWalletNet = true}) =>
    TransactionV2(
      walletId: 'wallet',
      blockHash: null,
      hash: 'hash',
      txid: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      timestamp: 0,
      height: 10,
      inputs: const [],
      outputs: const [],
      version: -1,
      type: TransactionType.outgoing,
      subType: TransactionSubType.none,
      otherData: jsonEncode({
        TxV2OdKeys.metadataStatus: TxV2OdKeys.metadataStatusPartial,
        TxV2OdKeys.missingMetadata: [
          'timestamp',
          'blockHash',
          'fee',
          'memo',
          'transactionVersion',
          if (!includeWalletNet) 'walletNetAmount',
        ],
        if (includeWalletNet) TxV2OdKeys.walletNetAmountRaw: '-123',
      }),
    );

Widget _harness(Widget child) {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final prefs = _TestPrefs();
  return ProviderScope(
    overrides: [
      pWallets.overrideWithValue(_TestWallets()),
      prefsChangeNotifierProvider.overrideWithValue(prefs),
      pWalletCoin.overrideWithProvider((_) => Provider((_) => _coin)),
      pWalletChainHeight.overrideWithProvider((_) => Provider((_) => 20)),
      pTransactionNote.overrideWithProvider((_) => Provider((_) => null)),
      themeProvider.overrideWithValue(StateController(theme)),
      themeAssetsProvider.overrideWithProvider(
        StateProvider((_) => theme.assets),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
      home: Scaffold(body: child),
    ),
  );
}

class _TestWallet extends Fake implements Wallet {
  @override
  CryptoCurrency get cryptoCurrency => _coin;
}

class _TestWallets extends Fake implements Wallets {
  @override
  Wallet getWallet(String walletId) => _TestWallet();
}

class _TestPrefs extends ChangeNotifier implements Prefs {
  @override
  String get currency => 'USD';

  @override
  bool get externalCalls => false;

  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;

  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
