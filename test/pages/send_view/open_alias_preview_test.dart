import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/coin_image_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../sample_data/theme_json.dart';

const literal =
    '4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FH'
    'XDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gp4nn';
Amount amount(int value) =>
    Amount(rawValue: BigInt.from(value), fractionDigits: 12);

class _Monero extends Monero {
  _Monero() : super(CryptoCurrencyNetwork.main);
  @override
  bool validateAddress(String address) =>
      address == literal || address == 'second-recipient';
  @override
  AddressType? getAddressType(String address) {
    if (!validateAddress(address)) {
      throw StateError('Unresolved recipient: $address');
    }
    return AddressType.cryptonote;
  }
}

class _Info extends Fake implements WalletInfo {
  _Info(this.coin);
  @override
  final CryptoCurrency coin;
  @override
  String get walletId => 'wallet';
  @override
  String get name => 'Test wallet';
  @override
  bool get isMwebEnabled => false;
  @override
  Balance get cachedBalance => Balance(
    total: amount(10000000000000),
    spendable: amount(10000000000000),
    blockedTotal: amount(0),
    pendingSpendable: amount(0),
  );
}

class _Wallet extends Fake implements CryptonoteWallet {
  _Wallet(this.cryptoCurrency) : info = _Info(cryptoCurrency);
  @override
  final Monero cryptoCurrency;
  @override
  final WalletInfo info;
  final prepared = <TxData>[];
  Completer<TxData>? preparation;
  final sent = <TxData>[];
  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    sent.add(txData);
    throw StateError('simulated broadcast failure');
  }

  @override
  Future<FeeObject> get fees async => FeeObject(
    numberOfBlocksFast: 1,
    numberOfBlocksAverage: 2,
    numberOfBlocksSlow: 3,
    fast: BigInt.one,
    medium: BigInt.one,
    slow: BigInt.one,
  );
  @override
  int getTxPriorityHigh() => 3;
  @override
  int getTxPriorityMedium() => 2;
  @override
  int getTxPriorityNormal() => 1;
  @override
  Future<Amount> estimateFeeFor(Amount value, BigInt feeRate) async =>
      amount(10);
  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    prepared.add(txData);
    return preparation?.future ?? txData.copyWith(fee: amount(10));
  }
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);
  final Wallet wallet;
  @override
  Wallet getWallet(String walletId) => wallet;
}

class _Prefs extends ChangeNotifier implements Prefs {
  @override
  String get currency => 'USD';
  @override
  bool get externalCalls => false;
  @override
  bool get enableCoinControl => false;
  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;
  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthObserver extends NavigatorObserver {
  bool approveNext = false;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (approveNext) {
      approveNext = false;
      // Supply the authentication result without involving PIN/password storage.
      scheduleMicrotask(() => navigator!.pop(true));
    }
  }
}

class _Harness {
  final bool desktop;
  final _Monero coin = _Monero();
  late final _Wallet wallet = _Wallet(coin);
  late final ProviderContainer container;
  final navigator = GlobalKey<NavigatorState>();
  final identity = ValueNotifier('wallet');
  final visible = ValueNotifier(true);
  final auth = _AuthObserver();
  final lookups = <Completer<List<String>>>[];
  int get calls => lookups.length;
  _Harness(this.desktop);

  Future<void> mount(
    WidgetTester tester, {
    SendViewAutoFillData? autofill,
  }) async {
    final size = desktop ? const Size(1200, 900) : const Size(390, 844);
    final previousLayout = Util.debugIsDesktopOverride;
    final previousWidth = Util.screenWidth;
    Util.debugIsDesktopOverride = desktop;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    Util.screenWidth = size.width;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      Util.debugIsDesktopOverride = previousLayout;
      Util.screenWidth = previousWidth;
    });
    expect(Util.isDesktop, desktop);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    container = ProviderContainer(
      overrides: [
        themeProvider.overrideWithProvider(StateProvider((_) => theme)),
        pWallets.overrideWithValue(_Wallets(wallet)),
        for (final id in ['wallet', 'other-wallet']) ...[
          pWalletInfo(id).overrideWithValue(wallet.info),
          pWalletCoin(id).overrideWithValue(coin),
          pWalletName(id).overrideWithValue('Test wallet'),
          pWalletBalance(id).overrideWithValue(wallet.info.cachedBalance),
        ],
        prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
        coinIconProvider(coin)
            .overrideWithValue('test/sample_data/light/assets/dummy.svg'),
        coinImageSecondaryProvider(coin).overrideWithValue('dummy.svg'),
        pSendOpenAliasService.overrideWithValue(
          OpenAliasService(
            externalCalls: () => true,
            useTor: () => false,
            lookup: (domain, _) {
              if (domain != 'alice.example') {
                throw StateError('Unexpected lookup: $domain');
              }
              final pending = Completer<List<String>>();
              lookups.add(pending);
              return pending.future;
            },
          ),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
      identity.dispose();
      visible.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [auth],
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => ValueListenableBuilder(
            valueListenable: visible,
            builder: (_, show, _) => !show
                ? const SizedBox()
                : ValueListenableBuilder(
                    valueListenable: identity,
                    builder: (_, id, _) => desktop
                        ? Scaffold(
                            body: SingleChildScrollView(
                              child: DesktopSend(
                                walletId: id,
                                autoFillData: autofill,
                              ),
                            ),
                          )
                        : SendView(
                            walletId: id,
                            coin: coin,
                            autoFillData: autofill,
                          ),
                  ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Finder get field => find.byKey(const Key('sendViewAddressFieldKey'));
  Finder get button => find.text(desktop ? 'Preview send' : 'Preview');
  String source(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;
  bool enabled(WidgetTester tester) => desktop
      ? tester
            .widget<PrimaryButton>(
              find.ancestor(of: button, matching: find.byType(PrimaryButton)),
            )
            .enabled
      : tester
                .widget<TextButton>(
                  find.ancestor(of: button, matching: find.byType(TextButton)),
                )
                .onPressed !=
            null;

  Future<void> enter(WidgetTester tester, String destination) async {
    await tester.enterText(field, destination);
    await tester.pumpAndSettle();
  }

  Future<void> setAmount(WidgetTester tester) async {
    container.read(pSendAmount.notifier).state = amount(1000000000000);
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester, {bool twice = false}) async {
    await tester.ensureVisible(button);
    if (twice) {
      final callback = desktop
          ? tester
                .widget<PrimaryButton>(
                  find.ancestor(
                    of: button,
                    matching: find.byType(PrimaryButton),
                  ),
                )
                .onPressed!
          : tester
                .widget<TextButton>(
                  find.ancestor(of: button, matching: find.byType(TextButton)),
                )
                .onPressed!;
      callback();
      callback();
    } else {
      await tester.tap(button);
    }
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  void succeed([String destination = literal]) =>
      lookups.last.complete(['oa1:xmr recipient_address=$destination;']);
}

void main() {
  for (final desktop in [false, true]) {
    final layout = desktop ? 'desktop 1200x900' : 'mobile 390x844';
    testWidgets(
      '$layout resolves on Preview and shows each prepared recipient',
      (tester) async {
        final h = _Harness(desktop);
        await h.mount(tester);
        await h.enter(tester, 'Alice@Example');
        expect(h.calls, 0);
        expect(h.enabled(tester), isFalse);
        expect(h.container.read(pValidSendToAddress), isFalse);
        expect(find.text('Invalid address'), findsNothing);
        expect(find.text('Use OpenAlias'), findsNothing);
        await h.setAmount(tester);
        expect(h.enabled(tester), isTrue);
        expect(h.calls, 0); // Amount changes and fee estimation are local.
        await h.preview(tester, twice: true);
        expect(h.calls, 1);
        expect(h.wallet.prepared, isEmpty);
        h.succeed();
        await h.finish(tester);
        expect(h.wallet.prepared.single.recipients!.single.address, literal);
        expect(
          h.wallet.prepared.single.openAliasRecipient!.domain,
          'alice.example',
        );
        expect(find.text('alice.example'), findsNothing);
        expect(find.byType(ConfirmTransactionView), findsOneWidget);
        expect(find.text('alice@example'), findsOneWidget);
        expect(find.text(literal), findsOneWidget);
        h.navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(h.source(tester), 'Alice@Example');
        await h.preview(tester);
        expect(h.calls, 2);
        h.succeed('second-recipient');
        await h.finish(tester);
        expect(
          h.wallet.prepared.last.recipients!.single.address,
          'second-recipient',
        );
        expect(find.text('second-recipient'), findsOneWidget);
        expect(find.text('alice@example'), findsOneWidget);
        // Final send receives the prepared transaction, without another lookup.
        h.auth.approveNext = true;
        await tester.ensureVisible(find.text('Send'));
        await tester.tap(find.text('Send'));
        await h.finish(tester);
        expect(
          h.wallet.sent.single.recipients!.single.address,
          'second-recipient',
        );
        expect(
          h.wallet.sent.single.openAliasRecipient!.domain,
          'alice.example',
        );
        expect(h.calls, 2);
      },
    );

    testWidgets('$layout lookup failure retains input and the send route', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, 'Alice@Example');
      await h.setAmount(tester);
      await h.preview(tester);
      h.lookups.single.completeError(
        const OpenAliasException('DNSSEC verification failed.'),
      );
      await h.finish(tester);
      expect(h.wallet.prepared, isEmpty);
      expect(find.byType(ConfirmTransactionView), findsNothing);
      expect(find.text('OpenAlias lookup failed'), findsOneWidget);
      expect(find.text('Transaction failed'), findsNothing);
      expect(find.text('DNSSEC verification failed.'), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
      expect(h.source(tester), 'Alice@Example');
      expect(h.navigator.currentState!.canPop(), isTrue);
      expect(h.enabled(tester), isTrue);
    });

    for (final change in [
      'edit away and back',
      'amount',
      'cancel',
      'wallet',
      'dispose',
    ]) {
      testWidgets('$layout $change discards a pending lookup', (tester) async {
        final h = _Harness(desktop);
        await h.mount(tester);
        await h.enter(tester, 'Alice@Example');
        await h.setAmount(tester);
        await h.preview(tester);
        expect(h.calls, 1);
        switch (change) {
          case 'edit away and back':
            final controller = tester.widget<TextField>(h.field).controller!;
            controller.text = 'bob.example';
            controller.text = 'Alice@Example';
          case 'amount':
            h.container.read(pSendAmount.notifier).state = amount(2);
          case 'cancel':
            await tester.tap(find.text('Cancel'));
          case 'wallet':
            h.identity.value = 'other-wallet';
            await tester.pump();
            h.identity.value = 'wallet';
            await tester.pump();
          case 'dispose':
            h.visible.value = false;
            await tester.pump();
        }
        h.succeed();
        await h.finish(tester);
        expect(h.wallet.prepared, isEmpty);
        expect(find.byType(ConfirmTransactionView), findsNothing);
        expect(find.text('Transaction failed'), findsNothing);
        expect(find.text('OpenAlias lookup failed'), findsNothing);
        expect(h.navigator.currentState!.canPop(), isTrue);
      });
    }

    for (final fail in [false, true]) {
      testWidgets('$layout cancellation during preparation ignores late '
          '${fail ? 'error' : 'success'}', (tester) async {
        final h = _Harness(desktop);
        await h.mount(tester);
        h.wallet.preparation = Completer<TxData>();
        await h.enter(tester, 'Alice@Example');
        await h.setAmount(tester);
        await h.preview(tester);
        h.succeed();
        await tester.pump();
        expect(h.wallet.prepared, hasLength(1));
        await tester.tap(find.text('Cancel'));
        if (fail) {
          h.wallet.preparation!.completeError(
            StateError('late preparation failure'),
          );
        } else {
          h.wallet.preparation!.complete(
            h.wallet.prepared.single.copyWith(fee: amount(10)),
          );
        }
        await h.finish(tester);
        expect(find.byType(ConfirmTransactionView), findsNothing);
        expect(find.text('Transaction failed'), findsNothing);
        expect(h.source(tester), 'Alice@Example');
        expect(h.navigator.currentState!.canPop(), isTrue);
      });
    }
    for (final input in ['literal', 'contact', 'uri']) {
      testWidgets('$layout $input prepares a literal address without lookup', (
        tester,
      ) async {
        final h = _Harness(desktop);
        await h.mount(
          tester,
          autofill: input == 'contact'
              ? SendViewAutoFillData(
                  address: literal,
                  contactLabel: 'Alice contact',
                )
              : null,
        );
        if (input != 'contact') {
          await h.enter(
            tester,
            input == 'uri' ? 'monero:$literal?amount=1' : literal,
          );
        }
        await h.setAmount(tester);
        expect(h.enabled(tester), isTrue);
        await h.preview(tester);
        await h.finish(tester);
        expect(h.calls, 0);
        expect(h.wallet.prepared.single.recipients!.single.address, literal);
        expect(h.wallet.prepared.single.openAliasRecipient, isNull);
      });
    }
  }
}
