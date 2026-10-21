import 'dart:async';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/send_view_auto_fill_data.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
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
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';

const literal =
    '4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FH'
    'XDA6i1DnQTd6h8R3VU5AkbGcWSNhtSwNNPgaD48gp4nn';
const alias = 'Alice@Example.com';
const balance = 10000000000000;

Amount amount(int value) =>
    Amount(rawValue: BigInt.from(value), fractionDigits: 12);

bool _isValid(String address) =>
    address == literal || address == 'second-recipient';

AddressType _addressType(String address) {
  if (!_isValid(address)) throw StateError('Unresolved recipient: $address');
  return AddressType.cryptonote;
}

class _Monero extends Monero {
  _Monero() : super(CryptoCurrencyNetwork.main);
  @override
  bool validateAddress(String address) => _isValid(address);
  @override
  AddressType? getAddressType(String address) => _addressType(address);
}

class _Wownero extends Wownero {
  _Wownero() : super(CryptoCurrencyNetwork.main);
  @override
  bool validateAddress(String address) => _isValid(address);
  @override
  AddressType? getAddressType(String address) => _addressType(address);
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
    total: amount(balance),
    spendable: amount(balance),
    blockedTotal: amount(0),
    pendingSpendable: amount(0),
  );
}

class _Wallet extends Fake implements CryptonoteWallet {
  _Wallet(this.cryptoCurrency) : info = _Info(cryptoCurrency);
  @override
  final CryptonoteCurrency cryptoCurrency;
  @override
  final WalletInfo info;
  final prepared = <TxData>[];
  @override
  bool get supportsMultiRecipient => true;
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
    return txData.copyWith(fee: amount(10));
  }

  @override
  Future<void> cancelSend({required TxData txData}) async {}
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
  // Short balances keep the mobile balance row within 390 px in the test font.
  @override
  int maxDecimals(CryptoCurrency coin) => 2;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lookup {
  _Lookup(this.alias, this.isValidAddress);
  final String alias;
  final bool Function(String) isValidAddress;
  final result = Completer<CsOpenAliasRecipient>();
  int cancels = 0;
}

class _Harness {
  _Harness(this.desktop, {CryptonoteCurrency? coin, this.incognito = false})
    : coin = coin ?? _Monero();

  final bool desktop;
  final CryptonoteCurrency coin;
  final bool incognito;
  late final _Wallet wallet = _Wallet(coin);
  late final ProviderContainer container;
  final navigator = GlobalKey<NavigatorState>();
  final lookups = <_Lookup>[];

  late final service = OpenAliasService(
    externalCalls: () => !incognito,
    useTor: () => false,
    lookup: (alias, {required isValidAddress, required proxy}) {
      final lookup = _Lookup(alias, isValidAddress);
      lookups.add(lookup);
      return CsOpenAliasOperation(lookup.result.future, () {
        lookup.cancels++;
        if (!lookup.result.isCompleted) {
          lookup.result.completeError(
            CsOpenAliasCancelledException('cancelled', alias: alias),
          );
        }
      });
    },
  );

  Future<void> mount(
    WidgetTester tester, {
    SendViewAutoFillData? autofill,
  }) async {
    final size = desktop ? const Size(1200, 900) : const Size(390, 844);
    final previousPlatform = Util.layoutPlatform;
    final previousWidth = Util.screenWidth;
    final previousIsIpad = Util.isIpad;
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? 'macos' : 'android',
    );
    Util.isIpad = false;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    Util.screenWidth = size.width;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      Util.layoutPlatform = previousPlatform;
      Util.screenWidth = previousWidth;
      Util.isIpad = previousIsIpad;
    });
    expect(Util.isDesktop, desktop);
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    container = ProviderContainer(
      overrides: [
        themeProvider.overrideWithProvider(StateProvider((_) => theme)),
        pWallets.overrideWithValue(_Wallets(wallet)),
        pWalletInfo('wallet').overrideWithValue(wallet.info),
        pWalletCoin('wallet').overrideWithValue(coin),
        pWalletName('wallet').overrideWithValue('Test wallet'),
        pWalletBalance('wallet').overrideWithValue(wallet.info.cachedBalance),
        prefsChangeNotifierProvider.overrideWithValue(_Prefs()),
        coinIconProvider(coin)
            .overrideWithValue('test/sample_data/light/assets/dummy.svg'),
        coinImageSecondaryProvider(coin).overrideWithValue('dummy.svg'),
        pOpenAliasService.overrideWithValue(service),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      container.dispose();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navigator,
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
          builder: (_) => desktop
              ? Scaffold(
                  body: SingleChildScrollView(
                    child: DesktopSend(
                      walletId: 'wallet',
                      autoFillData: autofill,
                    ),
                  ),
                )
              : SendView(
                  walletId: 'wallet',
                  coin: coin,
                  autoFillData: autofill,
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Finder get field => find.byKey(const Key('sendViewAddressFieldKey'));
  Finder get button => find.text(desktop ? 'Preview send' : 'Preview');
  Finder get ok => find.text(desktop ? 'Ok' : 'OK');
  TxData confirmed(WidgetTester tester) => tester
      .widget<ConfirmTransactionView>(find.byType(ConfirmTransactionView))
      .txData;
  // The send screen is offstage under the mobile confirm screen.
  String text(WidgetTester tester) => tester
      .widget<TextField>(
        find.byKey(const Key('sendViewAddressFieldKey'), skipOffstage: false),
      )
      .controller!
      .text;
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

  Future<void> setAmount(
    WidgetTester tester, [
    int value = 1000000000000,
  ]) async {
    container.read(pSendAmount.notifier).state = amount(value);
    await tester.pumpAndSettle();
  }

  /// Taps Preview and stops while the lookup is pending; the progress dialog
  /// animates, so this never settles.
  Future<void> preview(WidgetTester tester) async {
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  void succeed() => lookups.single.result.complete(
    CsOpenAliasRecipient(
      domain: 'alice.example.com',
      address: literal,
      fields: const {'recipient_address': literal},
    ),
  );
}

void main() {
  for (final desktop in [false, true]) {
    final layout = desktop ? 'desktop 1200x900' : 'mobile 390x844';

    testWidgets('$layout an alias in the Monero field enables Preview', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.setAmount(tester);
      await h.enter(tester, 'not an alias');
      expect(find.text('Invalid address'), findsOneWidget);
      expect(h.enabled(tester), isFalse);
      await h.enter(tester, alias);
      expect(find.text('Invalid address'), findsNothing);
      expect(h.enabled(tester), isTrue);
      expect(h.lookups, isEmpty);
    });

    testWidgets('$layout an alias in the Wownero field stays invalid', (
      tester,
    ) async {
      final h = _Harness(desktop, coin: _Wownero());
      await h.mount(tester);
      await h.setAmount(tester);
      await h.enter(tester, alias);
      expect(find.text('Invalid address'), findsOneWidget);
      expect(h.enabled(tester), isFalse);
    });

    testWidgets('$layout Preview resolves the alias and confirms the address', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester);
      await h.preview(tester);
      final lookup = h.lookups.single;
      expect(lookup.alias, alias);
      expect(lookup.isValidAddress(literal), isTrue);
      expect(lookup.isValidAddress(alias), isFalse);
      expect(find.text('Cancel'), findsOneWidget);
      expect(h.wallet.prepared, isEmpty);

      h.succeed();
      await h.finish(tester);
      expect(h.wallet.prepared.single.recipients!.single.address, literal);
      expect(find.byType(ConfirmTransactionView), findsOneWidget);
      expect(h.confirmed(tester).recipients!.single.address, literal);
      expect(h.confirmed(tester).openAlias, 'alice@example.com');
      expect(find.text('OpenAlias'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text(literal), findsWidgets);
      expect(h.text(tester), literal);
    });

    testWidgets('$layout the lookup runs before the send-all confirmation', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester, balance);
      await h.preview(tester);
      expect(h.lookups, hasLength(1));
      expect(find.text('Confirm send all'), findsNothing);
      h.succeed();
      await tester.pumpAndSettle();
      expect(find.text('Confirm send all'), findsOneWidget);
      expect(h.wallet.prepared, isEmpty);
      expect(h.text(tester), literal);
    });

    testWidgets('$layout Cancel during the lookup cancels it', (tester) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester);
      await h.preview(tester);
      await tester.tap(find.text('Cancel'));
      await h.finish(tester);
      expect(h.lookups.single.cancels, 1);
      expect(h.wallet.prepared, isEmpty);
      expect(find.byType(ConfirmTransactionView), findsNothing);
      expect(find.text('Generating transaction'), findsNothing);
      expect(find.text(openAliasLookupFailedTitle), findsNothing);
      expect(h.text(tester), alias);
      expect(h.enabled(tester), isTrue);
    });

    testWidgets('$layout a lookup failure shows the OpenAlias error', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester, balance);
      await h.preview(tester);
      const error = CsOpenAliasNoRecordException(
        'no oa1:xmr record',
        alias: 'alice.example.com',
      );
      h.lookups.single.result.completeError(error);
      await h.finish(tester);
      expect(find.text('OpenAlias lookup failed'), findsOneWidget);
      expect(
        find.text(
          'No Monero OpenAlias record was found for alice.example.com.',
        ),
        findsOneWidget,
      );
      expect(find.text('Generating transaction'), findsNothing);
      expect(find.text('Confirm send all'), findsNothing);
      expect(find.text('Transaction failed'), findsNothing);
      expect(h.wallet.prepared, isEmpty);
      await tester.tap(h.ok);
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmTransactionView), findsNothing);
      expect(h.text(tester), alias);
    });

    testWidgets('$layout Incognito shows the reason and sends nothing', (
      tester,
    ) async {
      final h = _Harness(desktop, incognito: true);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester);
      expect(h.enabled(tester), isTrue);
      await h.preview(tester);
      await h.finish(tester);
      expect(find.text('OpenAlias lookup failed'), findsOneWidget);
      expect(find.text(h.service.unavailableReason()!), findsOneWidget);
      expect(h.lookups, isEmpty);
      expect(h.wallet.prepared, isEmpty);
    });

    for (final input in ['literal', 'contact']) {
      testWidgets('$layout a $input address never starts a lookup', (
        tester,
      ) async {
        final h = _Harness(desktop);
        await h.mount(
          tester,
          autofill: input == 'contact'
              ? SendViewAutoFillData(address: literal, contactLabel: alias)
              : null,
        );
        if (input == 'literal') await h.enter(tester, literal);
        await h.setAmount(tester);
        expect(h.enabled(tester), isTrue);
        await h.preview(tester);
        await h.finish(tester);
        expect(h.lookups, isEmpty);
        expect(h.wallet.prepared.single.recipients!.single.address, literal);
        expect(find.byType(ConfirmTransactionView), findsOneWidget);
        expect(h.confirmed(tester).openAlias, isNull);
        expect(find.text('OpenAlias'), findsNothing);
      });
    }

    testWidgets('$layout multiple recipients never start a lookup', (
      tester,
    ) async {
      final h = _Harness(desktop);
      await h.mount(tester);
      await h.enter(tester, alias);
      await h.setAmount(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomTextButton && widget.text == 'Add recipient',
        ),
      );
      await tester.pumpAndSettle();
      final forms = find.byType(Recipient);
      expect(forms, findsNWidgets(2));
      Finder inForms(Key key) =>
          find.descendant(of: forms, matching: find.byKey(key));
      final addresses = inForms(const Key('sendViewAddressFieldKey'));
      await tester.enterText(addresses.first, literal);
      await tester.enterText(addresses.last, 'second-recipient');
      await tester.enterText(
        inForms(const Key('amountInputFieldCryptoTextFieldKey')).last,
        '2',
      );
      await tester.pumpAndSettle();
      expect(h.enabled(tester), isTrue);
      await h.preview(tester);
      await h.finish(tester);
      expect(h.lookups, isEmpty);
      expect(h.wallet.prepared.single.recipients!.map((e) => e.address), [
        literal,
        'second-recipient',
      ]);
      expect(find.byType(ConfirmTransactionView), findsOneWidget);
      expect(h.confirmed(tester).openAlias, isNull);
    });
  }
}
