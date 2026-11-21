import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/pages/slatepack/slatepack_import_flow.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/slatepack_text.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

/// Epic Cash wallet whose inspection is canned, so run() can be driven
/// without a native wallet.
class _InspectOnlyWallet extends EpiccashWallet {
  _InspectOnlyWallet(
    this.state, {
    this.invoices = false,
    this.localIsSend,
    this.localIsCancelled = false,
    this.localGate,
    this.receiveGate,
    this.receiveError,
    this.senderAddress,
    this.finalizeResult,
  }) : super(CryptoCurrencyNetwork.main);

  /// When set, receiving waits for it and then succeeds, or throws
  /// [receiveError] if that is set.
  final Completer<void>? receiveGate;
  final Exception? receiveError;
  final String? senderAddress;
  final FinalizeResult? finalizeResult;

  @override
  String get walletId => "test-wallet";

  final SlateState state;
  final bool invoices;

  @override
  bool get supportsInvoices => invoices;

  /// Direction of the wallet's own transaction for the slate. Null when the
  /// wallet has none.
  final bool? localIsSend;
  final bool localIsCancelled;

  /// When set, the local-history lookup waits for it.
  final Completer<void>? localGate;
  int receiveCalls = 0;
  int finalizeCalls = 0;
  int refreshCalls = 0;
  SlateInspection? actionInspection;

  /// What the flow handed to the wallet.
  final seen = <String>[];

  @override
  Future<SlateInspection> inspectSlatepack(String armored) async {
    seen.add(armored);
    return SlateInspection(
      state: state,
      slateId: "test-slate",
      slateJson: '{"id":"test-slate"}',
      amount: Amount(rawValue: BigInt.from(100), fractionDigits: 8),
      fee: Amount(rawValue: BigInt.one, fractionDigits: 8),
      senderAddress: senderAddress,
    );
  }

  @override
  Future<({Amount amount, Amount fee, bool isSend, bool isCancelled})?>
  localTxForSlate(String slateId) async {
    await localGate?.future;
    return localIsSend == null
        ? null
        : (
            amount: Amount(rawValue: BigInt.from(100), fractionDigits: 8),
            fee: Amount(rawValue: BigInt.one, fractionDigits: 8),
            isSend: localIsSend!,
            isCancelled: localIsCancelled,
          );
  }

  @override
  Future<SlatepackResult> receiveSlatepack(
    String slatepack, {
    required SlateInspection inspection,
  }) async {
    receiveCalls++;
    actionInspection = inspection;
    if (receiveGate == null) {
      return SlatepackResult(success: false, error: "not in tests");
    }
    await receiveGate!.future;
    if (receiveError != null) throw receiveError!;
    return SlatepackResult(
      success: true,
      slatepack: '{"response": true}',
      slateId: "test-slate",
      state: SlateState.s2,
    );
  }

  @override
  Future<void> refresh({bool doScan = true}) async {
    refreshCalls++;
  }

  @override
  Future<FinalizeResult> finalizeSlatepack(
    String slatepack, {
    required SlateInspection inspection,
  }) async {
    actionInspection = inspection;
    finalizeCalls++;
    return finalizeResult ??
        FinalizeResult(success: false, error: "not in tests");
  }
}

class _SynchronousMwcWallet extends MimblewimblecoinWallet {
  _SynchronousMwcWallet({
    required this.onInspect,
    this.state = SlateState.s3,
    this.localGate,
  }) : super(CryptoCurrencyNetwork.main);

  final VoidCallback onInspect;
  final SlateState state;
  final Completer<void>? localGate;

  @override
  String get walletId => "test-wallet";

  @override
  Future<SlateInspection> inspectSlatepack(String armored) {
    onInspect();
    return Future.value(SlateInspection(state: state, slateId: 'mwc-slate'));
  }

  @override
  Future<({Amount amount, Amount fee, bool isSend, bool isCancelled})?>
  localTxForSlate(String slateId) async {
    await localGate?.future;
    return null;
  }
}

void main() {
  group("routeFor", () {
    test("standard send states", () {
      for (final invoices in [true, false]) {
        expect(
          SlatepackImportFlow.routeFor(
            SlateState.s1,
            supportsInvoices: invoices,
          ),
          SlatepackRoute.receive,
        );
        expect(
          SlatepackImportFlow.routeFor(
            SlateState.s2,
            supportsInvoices: invoices,
          ),
          SlatepackRoute.finalizeSend,
        );
        expect(
          SlatepackImportFlow.routeFor(
            SlateState.s3,
            supportsInvoices: invoices,
          ),
          SlatepackRoute.alreadyFinalized,
        );
        expect(
          SlatepackImportFlow.routeFor(
            SlateState.i3,
            supportsInvoices: invoices,
          ),
          SlatepackRoute.alreadyFinalized,
        );
        expect(
          SlatepackImportFlow.routeFor(
            SlateState.unknown,
            supportsInvoices: invoices,
          ),
          SlatepackRoute.unsupported,
        );
      }
    });

    test("invoice states depend on supportsInvoices", () {
      expect(
        SlatepackImportFlow.routeFor(SlateState.i1, supportsInvoices: true),
        SlatepackRoute.payInvoice,
      );
      expect(
        SlatepackImportFlow.routeFor(SlateState.i2, supportsInvoices: true),
        SlatepackRoute.finalizeInvoice,
      );
      expect(
        SlatepackImportFlow.routeFor(SlateState.i1, supportsInvoices: false),
        SlatepackRoute.invoicesUnsupported,
      );
      expect(
        SlatepackImportFlow.routeFor(SlateState.i2, supportsInvoices: false),
        SlatepackRoute.invoicesUnsupported,
      );
    });
  });

  test("SlateState.fromCode", () {
    expect(SlateState.fromCode("S1"), SlateState.s1);
    expect(SlateState.fromCode("i2"), SlateState.i2);
    expect(SlateState.fromCode(" S3 "), SlateState.s3);
    expect(SlateState.fromCode("X9"), SlateState.unknown);
    expect(SlateState.fromCode(null), SlateState.unknown);
  });

  group("normalize", () {
    const armored =
        "BEGINSLATEPACK. 4H1qx1wHe668tFW yC2gfL8PPd8kSgv. "
        "ENDSLATEPACK.";

    test("trims whitespace", () {
      expect(SlatepackImportFlow.normalize("  \n$armored\r\n "), armored);
      expect(SlatepackImportFlow.normalize(armored), armored);
    });

    test("drops text around the armored frame", () {
      expect(
        SlatepackImportFlow.normalize(
          "Here is the slatepack:\n\n$armored\n\nSend it back soon.",
        ),
        armored,
      );
      expect(SlatepackImportFlow.normalize("> $armored <"), armored);
    });

    test("keeps line breaks inside the frame", () {
      const wrapped =
          "BEGINSLATEPACK. 4H1qx1wHe668tFW\nyC2gfL8PPd8kSgv. ENDSLATEPACK.";
      expect(SlatepackImportFlow.normalize("Hi\n$wrapped\nBye"), wrapped);
    });

    test("accepts the binary markers and a missing final period", () {
      const binary = "BEGINSLATE_BIN. 4H1qx1wHe668tFW. ENDSLATE_BIN.";
      expect(SlatepackImportFlow.normalize("x $binary y"), binary);
      expect(
        SlatepackImportFlow.normalize(
          "BEGINSLATEPACK. 4H1qx1wHe668tFW. ENDSLATEPACK",
        ),
        "BEGINSLATEPACK. 4H1qx1wHe668tFW. ENDSLATEPACK",
      );
    });

    test("shares the same armored-frame recognition as the wallets", () {
      expect(SlatepackText.isArmored(armored), isTrue);
      expect(SlatepackText.isArmored("\n$armored\n"), isTrue);
      expect(SlatepackText.isArmored("prefix $armored"), isFalse);
      expect(SlatepackText.isArmored('{"id":"abc"}'), isFalse);
    });

    test("takes the first of two slatepacks", () {
      expect(SlatepackImportFlow.normalize("$armored\n$armored"), armored);
    });

    test("leaves JSON slates alone apart from trimming", () {
      const json = '{"id": "abc", "note": "BEGINSLATEPACK. x. ENDSLATEPACK."}';
      expect(SlatepackImportFlow.normalize(" $json\n"), json);
    });

    test("leaves other text alone apart from trimming", () {
      expect(
        SlatepackImportFlow.normalize(" not a slatepack "),
        "not a slatepack",
      );
      expect(
        SlatepackImportFlow.normalize("BEGINSLATEPACK. cut off"),
        "BEGINSLATEPACK. cut off",
      );
      expect(SlatepackImportFlow.normalize("  "), "");
    });
  });

  group("run", () {
    Future<bool?> runFlow(
      WidgetTester tester,
      SlatepackInterface wallet, {
      String text = "{}",
      ValueNotifier<bool>? shown,
      void Function(bool)? onDone,
    }) async {
      bool? outcome;
      shown ??= ValueNotifier(true);
      final coin = wallet.cryptoCurrency;
      // The loading overlay reads its indicator from the theme.
      final previousThemes = StackFileSystem.themesDir;
      StackFileSystem.themesDir = Directory("test/sample_data").absolute;
      addTearDown(() => StackFileSystem.themesDir = previousThemes);
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pWallets.overrideWithValue(ConfirmationWallets(wallet)),
            pWalletBalance(wallet.walletId)
                .overrideWithValue(Balance.zeroFor(currency: coin)),
            themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
            pAmountFormatter(coin).overrideWithValue(
              AmountFormatter(
                unit: AmountUnit.normal,
                locale: "en_US",
                coin: coin,
                maxDecimals: coin.fractionDigits,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [StackColors.fromStackColorTheme(theme)],
            ),
            home: Scaffold(
              body: ValueListenableBuilder(
                valueListenable: shown,
                builder: (context, isShown, _) => !isShown
                    ? const SizedBox()
                    : Builder(
                        builder: (context) => TextButton(
                          onPressed: () async {
                            outcome = await SlatepackImportFlow.run(
                              context: context,
                              wallet: wallet,
                              text: text,
                            );
                            onDone?.call(outcome!);
                          },
                          child: const Text("go"),
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text("go"));
      // Loading overlay delay, then the inspection.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      return outcome;
    }

    Future<void> closeDialog(WidgetTester tester) async {
      await tester.tap(find.text("OK"));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('MWC inspection starts after the loading route is visible', (
      tester,
    ) async {
      double? routeOpacity;
      final wallet = _SynchronousMwcWallet(
        onInspect: () {
          final overlay = tester.element(find.byType(CustomLoadingOverlay));
          routeOpacity = ModalRoute.of(overlay)!.animation!.value;
        },
      );

      await runFlow(tester, wallet);

      expect(routeOpacity, 1);
      expect(find.text('Already finalized'), findsOneWidget);
      await closeDialog(tester);
    });

    testWidgets('MWC response with no local send does not show zero values', (
      tester,
    ) async {
      final wallet = _SynchronousMwcWallet(
        state: SlateState.s2,
        onInspect: () {},
      );

      await runFlow(tester, wallet);

      expect(find.text('Finalize slatepack'), findsOneWidget);
      expect(find.text('Encrypted'), findsOneWidget);
      expect(
        find.textContaining('amount and fee are unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('No matching send was found'), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsNothing);
      expect(find.textContaining('0.000000000 MWC'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets("finalized slate shows a message", (tester) async {
      final wallet = _InspectOnlyWallet(SlateState.s3);
      await runFlow(tester, wallet);
      expect(find.text("Already finalized"), findsOneWidget);
      await closeDialog(tester);
      expect(wallet.receiveCalls + wallet.finalizeCalls, 0);
    });

    testWidgets("unknown slate is unsupported", (tester) async {
      final wallet = _InspectOnlyWallet(SlateState.unknown);
      await runFlow(tester, wallet);
      expect(find.text("Unsupported slate"), findsOneWidget);
      await closeDialog(tester);
    });

    testWidgets("invoice without invoice support", (tester) async {
      final wallet = _InspectOnlyWallet(SlateState.i1);
      await runFlow(tester, wallet);
      expect(find.text("Invoices not supported"), findsOneWidget);
      await closeDialog(tester);
    });

    testWidgets("response to a send this wallet did not start", (tester) async {
      final wallet = _InspectOnlyWallet(SlateState.s2);
      await runFlow(tester, wallet);
      expect(find.text("Finalize slate"), findsOneWidget);
      expect(find.textContaining("No matching send was found"), findsOneWidget);
      expect(find.textContaining("could not be checked"), findsNothing);
      expect(find.textContaining('other party'), findsOneWidget);
      expect(find.textContaining('with the sender'), findsNothing);
      final warning = find.byKey(const Key("slatepackHistoryWarning"));
      expect(warning, findsOneWidget);
      expect(tester.widget(warning), isA<RoundedContainer>());
      final warningContainer = tester.widget<RoundedContainer>(warning);
      final warningColors = Theme.of(tester.element(warning))
          .extension<StackColors>()!;
      expect(warningContainer.color, warningColors.warningBackground);
      expect(warningContainer.borderColor, isNull);
      expect(
        find.descendant(of: warning, matching: find.byType(Icon)),
        findsNothing,
      );
      final warningText = tester.widget<Text>(
        find.textContaining("No matching send was found"),
      );
      expect(warningText.style?.color, warningColors.warningForeground);
      expect(find.text("0.00000100 EPIC"), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text("Cancel"));
      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(wallet.finalizeCalls, 0);
    });

    testWidgets("this wallet cannot receive its own initial slate", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.s1, localIsSend: true);

      await runFlow(tester, wallet);

      expect(find.text("Cannot receive this slate"), findsOneWidget);
      expect(find.textContaining("This wallet created"), findsOneWidget);
      expect(find.text("Receive"), findsNothing);
      expect(wallet.receiveCalls, 0);
      await closeDialog(tester);
    });

    testWidgets('a stalled local-history lookup falls back to the summary', (
      tester,
    ) async {
      final wallet = _SynchronousMwcWallet(
        state: SlateState.s2,
        onInspect: () {},
        localGate: Completer<void>(),
      );

      await runFlow(tester, wallet);
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Finalize slatepack'), findsOneWidget);
      expect(find.byKey(const Key('slatepackHistoryWarning')), findsOneWidget);
      expect(
        find.textContaining(
          "history could not be checked because the wallet "
          "is busy",
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('amount and fee are unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('No matching send was found'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('a stalled lookup with slate values says they are unchecked', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s2,
        localGate: Completer<void>(),
      );

      await runFlow(tester, wallet);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Finalize slate'), findsOneWidget);
      expect(find.byKey(const Key('slatepackHistoryWarning')), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsOneWidget);
      expect(
        find.textContaining('come from the imported slate'),
        findsOneWidget,
      );
      expect(find.textContaining('No matching send was found'), findsNothing);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(wallet.finalizeCalls, 0);
    });

    testWidgets('a slow receive lookup still offers the summary', (
      tester,
    ) async {
      final gate = Completer<void>();
      final wallet = _InspectOnlyWallet(SlateState.s1, localGate: gate);

      await runFlow(tester, wallet);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);
      expect(find.text('Could not check wallet history'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Receive slate'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
      expect(find.textContaining('busy'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(wallet.receiveCalls, 0);
    });

    testWidgets('a receive lookup that never finishes is refused', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s1,
        localGate: Completer<void>(),
      );

      await runFlow(tester, wallet);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);
      expect(find.text('Could not check wallet history'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Could not check wallet history'), findsOneWidget);
      expect(find.textContaining('The wallet is busy'), findsOneWidget);
      expect(find.text('Receive'), findsNothing);
      await closeDialog(tester);
      expect(wallet.receiveCalls, 0);
    });

    testWidgets('a slate already received is refused', (tester) async {
      final wallet = _InspectOnlyWallet(SlateState.s1, localIsSend: false);

      await runFlow(tester, wallet);

      expect(find.text('Cannot receive this slate'), findsOneWidget);
      expect(
        find.textContaining("already in this wallet's history"),
        findsOneWidget,
      );
      expect(find.text('Receive'), findsNothing);
      await closeDialog(tester);
      expect(wallet.receiveCalls, 0);
    });

    testWidgets('a slate whose receive was cancelled is refused consistently', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s1,
        localIsSend: false,
        localIsCancelled: true,
      );

      await runFlow(tester, wallet);

      expect(find.text('Cannot receive this slate'), findsOneWidget);
      expect(find.textContaining('receive was cancelled'), findsOneWidget);
      expect(find.text('Receive'), findsNothing);
      await closeDialog(tester);
      expect(wallet.receiveCalls, 0);
    });

    testWidgets("this wallet's cancelled send cannot be received", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s1,
        localIsSend: true,
        localIsCancelled: true,
      );

      await runFlow(tester, wallet);

      expect(find.text('Cannot receive this slate'), findsOneWidget);
      expect(
        find.textContaining('This transaction was cancelled'),
        findsOneWidget,
      );
      expect(find.textContaining('This wallet created'), findsNothing);
      expect(find.text('Receive'), findsNothing);
      await closeDialog(tester);
      expect(wallet.receiveCalls, 0);
    });

    testWidgets('a hexadecimal slatepack sender is labelled as a key', (
      tester,
    ) async {
      final senderKey = List.filled(32, 'ab').join();
      final wallet = _InspectOnlyWallet(
        SlateState.s1,
        senderAddress: senderKey,
      );

      await runFlow(tester, wallet);

      expect(find.text('Sender key'), findsOneWidget);
      expect(find.text('From'), findsNothing);
      expect(find.text(senderKey), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Epic summaries omit an inapplicable encryption row', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.s1);

      await runFlow(tester, wallet);

      expect(find.text('Receive slate'), findsOneWidget);
      expect(find.text('Encrypted'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets("response to a transaction this wallet received", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.s2, localIsSend: false);
      await runFlow(tester, wallet);
      expect(find.text("Cannot finalize this slate"), findsOneWidget);
      expect(
        find.textContaining("a transaction this wallet received"),
        findsOneWidget,
      );
      expect(find.text("Finalize"), findsNothing);
      await closeDialog(tester);
      expect(wallet.finalizeCalls, 0);
    });

    testWidgets("response to this wallet's cancelled send is refused", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s2,
        localIsSend: true,
        localIsCancelled: true,
      );
      await runFlow(tester, wallet);
      expect(find.text("Cannot finalize this slate"), findsOneWidget);
      expect(find.textContaining("was cancelled"), findsOneWidget);
      expect(find.text("Finalize"), findsNothing);
      await closeDialog(tester);
      expect(wallet.finalizeCalls, 0);
    });

    testWidgets("response to this wallet's own send can be finalized", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.s2, localIsSend: true);
      await runFlow(tester, wallet);
      expect(find.text("Cannot finalize this slate"), findsNothing);
      expect(find.text("Finalize slate"), findsOneWidget);
      expect(find.byKey(const Key("slatepackHistoryWarning")), findsNothing);
      expect(find.text("0.00000100 EPIC"), findsOneWidget);
      await tester.tap(find.text("Finalize"));
      // Loading overlay delay, then the canned failure and its dialog.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(wallet.finalizeCalls, 1);
      expect(wallet.refreshCalls, 0);
      await closeDialog(tester);
    });

    testWidgets('a finalized transaction reports a rejected broadcast', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s2,
        localIsSend: true,
        finalizeResult: FinalizeResult(
          success: true,
          slateId: 'test-slate',
          posted: false,
        ),
      );
      await runFlow(tester, wallet);
      await tester.tap(find.text('Finalize'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Finalized, not broadcast'), findsOneWidget);
      expect(wallet.refreshCalls, 0);
      expect(find.textContaining('node did not accept it'), findsOneWidget);
      expect(find.textContaining('transaction details'), findsNothing);
      await closeDialog(tester);
    });

    testWidgets('an older plugin does not claim an unknown broadcast result', (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(
        SlateState.s2,
        localIsSend: true,
        finalizeResult: FinalizeResult(
          success: true,
          slateId: 'test-slate',
          posted: null,
        ),
      );
      await runFlow(tester, wallet);
      await tester.tap(find.text('Finalize'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Transaction finalized'), findsOneWidget);
      expect(
        find.textContaining('broadcast result is unavailable'),
        findsOneWidget,
      );
      expect(find.textContaining('finalized and broadcast'), findsNothing);
      expect(find.textContaining('node did not accept'), findsNothing);
      await closeDialog(tester);
    });

    testWidgets("the wallet only sees the slatepack itself", (tester) async {
      const armored = "BEGINSLATEPACK. 4H1qx1wHe668tFW. ENDSLATEPACK.";
      final wallet = _InspectOnlyWallet(SlateState.s2, localIsSend: true);
      await runFlow(tester, wallet, text: "Here you go:\n$armored\nThanks\n");
      await tester.tap(find.text("Finalize"));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(wallet.seen, [armored]);
      expect(wallet.actionInspection?.slateJson, '{"id":"test-slate"}');
      await closeDialog(tester);
    });

    testWidgets("the response is shown even if the importing screen closed "
        "while the slate was received", (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gate = Completer<void>();
      final wallet = _InspectOnlyWallet(SlateState.s1, receiveGate: gate);
      final shown = ValueNotifier(true);
      addTearDown(shown.dispose);
      bool? done;
      await runFlow(tester, wallet, shown: shown, onDone: (v) => done = v);
      expect(find.text("Receive slate"), findsOneWidget);
      await tester.tap(find.text("Receive"));
      // Summary closes, loading overlay delay, then the wallet is asked.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(wallet.receiveCalls, 1);
      expect(find.byType(SlatepackDialog), findsNothing);
      expect(find.byType(CustomLoadingOverlay), findsOneWidget);

      shown.value = false;
      await tester.pump();
      expect(find.text("go"), findsNothing);

      gate.complete();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SlatepackDialog), findsOneWidget);
      expect(find.text('{"response": true}'), findsOneWidget);
      expect(find.text('Not encrypted'), findsNothing);

      await tester.tap(find.text("Done"));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(done, isTrue);
      // Nothing is left over the app once the response is closed.
      expect(
        find.byType(CustomLoadingOverlay, skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(ModalBarrier), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("an error is shown even if the importing screen closed "
        "while the slate was received", (tester) async {
      final gate = Completer<void>();
      final wallet = _InspectOnlyWallet(
        SlateState.s1,
        receiveGate: gate,
        receiveError: Exception("the slate was refused"),
      );
      final shown = ValueNotifier(true);
      addTearDown(shown.dispose);
      bool? done;
      await runFlow(tester, wallet, shown: shown, onDone: (v) => done = v);
      await tester.tap(find.text("Receive"));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(wallet.receiveCalls, 1);

      shown.value = false;
      await tester.pump();
      gate.complete();
      for (
        var i = 0;
        i < 10 && find.text("the slate was refused").evaluate().isEmpty;
        i++
      ) {
        await tester.pump();
      }
      expect(find.text("the slate was refused"), findsOneWidget);
      expect(
        find.byType(CustomLoadingOverlay, skipOffstage: false),
        findsOneWidget,
        reason: 'the outgoing and incoming dialog fades should overlap',
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(CustomLoadingOverlay, skipOffstage: false),
        findsNothing,
      );

      await closeDialog(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(done, isFalse);
      expect(tester.takeException(), isNull);
    });
    testWidgets("invoice with invoice support opens the payment review", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.i1, invoices: true);
      await runFlow(tester, wallet);
      expect(find.text("Pay invoice"), findsWidgets);
    });
  });
}
