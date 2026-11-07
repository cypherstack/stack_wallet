import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_import_flow.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';

import '../../sample_data/theme_json.dart';

/// Epic Cash wallet whose inspection is canned, so run() can be driven
/// without a native wallet.
class _InspectOnlyWallet extends EpiccashWallet {
  _InspectOnlyWallet(this.state, {this.invoices = false})
    : super(CryptoCurrencyNetwork.main);

  final SlateState state;
  final bool invoices;
  int receiveCalls = 0;
  int finalizeCalls = 0;

  @override
  bool get supportsInvoices => invoices;

  @override
  Future<SlateInspection> inspectSlatepack(String armored) async =>
      SlateInspection(state: state, slateId: "test-slate");

  @override
  Future<SlatepackResult> receiveSlatepack(String slatepack) async {
    receiveCalls++;
    return SlatepackResult(success: false, error: "not in tests");
  }

  @override
  Future<FinalizeResult> finalizeSlatepack(String slatepack) async {
    finalizeCalls++;
    return FinalizeResult(success: false, error: "not in tests");
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

  group("run", () {
    Future<bool?> runFlow(
      WidgetTester tester,
      _InspectOnlyWallet wallet,
    ) async {
      bool? outcome;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(json: lightThemeJsonMap),
              ),
            ],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  outcome = await SlatepackImportFlow.run(
                    context: context,
                    wallet: wallet,
                    text: "{}",
                  );
                },
                child: const Text("go"),
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

    testWidgets("invoice with invoice support is a placeholder", (
      tester,
    ) async {
      final wallet = _InspectOnlyWallet(SlateState.i2, invoices: true);
      await runFlow(tester, wallet);
      expect(find.text("Invoice payment"), findsOneWidget);
      await closeDialog(tester);
    });
  });
}
