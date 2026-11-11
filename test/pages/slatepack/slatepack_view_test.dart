import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

/// Epic Cash wallet whose inspection waits for [gate] and then reports a
/// finalized slate, which the import flow answers with a plain message.
class _SlowWallet extends EpiccashWallet {
  _SlowWallet() : super(CryptoCurrencyNetwork.main);

  final gate = Completer<void>();
  int inspections = 0;

  @override
  Future<SlateInspection> inspectSlatepack(String armored) async {
    inspections++;
    await gate.future;
    return const SlateInspection(state: SlateState.s3, slateId: "test-slate");
  }
}

void main() {
  testWidgets("Continue starts one import however often it is pressed", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The phone layout closes the keyboard and waits a moment before it
    // starts the import, which is when a second press can get in.
    final previousWidth = Util.screenWidth;
    Util.screenWidth = 400;
    addTearDown(() => Util.screenWidth = previousWidth);
    final previousThemes = StackFileSystem.themesDir;
    StackFileSystem.themesDir = Directory("test/sample_data").absolute;
    addTearDown(() => StackFileSystem.themesDir = previousThemes);
    final wallet = _SlowWallet();
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: const Scaffold(body: SlatepackView(walletId: "wallet-1")),
        ),
      ),
    );
    await tester.pumpAndSettle();

    PrimaryButton button() =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton));

    expect(button().enabled, isFalse);
    await tester.enterText(find.byType(TextField), "{}");
    await tester.pump();
    expect(button().enabled, isTrue);

    // The second press lands before a frame has disabled the button, the
    // third while the keyboard is still closing.
    await tester.tap(find.text("Continue"));
    await tester.tap(find.text("Continue"), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 20));
    expect(button().enabled, isFalse);
    await tester.tap(find.text("Continue"), warnIfMissed: false);

    // Keyboard delay, loading overlay delay, then the inspection.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(wallet.inspections, 1);

    wallet.gate.complete();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text("Already finalized"), findsOneWidget);
    await tester.tap(find.text("OK"));
    await tester.pump(const Duration(milliseconds: 400));

    expect(wallet.inspections, 1);
    // Nothing was acted on, so the text stays and Continue works again.
    expect(find.text("{}"), findsOneWidget);
    expect(button().enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
