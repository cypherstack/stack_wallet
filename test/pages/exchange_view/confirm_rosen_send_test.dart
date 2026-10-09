import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/input.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/pages/exchange_view/confirm_change_now_send.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_exchange.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_funding.dart';
import 'package:stackwallet/services/exchange/rosen/rosen_protocol.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/firo_op_return.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

import '../../sample_data/theme_json.dart';
import '../../services/exchange/rosen/rosen_test_utils.dart';

void main() {
  late Directory directory;
  late Box<Trade> trades;
  late Box<TradeWalletLookup> lookups;
  late Trade trade;
  final http = RosenTestHttp(
    (url) => url.host == 'app.rosen.tech'
        ? [
            {'network': 'firo', 'height': 1378335},
          ]
        : {
            'items': [rosenFeeBox()],
            'total': 1,
          },
  );

  Future<void> setUpBoxes() async {
    directory = await Directory.systemTemp.createTemp('rosen-confirm-ui-');
    final hive = DB.instance.hive;
    hive.init(directory.path);
    if (!hive.isAdapterRegistered(Trade.typeId)) {
      hive.registerAdapter(TradeAdapter());
    }
    final adapter = TradeWalletLookupAdapter();
    if (!hive.isAdapterRegistered(adapter.typeId)) {
      hive.registerAdapter(adapter);
    }
    trades = await hive.openBox<Trade>(DB.boxNameTradesV2);
    lookups = await hive.openBox<TradeWalletLookup>(DB.boxNameTradeLookup);
    await http.run(() async {
      trade = (await RosenExchange.instance.createTrade(
        from: 'FIRO',
        fromNetwork: 'firo',
        to: 'rsFIRO',
        toNetwork: 'eth',
        fixedRate: false,
        reversed: false,
        amount: Decimal.fromInt(100),
        addressTo: '0x00112233445566778899aabbccddeeff00112233',
        addressRefund: '',
        refundExtraId: '',
      )).value!.copyWith(tradeId: 'test-trade');
    });
    await trades.put(trade.uuid, trade);
  }

  for (final outcome in ['uncertain', 'rejected', 'submitted']) {
    testWidgets('saved $outcome deposit shows its verified submission state', (
      tester,
    ) async {
      await tester.runAsync(setUpBoxes);
      await tester.binding.setSurfaceSize(const Size(1000, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
        final closing = Future.wait([lookups.close(), trades.close()]);
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.runAsync(() async {
          await closing;
          await directory.delete(recursive: true);
        });
      });
      final txData = _prepared(trade);
      final wallet = _FundingWallet(txData, outcome);
      final observer = _UnlockObserver();
      final stackTheme = StackTheme.fromJson(json: lightThemeJsonMap);
      await http.run(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(_Wallets(wallet)),
              mainDBProvider.overrideWithValue(_FailingNotesDB()),
              pWalletCoin(wallet.walletId)
                  .overrideWithValue(wallet.cryptoCurrency),
              pWalletName(wallet.walletId).overrideWithValue('Bridge wallet'),
              pAmountFormatter(wallet.cryptoCurrency).overrideWithValue(
                AmountFormatter(
                  unit: AmountUnit.normal,
                  locale: 'en_US',
                  coin: wallet.cryptoCurrency,
                  maxDecimals: 8,
                ),
              ),
              coinImageSecondaryProvider(wallet.cryptoCurrency)
                  .overrideWithValue('firo.svg'),
              priceAnd24hChangeNotifierProvider.overrideWithValue(
                PriceService('USD'),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(0.7)),
                child: child!,
              ),
              navigatorObservers: [observer],
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(stackTheme)],
              ),
              home: ConfirmChangeNowSendView(
                txData: txData,
                walletId: wallet.walletId,
                trade: trade,
              ),
            ),
          ),
        );
        await tester.tap(find.widgetWithText(PrimaryButton, 'Send'));
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        if (outcome == 'submitted') {
          await tester.pump(const Duration(seconds: 5));
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(wallet.attempted.isCompleted, isTrue);
        final saved = trades.get(trade.uuid)!;
        expect(saved.payInTxid, isNotEmpty);
        expect(
          RosenFunding.fundingWalletId(saved),
          outcome == 'submitted' ? null : wallet.walletId,
        );
        expect(
          find.text(
            outcome == 'rejected'
                ? 'Bridge deposit needs attention'
                : outcome == 'submitted'
                ? 'Bridge deposit submitted'
                : 'Bridge deposit pending verification',
          ),
          findsOneWidget,
        );
        expect(find.byType(SendingTransactionDialog), findsNothing);
        expect(find.textContaining('Do not send again'), findsOneWidget);
        expect(find.text('Broadcast transaction failed'), findsNothing);
        final dialog = tester.widget<StackDialog>(find.byType(StackDialog));
        await tester.tap(
          find.descendant(
            of: find.byType(StackDialog),
            matching: find.text('Ok'),
          ),
        );
        await tester.pump();
        expect(dialog.title, startsWith('Bridge deposit'));
        expect(
          tester
              .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Send'))
              .enabled,
          isFalse,
        );
        expect(wallet.confirmations, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 6));
      });
    });
  }
}

class _UnlockObserver extends NavigatorObserver {
  bool unlocked = false;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute && !unlocked) {
      unlocked = true;
      scheduleMicrotask(() => navigator!.pop(true));
    }
  }
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);
  final Wallet wallet;
  @override
  Wallet getWallet(String walletId) => wallet;
}

class _Info extends Fake implements WalletInfo {
  @override
  bool get isViewOnly => false;
  @override
  CryptoCurrency get coin => Firo(CryptoCurrencyNetwork.main);
}

class _FailingNotesDB extends Fake implements MainDB {
  @override
  Future<void> putTransactionNote(TransactionNote note) async =>
      throw StateError('Local note storage unavailable');
}

class _FundingWallet extends Fake implements FiroWallet {
  _FundingWallet(this.txData, this.outcome)
    : electrumXClient = _Node(txData, outcome == 'rejected');
  final TxData txData;
  final String outcome;
  final attempted = Completer<void>();
  int confirmations = 0;
  @override
  final ElectrumXClient electrumXClient;
  @override
  final Firo cryptoCurrency = Firo(CryptoCurrencyNetwork.main);
  @override
  final WalletInfo info = _Info();
  @override
  String get walletId => 'confirmation-wallet';
  @override
  Future<int> fetchChainHeight({int retries = 1}) async => 1378335;
  @override
  Future<void> refresh() async {}
  @override
  Future<TxData> confirmSend({
    required TxData txData,
    Future<void> Function(String)? beforeBroadcast,
  }) async {
    confirmations++;
    await beforeBroadcast!(txData.raw!);
    attempted.complete();
    if (outcome == 'submitted') {
      return txData.copyWith(txid: firoTransactionFromHex(txData.raw!).txid);
    }
    throw StateError('Network acceptance unknown');
  }
}

class _Node extends Fake implements ElectrumXClient {
  _Node(this.txData, this.needsAttention);
  final TxData txData;
  final bool needsAttention;
  @override
  Future<dynamic> request({
    required String command,
    List<dynamic> args = const [],
    String? requestID,
    int retries = 2,
    Duration requestTimeout = const Duration(seconds: 60),
  }) async {
    if (needsAttention) {
      throw RpcException(-1, 'No such mempool or blockchain transaction');
    }
    throw StateError('Node unavailable');
  }

  @override
  Future<List<Map<String, dynamic>>> getUTXOs({
    required String scripthash,
    String? requestID,
  }) async => [
    {
      'tx_hash': '00' * 32,
      'tx_pos': 0,
      'value': txData.amountWithoutChange!.raw.toInt() + 1000,
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> getHistory({
    required String scripthash,
    String? requestID,
  }) async => [];
  @override
  Future<String> broadcastTransaction({
    required String rawTx,
    String? requestID,
  }) async => throw RpcException(-26, 'bad-txns-inputs-missingorspent');
}

TxData _prepared(Trade trade) {
  final amount = RosenProtocol.parseAmount(trade.payInAmount);
  final metadata = RosenExchange.validatedMetadata(trade);
  const signature =
      '304402206687c87c5f80c4e2a4e63fed02b0de65bcd38b77255b1de3f375f5d7'
      'a1b124c902202d5997a82c65d254e08ecc2ef7ba15995df3adfefa509b6ce0fdd'
      '65642a4062f';
  const publicKey =
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  final raw = coinlib.Transaction(
    version: 1,
    inputs: [
      coinlib.RawInput(
        prevOut: coinlib.OutPoint(Uint8List(32), 0),
        scriptSig: '47${signature}0121$publicKey'.toUint8ListFromHex,
      ),
    ],
    outputs: [
      coinlib.Output.fromScriptBytes(
        amount,
        RosenProtocol.firoScript(trade.payInAddress).toUint8ListFromHex,
      ),
      firoOpReturnOutput(metadata),
    ],
  ).toHex();
  return TxData(
    recipients: [
      TxRecipient(
        address: trade.payInAddress,
        amount: Amount(rawValue: amount, fractionDigits: 8),
        isChange: false,
        addressType: Firo(CryptoCurrencyNetwork.main).defaultAddressType,
      ),
    ],
    fee: Amount(rawValue: BigInt.from(1000), fractionDigits: 8),
    raw: raw,
    opReturnData: metadata,
    usedUTXOs: [
      StandardInput(
        UTXO(
          walletId: 'confirmation-wallet',
          txid: '00' * 32,
          vout: 0,
          value: (amount + BigInt.from(1000)).toInt(),
          name: '',
          isBlocked: false,
          blockedReason: null,
          isCoinbase: false,
          blockHash: null,
          blockHeight: null,
          blockTime: null,
          address: trade.payInAddress,
        ),
      ),
    ],
  );
}
