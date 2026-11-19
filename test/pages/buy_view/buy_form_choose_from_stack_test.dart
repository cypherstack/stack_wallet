import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/buy_view/buy_form.dart';
import 'package:stackwallet/pages/exchange_view/choose_address_from_stack_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/enums/derive_path_type_enum.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/bitcoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../sample_data/theme_json.dart';
import '../send_view/support/send_view_harness.dart';

const _walletId = 'buy-form-test';

Address _address(String value, AddressType type) => Address(
  walletId: _walletId,
  value: value,
  publicKey: [],
  derivationIndex: 0,
  derivationPath: null,
  type: type,
  subType: AddressSubType.receiving,
);

class _Wallet extends BitcoinWallet {
  _Wallet({required this.viewOnly, required this.current, this.fallback})
    : super(CryptoCurrencyNetwork.main);

  final bool viewOnly;
  final Address current;
  final Address? fallback;
  int fallbackCalls = 0;

  @override
  String get walletId => _walletId;

  @override
  bool get isViewOnly => viewOnly;

  @override
  Future<Address?> getCurrentReceivingAddress() async => current;

  @override
  Future<Address> getOrCreateCurrentReceivingAddress({
    required DerivePathType derivePathType,
  }) async {
    fallbackCalls++;
    return fallback!;
  }
}

class _FakeWallets extends Fake implements Wallets {
  _FakeWallets(this.wallet);

  final Wallet wallet;

  @override
  Wallet getWallet(String walletId) => wallet;
}

/// Stands in for the wallet chooser: returns the wallet the way it does.
class _Chooser extends StatelessWidget {
  const _Chooser();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => Navigator.of(context)
          .pop((walletId: _walletId, address: 'unused', walletName: 'Wallet')),
      child: const Text('pick'),
    ),
  );
}

class _PopCounter extends NavigatorObserver {
  int pops = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => pops++;
}

void main() {
  late platform.Platform originalPlatform;

  setUpAll(loadButtonFont);
  setUp(() => originalPlatform = Util.layoutPlatform);
  tearDown(() => Util.layoutPlatform = originalPlatform);

  final field = find.byKey(const Key('buyViewReceiveAddressFieldKey'));
  const homeKey = Key('home');

  /// Pumps the Buy form where each layout really hosts it: directly under the
  /// app's navigator on mobile, inside a nested navigator on desktop.
  Future<({_PopCounter root, _PopCounter nested})> pumpForm(
    WidgetTester tester,
    _Wallet wallet,
  ) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final root = _PopCounter();
    final nested = _PopCounter();
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    Route<dynamic> route(RouteSettings settings) => MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => settings.name == ChooseAddressFromStackView.routeName
          ? const _Chooser()
          : const Scaffold(body: BuyForm()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          pWallets.overrideWithValue(_FakeWallets(wallet)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          navigatorObservers: [root],
          onGenerateRoute: Util.isDesktop ? null : route,
          home: Util.isDesktop
              ? Scaffold(
                  key: homeKey,
                  body: Navigator(onGenerateRoute: route, observers: [nested]),
                )
              : const Scaffold(key: homeKey, body: BuyForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (root: root, nested: nested);
  }

  Future<void> chooseWallet(WidgetTester tester) async {
    await tester.tap(find.text('Choose from Stack', findRichText: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;

  // The form and the dialog only ask whether the layout is desktop, so one
  // OS of each kind covers both.
  for (final (layout, os) in [('mobile', 'android'), ('desktop', 'macos')]) {
    group('$layout layout', () {
      setUp(
        () => Util.layoutPlatform = platform.FakePlatform(operatingSystem: os),
      );

      testWidgets('a view only Taproot wallet shows a dialog', (tester) async {
        final wallet = _Wallet(
          viewOnly: true,
          current: _address('bc1ptaproot', AddressType.p2tr),
        );
        final pops = await pumpForm(tester, wallet);
        await tester.enterText(field, 'previous');
        await tester.pumpAndSettle();

        await chooseWallet(tester);

        expect(find.text('Wallet not supported'), findsOneWidget);
        expect(
          find.textContaining('a view only Taproot wallet has no other'),
          findsOneWidget,
        );
        // The chooser is closed and the form is still there under the dialog.
        expect(find.byType(_Chooser), findsNothing);
        expect(find.byType(BuyForm), findsOneWidget);
        expect(wallet.fallbackCalls, 0);
        final rootPops = pops.root.pops;
        final nestedPops = pops.nested.pops;

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Closing the dialog pops that one route and nothing else.
        expect(find.text('Wallet not supported'), findsNothing);
        expect(pops.root.pops, rootPops + 1);
        expect(pops.nested.pops, nestedPops);
        expect(find.byKey(homeKey), findsOneWidget);
        expect(find.byType(BuyForm), findsOneWidget);
        expect(fieldText(tester), 'previous');
        expect(tester.takeException(), isNull);

        // The form still works afterwards.
        await chooseWallet(tester);
        expect(find.text('Wallet not supported'), findsOneWidget);
      });

      testWidgets('a Taproot wallet with a seed gets its BIP84 address', (
        tester,
      ) async {
        final wallet = _Wallet(
          viewOnly: false,
          current: _address('bc1ptaproot', AddressType.p2tr),
          fallback: _address('bc1qfallback', AddressType.p2wpkh),
        );
        await pumpForm(tester, wallet);

        await chooseWallet(tester);

        expect(find.text('Wallet not supported'), findsNothing);
        expect(fieldText(tester), 'bc1qfallback');
        expect(wallet.fallbackCalls, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a view only wallet on another path is used as is', (
        tester,
      ) async {
        final wallet = _Wallet(
          viewOnly: true,
          current: _address('bc1qcurrent', AddressType.p2wpkh),
        );
        await pumpForm(tester, wallet);

        await chooseWallet(tester);

        expect(find.text('Wallet not supported'), findsNothing);
        expect(fieldText(tester), 'bc1qcurrent');
        expect(wallet.fallbackCalls, 0);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
