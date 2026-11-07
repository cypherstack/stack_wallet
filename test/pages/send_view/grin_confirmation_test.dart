import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/grin_fakes.dart';
import '../../wallets/support/xelis_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  TxData direct(String address) => TxData(
    recipients: [
      TxRecipient(
        address: address,
        amount: Amount(rawValue: BigInt.from(1000000000), fractionDigits: 9),
        isChange: false,
        addressType: AddressType.mimbleWimble,
      ),
    ],
    fee: Amount(rawValue: BigInt.from(23500000), fractionDigits: 9),
    otherData: slatepackMethodOtherData(SlatepackMethod.http),
  );

  Future<void> pumpConfirm(WidgetTester tester, TxData txData) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;

    final wallet = h.wallet;
    final coin = wallet.cryptoCurrency;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletCoin(h.walletId).overrideWithValue(coin),
          prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          pAmountFormatter(coin).overrideWithValue(
            AmountFormatter(
              unit: AmountUnit.normal,
              locale: 'en_US',
              coin: coin,
              maxDecimals: 9,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: ConfirmTransactionView(
              txData: txData,
              walletId: h.walletId,
              onSuccess: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  bool sendEnabled(WidgetTester tester) => tester
      .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Send'))
      .enabled;

  testWidgets('clearnet https with Tor off needs the IP warning', (
    tester,
  ) async {
    await pumpConfirm(tester, direct('https://payee.example'));
    expect(find.byKey(const Key('slatepackClearnetAck')), findsOneWidget);
    expect(find.byKey(const Key('slatepackPlaintextAck')), findsNothing);
    expect(sendEnabled(tester), isFalse);
    await tester.ensureVisible(find.byKey(const Key('slatepackClearnetAck')));
    await tester.tap(find.byKey(const Key('slatepackClearnetAck')));
    await tester.pumpAndSettle();
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('plain http with Tor off needs both warnings', (tester) async {
    await pumpConfirm(tester, direct('http://payee.example'));
    await tester.ensureVisible(find.byKey(const Key('slatepackClearnetAck')));
    await tester.tap(find.byKey(const Key('slatepackClearnetAck')));
    await tester.pumpAndSettle();
    expect(sendEnabled(tester), isFalse);
    await tester.ensureVisible(find.byKey(const Key('slatepackPlaintextAck')));
    await tester.tap(find.byKey(const Key('slatepackPlaintextAck')));
    await tester.pumpAndSettle();
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('plain http over Tor still warns', (tester) async {
    h.prefs.tor = true;
    h.tor.current = TorConnectionStatus.connected;
    await pumpConfirm(tester, direct('http://payee.example'));
    expect(find.byKey(const Key('slatepackClearnetAck')), findsNothing);
    expect(find.byKey(const Key('slatepackPlaintextAck')), findsOneWidget);
    expect(sendEnabled(tester), isFalse);
  });

  testWidgets('a grin1 target without Tor is blocked', (tester) async {
    await pumpConfirm(tester, direct('grin1payee'));
    expect(find.textContaining('needs Tor'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(sendEnabled(tester), isFalse);
  });

  testWidgets('Tor wanted but down blocks everything', (tester) async {
    h.prefs.tor = true;
    h.prefs.killSwitch = false;
    h.tor.current = TorConnectionStatus.disconnected;
    await pumpConfirm(tester, direct('https://payee.example'));
    expect(find.textContaining('Tor is not connected'), findsOneWidget);
    expect(sendEnabled(tester), isFalse);
  });

  testWidgets('a slatepack send has no transport warnings', (tester) async {
    await pumpConfirm(
      tester,
      direct('').copyWith(
        otherData: slatepackMethodOtherData(SlatepackMethod.slatepack),
      ),
    );
    expect(find.byType(Checkbox), findsNothing);
    expect(sendEnabled(tester), isTrue);
  });
}
