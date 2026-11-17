import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/input_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/output_v2.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/transaction_note_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/slatepack_terms.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/grin_wallet.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _RepostDetailsWallet extends Fake implements GrinWallet {
  @override
  final cryptoCurrency = Grin(CryptoCurrencyNetwork.main);

  @override
  String get walletId => 'grin-repost-details';

  final reposted = <String>[];
  bool broadcastPosted = false;

  @override
  bool get supportsOnChainNote => false;

  @override
  bool get supportsPaymentProofs => false;

  @override
  bool get supportsRepost => true;

  @override
  SlatepackTerms get slatepackTerms => SlatepackTerms.slatepack;

  @override
  Future<void> repost(String txid) async {
    reposted.add(txid);
    broadcastPosted = true;
  }

  @override
  SlatepackTxInfo? slatepackTxInfo(TransactionV2 tx) => SlatepackTxInfo(
    state: SlateState.s3,
    slateId: tx.slateId,
    finalizedAwaitingConfirmation: true,
    broadcastPosted: broadcastPosted,
    canRepost: true,
  );
}

void main() {
  testWidgets('successful repost immediately removes transaction Cancel', (
    tester,
  ) async {
    final wallet = _RepostDetailsWallet();
    final transaction = TransactionV2(
      walletId: wallet.walletId,
      blockHash: null,
      hash: '08ab',
      txid: 'slate-1',
      timestamp: 0,
      height: null,
      inputs: [
        InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: null,
          scriptSigAsm: null,
          sequence: null,
          outpoint: null,
          addresses: const [],
          valueStringSats: '1100',
          witness: null,
          innerRedeemScriptAsm: null,
          coinbase: null,
          walletOwns: true,
        ),
      ],
      outputs: [
        OutputV2.isarCantDoRequiredInDefaultConstructor(
          scriptPubKeyHex: '',
          valueStringSats: '1000',
          addresses: const [],
          walletOwns: false,
        ),
      ],
      version: 0,
      type: TransactionType.outgoing,
      subType: TransactionSubType.none,
      otherData: jsonEncode({
        TxV2OdKeys.isGrinTransaction: true,
        TxV2OdKeys.slateId: 'slate-1',
        TxV2OdKeys.grinSlateState: 'S3',
        TxV2OdKeys.grinHasStoredTx: true,
      }),
    );
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletChainHeight(wallet.walletId).overrideWithValue(0),
          pTransactionNote((walletId: wallet.walletId, txid: transaction.txid))
              .overrideWithValue(null),
          prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          pAmountFormatter(wallet.cryptoCurrency).overrideWithValue(
            AmountFormatter(
              unit: AmountUnit.normal,
              locale: 'en_US',
              coin: wallet.cryptoCurrency,
              maxDecimals: 9,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: TransactionV2DetailsView(
            transaction: transaction,
            walletId: wallet.walletId,
            coin: wallet.cryptoCurrency,
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Cancel transaction'), findsOneWidget);

    await tester.ensureVisible(find.text('Repost'));
    await tester.tap(find.text('Repost'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Repost').last);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(wallet.reposted, ['slate-1']);
    expect(find.text('Cancel transaction'), findsNothing);
  });
}
