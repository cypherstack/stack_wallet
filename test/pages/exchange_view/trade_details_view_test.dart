import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/trade_details_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_details_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/transaction_v2_list_item.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/transaction_note_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/exchange/exolix/exolix_exchange.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/trade_notes_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/trade_card.dart';

import '../../sample_data/theme_json.dart';
import '../send_view/support/fake_wallets.dart';

class _ThemeService extends Mock implements ThemeService {}

class _Prefs extends Mock implements Prefs {
  _Prefs(this.unit);

  final AmountUnit unit;

  @override
  bool get externalCalls => false;

  @override
  String get currency => 'USD';

  @override
  bool get useTor => false;

  @override
  AmountUnit amountUnit(CryptoCurrency coin) => unit;

  @override
  int maxDecimals(CryptoCurrency coin) => 8;
}

class _TokenDB extends Fake implements MainDB {
  @override
  EthContract getEthContractSync(String address) => testEthContract;
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);
  final Wallet wallet;

  @override
  Wallet getWallet(String walletId) => wallet;
}

class _LocaleService extends LocaleService {
  @override
  String get locale => 'en_US';
}

class _Trades extends TradesService {
  _Trades(this._trades);

  final List<Trade> _trades;

  @override
  List<Trade> get trades => _trades;
}

class _Notes extends TradeNotesService {
  @override
  String getNote({required String tradeId}) => "";
}

Trade _trade({required String payInCurrency}) => Trade(
  uuid: "uuid",
  tradeId: "trade-1",
  rateType: "estimated",
  direction: "direct",
  timestamp: DateTime.utc(2026, 11, 15),
  updatedAt: DateTime.utc(2026, 11, 15),
  payInCurrency: payInCurrency,
  payInAmount: "0.02",
  payInAddress: "deposit-address",
  payInNetwork: "",
  payInExtraId: "",
  payInTxid: "",
  payOutCurrency: "ETH",
  payOutAmount: "0.7",
  payOutAddress: "payout-address",
  payOutNetwork: "",
  payOutExtraId: "",
  payOutTxid: "",
  refundAddress: "refund-address",
  refundExtraId: "",
  status: "Waiting",
  exchangeName: ExolixExchange.exchangeName,
);

Future<void> _pump(
  WidgetTester tester,
  Trade trade, {
  AmountUnit unit = AmountUnit.normal,
  Widget? home,
  Wallets? wallets,
  List<Override> overrides = const [],
}) async {
  // The full details layout does not fit the default 800x600 test surface.
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final themeService = _ThemeService();
  when(themeService.getTheme(themeId: 'light')).thenReturn(theme);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pThemeService.overrideWithValue(themeService),
        prefsChangeNotifierProvider.overrideWithValue(_Prefs(unit)),
        localeServiceChangeNotifierProvider.overrideWithValue(_LocaleService()),
        tradesServiceProvider.overrideWithValue(_Trades([trade])),
        tradeNoteServiceProvider.overrideWithValue(_Notes()),
        pWallets.overrideWithValue(wallets ?? Wallets.sharedInstance),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        onGenerateRoute: RouteGenerator.generateRoute,
        home:
            home ??
            TradeDetailsView(
              tradeId: trade.tradeId,
              transactionIfSentFromStack: null,
              walletId: null,
              walletName: null,
            ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('mobile token trade card opens its linked V2 transaction', (
    tester,
  ) async {
    final previousWidth = Util.screenWidth;
    Util.screenWidth = 390;
    addTearDown(() => Util.screenWidth = previousWidth);
    final wallet = FakeEthereumWallet();
    final tx = TransactionV2(
      walletId: wallet.walletId,
      blockHash: null,
      hash: 'hash',
      txid: 'token-send',
      timestamp: 1,
      height: 1,
      inputs: [],
      outputs: [],
      version: -1,
      type: TransactionType.outgoing,
      subType: TransactionSubType.ethToken,
      otherData: jsonEncode({
        TxV2OdKeys.contractAddress: testEthContract.address,
        TxV2OdKeys.nonce: 1,
        TxV2OdKeys.overrideFee: Amount(
          rawValue: BigInt.one,
          fractionDigits: 18,
        ).toJsonString(),
      }),
    );
    final trade = _trade(payInCurrency: testEthContract.symbol)
        .copyWith(payInTxid: tx.txid, status: 'Finished');

    await _pump(
      tester,
      trade,
      home: Scaffold(
        body: TxListItem(tx: tx, coin: wallet.cryptoCurrency),
      ),
      wallets: _Wallets(wallet),
      overrides: [
        mainDBProvider.overrideWithValue(_TokenDB()),
        pWalletName(tx.walletId).overrideWithValue('Sending wallet'),
        pWalletCoin(tx.walletId).overrideWithValue(wallet.cryptoCurrency),
        pWalletChainHeight(tx.walletId).overrideWithValue(100),
        pTransactionNote((walletId: tx.walletId, txid: tx.txid))
            .overrideWithValue(null),
      ],
    );
    await tester.tap(find.byType(TradeCard));
    await tester.pumpAndSettle();
    expect(find.text('Sending wallet'), findsOneWidget);
    final link = find.text('View transaction', findRichText: true);
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    final details = tester.widget<TransactionV2DetailsView>(
      find.byType(TransactionV2DetailsView),
    );
    expect(details.transaction, same(tx));
    expect(details.walletId, tx.walletId);
    expect(details.coin, same(wallet.cryptoCurrency));
  });

  testWidgets("shows the pay-in ticker once for a known coin", (tester) async {
    await _pump(tester, _trade(payInCurrency: "BTC"));

    expect(find.text("-0.02000000 BTC"), findsOneWidget);
    expect(find.textContaining("BTC BTC"), findsNothing);
  });

  testWidgets("shows the user's display unit instead of the ticker", (
    tester,
  ) async {
    await _pump(tester, _trade(payInCurrency: "BTC"), unit: AmountUnit.nano);

    // 0.02 BTC in sats; the ticker must not be appended to a shifted amount.
    expect(find.textContaining(RegExp(r"^-[\d,]+ sats$")), findsOneWidget);
    expect(find.textContaining(RegExp(r"^-.*BTC")), findsNothing);
  });

  testWidgets("shows the pay-in ticker for an unknown coin", (tester) async {
    await _pump(tester, _trade(payInCurrency: "FOO"));

    expect(find.text("-0.02000000 FOO"), findsOneWidget);
  });
}
