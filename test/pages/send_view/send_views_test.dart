import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/transaction_fee_selection_sheet.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/wallet/public_private_balance_state_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/widgets/custom_buttons/blue_text_button.dart';
import 'package:stackwallet/widgets/desktop/desktop_fee_dialog.dart';
import 'package:stackwallet/widgets/eth_fee_form.dart';
import 'package:stackwallet/widgets/fee_slider.dart';
import 'package:tuple/tuple.dart';

import '../../support/isar_test_utils.dart';
import 'support/fake_wallets.dart';
import 'support/send_view_cases.dart';
import 'support/send_view_harness.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp("send_views_");
    StackFileSystem.setDesktopOverrideDir(dir.path);
    addTearDown(() => dir.delete(recursive: true));
    await initializeTestIsar();
    await loadButtonFont();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(
    WidgetTester tester,
    SendViewCase view,
    String amount,
  ) async {
    await enterField(tester, view.cryptoAmountField, amount);
    // Leaving the field applies the amount at once.
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
  }

  Future<void> receive(
    WidgetTester tester,
    Wallet wallet,
    Balance balance,
  ) async {
    (wallet.info as TestWalletInfo).balance = balance;
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .refresh(pWalletBalance(wallet.walletId));
    await settle(tester);
  }

  Future<void> setSyncStatus(
    WidgetTester tester,
    FakeSyncDependentFeeWallet wallet,
    WalletSyncStatus status,
  ) async {
    wallet.isSynced = status == WalletSyncStatus.synced;
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        status,
        wallet.walletId,
        wallet.cryptoCurrency,
      ),
    );
    await settle(tester);
  }

  Finder inFeeChoice(Finder finder) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is TransactionFeeSelectionSheet || widget is DesktopFeeDialog,
    ),
    matching: finder,
  );

  Future<void> failHeldFeeRates(WidgetTester tester, FakeWallet fees) async {
    final held = fees.holdFeeRateFetches!;
    fees.holdFeeRateFetches = null;
    held.completeError(Exception("node down"));
    await settle(tester);
  }

  Future<RecordedRoutes> pumpCoinControl(WidgetTester tester) async {
    final routes = RecordedRoutes();
    await mobileCoin.pump(
      tester,
      balance: testBalance("1", 8),
      prefs: HarnessPrefs(enableCoinControl: true),
      onGenerateRoute: routes.generate,
    );
    await enterField(tester, mobileCoin.addressField, btcAddress);
    return routes;
  }

  final ethFeeViews = [
    (mobileCoin, "0.000042"),
    (desktopCoin, ""),
    (mobileEthToken, "0.00013"),
    (desktopEthToken, ""),
  ];

  group("the fee shown", () {
    for (final view in coinCases) {
      testWithoutAnimation("covers the OP_RETURN output of a public Firo send "
          "($view)", (tester) async {
        await view.pump(
          tester,
          wallet: FakeFiroWallet(),
          overrides: [
            publicPrivateBalanceStateProvider.overrideWithProvider(
              StateProvider((_) => BalanceType.public),
            ),
          ],
        );
        await enterField(
          tester,
          view.addressField,
          "firo:$firoExchangeAddress?amount=0.1&op_return=68656c6c6f",
        );
        await settle(tester);
        expect(find.textContaining("0.00001320"), findsOneWidget);

        await view.openFeeChoice(tester, "0.00001320");

        // Each rate's estimate plus its fee for the 16-vbyte OP_RETURN output.
        expect(find.textContaining("0.00001980"), findsOneWidget);
        expect(find.textContaining("0.00001320"), findsWidgets);
        expect(find.textContaining("0.00000660"), findsOneWidget);
      });

      testWithoutAnimation("follows the balance sent from ($view Firo)", (
        tester,
      ) async {
        await view.pump(tester, wallet: FakeFiroWallet());
        await enterAmount(tester, view, "0.1");
        expect(find.textContaining("0.00002000"), findsOneWidget);

        await sendFrom(tester, "Public balance");
        await settle(tester);

        expect(find.textContaining("0.00001000"), findsOneWidget);
        expect(find.textContaining("0.00002000"), findsNothing);
      });

      testWithoutAnimation("is calculated when reviewing ($view Xelis)", (
        tester,
      ) async {
        final wallet = FakeXelisWallet();
        await view.pump(tester, wallet: wallet);
        await enterAmount(tester, view, "0.12345678");

        await tester.tap(find.text("Calculated when reviewing"));
        await tester.pumpAndSettle();

        expect(find.text("Transaction fee"), findsOneWidget);
        expect(find.text("Calculated when reviewing"), findsOneWidget);
        expect(find.byType(TransactionFeeSelectionSheet), findsNothing);
        expect(find.text("Edit", findRichText: true), findsNothing);
        expect(wallet.feeRateFetches, 0);
        expect(wallet.feeEstimates, 0);
      });

      testWithoutAnimation(
        "is absent for a coin without fees ($view Epic Cash)",
        (tester) async {
          final wallet = FakeEpiccashWallet();
          await view.pump(tester, wallet: wallet);
          await enterField(tester, view.cryptoAmountField, "1");
          await settle(tester);

          expect(find.textContaining("Transaction fee"), findsNothing);
          expect(wallet.feeRateFetches, 0);
        },
      );

      testWithoutAnimation("is labelled as an estimate until Custom is picked "
          "($view)", (tester) async {
        await view.pump(tester);
        expect(find.text("Transaction fee (estimated)"), findsOneWidget);

        await view.openFeeChoice(tester, "0.00002000");
        await pick(tester, "Custom");

        expect(find.text("Transaction fee"), findsOneWidget);
      });

      testWithoutAnimation("is estimated for the whole balance with Send all "
          "($view)", (tester) async {
        final wallet = FakeBitcoinWallet();
        await view.pump(tester, wallet: wallet, balance: testBalance("1", 8));

        await tester.tap(find.text("Send all BTC", findRichText: true));
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);

        expect(
          wallet.feeEstimateAmounts.last,
          Amount.tryParseCanonicalAmount("1", fractionDigits: 8),
        );
      });

      testWithoutAnimation(
        "is estimated for the amount at the picked level ($view)",
        (tester) async {
          final wallet = FakeBitcoinWallet();
          await view.pump(tester, wallet: wallet);
          await view.openFeeChoice(tester, "0.00002000");
          await pick(tester, "Fast");

          await enterAmount(tester, view, "0.2");

          expect(
            wallet.feeEstimateAmounts.last,
            Amount.tryParseCanonicalAmount("0.2", fractionDigits: 8),
          );
          expect(find.textContaining("0.00003000"), findsOneWidget);
        },
      );

      testWithoutAnimation(
        "follows the funds the wallet can spend ($view Solana)",
        (tester) async {
          final wallet = FakeSolanaWallet();
          await view.pump(tester, wallet: wallet);
          await enterAmount(tester, view, "1");

          await receive(tester, wallet, testBalance("1", 9));

          expect(find.textContaining("0.000015000"), findsOneWidget);
        },
      );

      for (final (coin, newWallet, fee, balance)
          in <(String, FakeSyncDependentFeeWallet Function(), String, Balance)>[
            ("Monero", FakeMoneroWallet.new, "0.00002", testBalance("10", 12)),
            ("Wownero", FakeWowneroWallet.new, "0.0002", testBalance("10", 11)),
          ]) {
        testWithoutAnimation(
          "follows the wallet once it has synchronized ($view $coin)",
          (tester) async {
            final wallet = newWallet()..isSynced = false;
            await view.pump(tester, wallet: wallet, balance: balance);
            await enterAmount(tester, view, "1");
            expect(find.textContaining("Calculating"), findsOneWidget);

            await setSyncStatus(tester, wallet, WalletSyncStatus.synced);

            expect(find.textContaining(fee), findsOneWidget);
          },
        );
      }

      testWithoutAnimation(
        "stays while the synchronized wallet refreshes ($view Monero)",
        (tester) async {
          final wallet = FakeMoneroWallet();
          await view.pump(
            tester,
            wallet: wallet,
            balance: testBalance("10", 12),
          );
          await enterAmount(tester, view, "1");

          await setSyncStatus(tester, wallet, WalletSyncStatus.syncing);
          await enterAmount(tester, view, "1");

          expect(find.textContaining("0.00002"), findsOneWidget);
        },
      );

      testWithoutAnimation(
        "is estimated for the recipients' total ($view Monero)",
        (tester) async {
          final wallet = FakeMoneroWallet();
          await view.pump(tester, wallet: wallet);
          await enterField(
            tester,
            view.addressField,
            "monero:address0;address1?tx_amount=1;2",
          );
          await settle(tester);

          await tester.enterText(
            find.descendant(
              of: find.byType(Recipient).first,
              matching: find.byKey(view.cryptoAmountField),
            ),
            "5",
          );
          await settle(tester);

          expect(
            wallet.feeEstimateAmounts.last,
            Amount.tryParseCanonicalAmount("7", fractionDigits: 12),
          );
        },
      );
    }

    testWithoutAnimation("is the slow rate's fee (mobile Solana token)", (
      tester,
    ) async {
      await mobileSolToken.pump(tester, balance: testBalance("1", 9));
      await enterField(tester, mobileSolToken.cryptoAmountField, "1");
      await settle(tester);

      expect(find.text("Slow"), findsOneWidget);
      expect(find.text("~0.000010000 SOL"), findsOneWidget);
    });
  });

  group("the fee choice", () {
    for (final view in coinCases) {
      testWithoutAnimation("shows each level's confirmation time ($view)", (
        tester,
      ) async {
        await view.pump(tester);

        await view.openFeeChoice(tester, "0.00002000");

        expect(inFeeChoice(find.text("~10 minutes")), findsOneWidget);
        expect(inFeeChoice(find.text("~30 minutes")), findsOneWidget);
        expect(inFeeChoice(find.text("~1 hour")), findsOneWidget);
      });

      testWithoutAnimation(
        "shows the fees once the wallet has synchronized ($view Monero)",
        (tester) async {
          final wallet = FakeMoneroWallet()..isSynced = false;
          await view.pump(
            tester,
            wallet: wallet,
            balance: testBalance("10", 12),
          );
          await enterAmount(tester, view, "1");
          await view.openFeeChoice(tester, "Calculating");

          await setSyncStatus(tester, wallet, WalletSyncStatus.synced);

          expect(inFeeChoice(find.textContaining("0.00002")), findsOneWidget);
        },
      );

      testWithoutAnimation("leaves the form at the picked level and its fee "
          "($view)", (tester) async {
        final wallet = FakeBitcoinWallet();
        await view.pump(tester, wallet: wallet);
        await enterAmount(tester, view, "0.1");
        await view.openFeeChoice(tester, "0.00002000");
        final estimates = wallet.feeEstimates;

        await pick(tester, "Fast");

        expect(find.textContaining("Fast"), findsOneWidget);
        expect(find.textContaining("0.00003000"), findsOneWidget);
        expect(wallet.feeEstimates, estimates);
      });

      testWithoutAnimation("offers no custom rate for Solana ($view)", (
        tester,
      ) async {
        await view.pump(
          tester,
          wallet: FakeSolanaWallet(),
          balance: testBalance("1", 9),
        );
        await enterAmount(tester, view, "1");

        await view.openFeeChoice(tester, "0.000015000");

        expect(inFeeChoice(find.textContaining("0.000020000")), findsOneWidget);
        expect(find.text("Custom"), findsNothing);
      });

      testWithoutAnimation(
        "offers the edit fees for cryptonote coins ($view)",
        (tester) async {
          await view.pump(tester, wallet: FakeMoneroWallet());
          await enterAmount(tester, view, "1");

          await view.openFeeChoice(tester, "0.00002");

          expect(inFeeChoice(find.textContaining("0.00003")), findsOneWidget);
        },
      );

      testWithoutAnimation("is absent for Spark ($view Firo)", (tester) async {
        await view.pump(tester, wallet: FakeFiroWallet());
        await enterAmount(tester, view, "0.1");

        await tester.tap(find.textContaining("0.00002000").last);
        await tester.pumpAndSettle();

        expect(find.byType(TransactionFeeSelectionSheet), findsNothing);
        expect(find.text("Edit", findRichText: true), findsNothing);
      });
    }

    for (final (view, coin, wallet, fee, balance)
        in <(SendViewCase, String, Wallet Function(), String, Balance)>[
          (
            mobileCoin,
            "Stellar",
            FakeStellarWallet.new,
            "0.00001",
            testBalance("10", 7),
          ),
          (
            mobileCoin,
            "Cardano",
            FakeCardanoWallet.new,
            "0.17",
            testBalance("10", 6),
          ),
          (
            desktopCoin,
            "Cardano",
            FakeCardanoWallet.new,
            "0.17",
            testBalance("10", 6),
          ),
        ]) {
      testWithoutAnimation("is absent for $coin ($view)", (tester) async {
        await view.pump(tester, wallet: wallet(), balance: balance);
        await enterAmount(tester, view, "1");

        await tester.tap(find.textContaining(fee).last);
        await tester.pumpAndSettle();

        expect(find.byType(TransactionFeeSelectionSheet), findsNothing);
        expect(find.text("Edit", findRichText: true), findsNothing);
      });
    }

    for (final (view, fee) in ethFeeViews) {
      testWithoutAnimation("offers a custom Ethereum fee ($view)", (
        tester,
      ) async {
        await view.pump(tester, wallet: FakeEthereumWallet());
        await enterAmount(tester, view, "1");
        await view.openFeeChoice(tester, fee);

        await pick(tester, "Custom");

        expect(find.byType(EthFeeForm), findsOneWidget);
      });
    }

    testWithoutAnimation(
      "offers no custom rate once sent from the private balance "
      "(mobile Firo)",
      (tester) async {
        await mobileCoin.pump(tester, wallet: FakeFiroWallet());
        await sendFrom(tester, "Public balance");
        await settle(tester);
        await mobileCoin.openFeeChoice(tester, "0.00001000");
        await pick(tester, "Custom");

        await sendFrom(tester, "Private balance");

        expect(find.byType(FeeSlider), findsNothing);
      },
    );

    testWithoutAnimation("opens from an Edit click that ends the amount typing "
        "(desktop)", (tester) async {
      await desktopCoin.pump(tester);
      await enterField(tester, desktopCoin.cryptoAmountField, "0.01");
      final edit = find.ancestor(
        of: find.text("Edit", findRichText: true),
        matching: find.byType(CustomTextButton),
      );

      FocusManager.instance.primaryFocus?.unfocus();
      final click = await tester.startGesture(
        tester.getRect(edit).centerLeft + const Offset(4, 0),
      );
      await tester.pump();
      await click.up();
      await tester.pumpAndSettle();

      expect(find.byType(DesktopFeeDialog), findsOneWidget);
    });
  });

  group("the fee sent", () {
    for (final view in coinCases) {
      testWithoutAnimation("is the custom rate picked ($view)", (tester) async {
        final wallet = FakeBitcoinWallet();
        await view.pump(tester, wallet: wallet, balance: testBalance("1", 8));
        await enterField(tester, view.addressField, btcAddress);
        await enterField(tester, view.cryptoAmountField, "0.1");
        await settle(tester);
        await view.openFeeChoice(tester, "0.00002000");
        final rate = await setCustomRate(tester);
        await view.preview(tester);

        expect(rate, greaterThan(1));
        expect(wallet.prepared!.feeRateType, FeeRateType.custom);
        expect(wallet.prepared!.satsPerVByte, rate);
      });

      testWithoutAnimation(
        "starts the custom rate over once a level was picked "
        "($view)",
        (tester) async {
          final wallet = FakeBitcoinWallet();
          await view.pump(tester, wallet: wallet, balance: testBalance("1", 8));
          await enterField(tester, view.addressField, btcAddress);
          await enterAmount(tester, view, "0.1");
          await view.openFeeChoice(tester, "0.00002000");
          await setCustomRate(tester);
          await view.openFeeChoice(tester, "Custom");
          await pick(tester, "Fast");
          await view.openFeeChoice(tester, "0.00003000");

          await pick(tester, "Custom");
          final rate = sliderRate(tester);
          await view.preview(tester);

          expect(wallet.prepared!.satsPerVByte, rate);
        },
      );

      testWithoutAnimation(
        "starts the custom rate over once the private balance hid it "
        "($view Firo)",
        (tester) async {
          final wallet = FakeFiroWallet();
          await view.pump(tester, wallet: wallet, balance: testBalance("1", 8));
          await sendFrom(tester, "Public balance");
          await settle(tester);
          await view.openFeeChoice(tester, "0.00001000");
          await setCustomRate(tester);
          await sendFrom(tester, "Private balance");
          await sendFrom(tester, "Public balance");
          await enterField(tester, view.addressField, firoAddress);
          await enterAmount(tester, view, "0.1");

          final rate = sliderRate(tester);
          await view.preview(tester);

          expect(wallet.prepared!.satsPerVByte, rate);
        },
      );

      testWithoutAnimation(
        "starts at the Average level in a new send form ($view)",
        (tester) async {
          final wallet = FakeBitcoinWallet();
          await view.pump(tester, wallet: wallet, balance: testBalance("1", 8));
          await view.openFeeChoice(tester, "0.00002000");
          await pick(tester, "Fast");
          final navigator = Navigator.of(
            tester.element(find.byType(Scaffold).first),
          );
          unawaited(
            navigator.pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const SizedBox()),
            ),
          );
          await tester.pumpAndSettle();
          unawaited(
            navigator.pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(body: view.view(wallet)),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await enterField(tester, view.addressField, btcAddress);
          await enterAmount(tester, view, "0.1");
          await view.preview(tester);

          expect(wallet.prepared!.feeRateType, FeeRateType.average);
        },
      );
    }

    for (final (view, fee) in ethFeeViews) {
      Future<FakeWallet> pumpCustomEthFee(WidgetTester tester) async {
        final wallet = FakeEthereumWallet();
        await view.pump(tester, wallet: wallet, balance: testBalance("1", 18));
        await enterField(tester, view.addressField, testEthContract.address);
        await enterAmount(tester, view, "0.1");
        await view.openFeeChoice(tester, fee);
        await pick(tester, "Custom");
        await enterField(tester, const Key("ethMaxFeePerGasField"), "50");
        await enterField(
          tester,
          const Key("ethMaxPriorityFeePerGasField"),
          "2",
        );
        return view.feeEstimator(wallet);
      }

      testWithoutAnimation(
        "drops the custom Ethereum fee once a level is picked "
        "($view)",
        (tester) async {
          final sender = await pumpCustomEthFee(tester);
          await view.openFeeChoice(tester, "Custom");

          await pick(tester, "Fast");
          await view.preview(tester);

          expect(sender.prepared!.ethEIP1559Fee, isNull);
        },
      );

      testWithoutAnimation(
        "drops the custom Ethereum fee once another send form sets "
        "a level ($view)",
        (tester) async {
          final sender = await pumpCustomEthFee(tester);

          ProviderScope.containerOf(tester.element(find.byType(EthFeeForm)))
                  .read(pFeeRateType.notifier)
                  .state =
              FeeRateType.average;
          await tester.pumpAndSettle();
          await view.preview(tester);

          expect(sender.prepared!.ethEIP1559Fee, isNull);
        },
      );
    }
  });

  group("the fee sent to coin control", () {
    /// The amount coin control is opened with.
    Future<Object?> selectCoins(
      WidgetTester tester,
      RecordedRoutes routes,
    ) async {
      await tester.tap(find.text("Select coins", findRichText: true));
      await settle(tester);
      return (routes.arguments.single! as Tuple4).item3;
    }

    testWithoutAnimation("is the picked level's fee (mobile)", (tester) async {
      final routes = await pumpCoinControl(tester);
      await enterAmount(tester, mobileCoin, "0.1");
      await mobileCoin.openFeeChoice(tester, "0.00002000");
      await pick(tester, "Fast");

      expect(
        await selectCoins(tester, routes),
        Amount.tryParseCanonicalAmount("0.10003", fractionDigits: 8),
      );
    });

    testWithoutAnimation("is none with a custom fee (mobile)", (tester) async {
      final routes = await pumpCoinControl(tester);
      await enterAmount(tester, mobileCoin, "0.1");
      await mobileCoin.openFeeChoice(tester, "0.00002000");
      await pick(tester, "Custom");

      expect(
        await selectCoins(tester, routes),
        Amount.tryParseCanonicalAmount("0.1", fractionDigits: 8),
      );
    });
  });

  group("a failed fee", () {
    for (final (view, newWallet) in <(SendViewCase, Wallet Function())>[
      (mobileCoin, FakeBitcoinWallet.new),
      (desktopCoin, FakeBitcoinWallet.new),
      (mobileEthToken, FakeEthereumWallet.new),
      (desktopEthToken, FakeEthereumWallet.new),
    ]) {
      testWithoutAnimation("shows as calculating ($view)", (tester) async {
        final wallet = newWallet();
        final fees = view.feeEstimator(wallet)
          ..feeError = Exception("node down");
        await view.pump(tester, wallet: wallet);
        await enterAmount(tester, view, "1");
        final estimates = fees.feeEstimates;

        await enterField(tester, view.addressField, "a");
        await enterField(tester, view.addressField, "ab");

        expect(estimates, greaterThan(0));
        expect(fees.feeEstimates, estimates);
        expect(find.textContaining("Calculating"), findsOneWidget);
      });

      testWithoutAnimation("is estimated again once typing pauses ($view)", (
        tester,
      ) async {
        final wallet = newWallet();
        final fees = view.feeEstimator(wallet)..feeError = Exception("down");
        await view.pump(tester, wallet: wallet);
        await enterAmount(tester, view, "1");
        final estimates = fees.feeEstimates;

        await enterField(tester, view.cryptoAmountField, "2");
        await settle(tester);

        expect(fees.feeEstimates, estimates + 1);
      });

      testWithoutAnimation(
        "is estimated again when the amount field loses focus ($view)",
        (tester) async {
          final wallet = newWallet();
          final fees = view.feeEstimator(wallet)..feeError = Exception("down");
          await view.pump(tester, wallet: wallet);
          await enterAmount(tester, view, "1");
          final estimates = fees.feeEstimates;

          await enterAmount(tester, view, "1");

          expect(fees.feeEstimates, estimates + 1);
        },
      );
    }

    testWithoutAnimation("is fetched again by a balance switch (mobile Firo)", (
      tester,
    ) async {
      final wallet = FakeFiroWallet()..holdFeeRateFetches = Completer<void>();
      await mobileCoin.pump(tester, wallet: wallet);
      await enterAmount(tester, mobileCoin, "0.1");
      await sendFrom(tester, "Public balance");
      await sendFrom(tester, "Private balance");
      await failHeldFeeRates(tester, wallet);

      await sendFrom(tester, "Public balance");

      expect(find.textContaining("0.00001000"), findsOneWidget);
      expect(wallet.feeRateFetches, 2);
    });

    testWithoutAnimation(
      "is fetched again by a balance switch (desktop Firo)",
      (tester) async {
        final wallet = FakeFiroWallet()..failingFeeRateFetches = 2;
        await desktopCoin.pump(tester, wallet: wallet);
        await sendFrom(tester, "Public balance");
        await sendFrom(tester, "Private balance");

        await sendFrom(tester, "Public balance");

        expect(find.textContaining("0.00001000"), findsOneWidget);
        expect(wallet.feeRateFetches, 3);
      },
    );

    testWithoutAnimation(
      "falls back to the minimum fee (mobile Solana token)",
      (tester) async {
        final wallet = FakeSolanaWallet()..feeError = Exception("node down");
        await mobileSolToken.pump(tester, wallet: wallet);

        await enterField(tester, mobileSolToken.cryptoAmountField, "1");
        await settle(tester);

        expect(wallet.feeEstimates, greaterThan(0));
        expect(find.textContaining("0.000005"), findsOneWidget);
      },
    );

    testWithoutAnimation("is logged (mobile Solana token)", (tester) async {
      final wallet = FakeSolanaWallet()..feeError = Exception("node down");

      final logged = await logs(() async {
        await mobileSolToken.pump(
          tester,
          wallet: wallet,
          balance: testBalance("1", 9),
        );
        await enterAmount(tester, mobileSolToken, "1");
      });

      expect(
        logged,
        contains(contains("Failed to calculate Solana token fees")),
      );
    });

    testWithoutAnimation(
      "is fetched again once typing pauses (mobile Solana token)",
      (tester) async {
        final wallet = FakeSolanaWallet()..failingFeeRateFetches = 1;
        await mobileSolToken.pump(
          tester,
          wallet: wallet,
          balance: testBalance("1", 9),
        );

        await enterAmount(tester, mobileSolToken, "1");

        expect(wallet.feeRateFetches, 2);
        expect(find.text("~0.000010000 SOL"), findsOneWidget);
      },
    );
  });

  group("fee rates", () {
    for (final view in coinCases) {
      testWithoutAnimation("are fetched once for every amount ($view)", (
        tester,
      ) async {
        final wallet = FakeBitcoinWallet();
        await view.pump(tester, wallet: wallet);
        await enterAmount(tester, view, "0.1");

        await enterAmount(tester, view, "0.2");

        expect(wallet.feeRateFetches, 1);
      });

      testWithoutAnimation(
        "are fetched fresh each time the fee choice opens ($view)",
        (tester) async {
          final wallet = FakeBitcoinWallet();
          await view.pump(tester, wallet: wallet);
          await enterAmount(tester, view, "0.1");
          await view.openFeeChoice(tester, "0.00002000");
          await pick(tester, "Average");
          final fetches = wallet.feeRateFetches;
          wallet.feeRateFactor = 2;

          await view.openFeeChoice(tester, "0.00002000");

          expect(wallet.feeRateFetches, fetches + 1);
          expect(
            inFeeChoice(find.textContaining("0.00004000")),
            findsOneWidget,
          );
        },
      );
    }
  });

  group("fee estimates", () {
    for (final view in coinCases) {
      testWithoutAnimation("follow the amount typed last ($view)", (
        tester,
      ) async {
        final wallet = FakeBitcoinWallet();
        await view.pump(tester, wallet: wallet);
        final estimates = wallet.feeEstimateAmounts.length;

        await tester.enterText(find.byKey(view.cryptoAmountField), "0.1");
        await tester.pump(const Duration(milliseconds: 100));
        await tester.enterText(find.byKey(view.cryptoAmountField), "0.2");
        await settle(tester);

        expect(wallet.feeEstimateAmounts.sublist(estimates), [
          Amount.tryParseCanonicalAmount("0.2", fractionDigits: 8),
        ]);
      });

      testWithoutAnimation(
        "follow the recipients' total typed last ($view Monero)",
        (tester) async {
          final wallet = FakeMoneroWallet();
          await view.pump(tester, wallet: wallet);
          await enterField(
            tester,
            view.addressField,
            "monero:address0;address1?tx_amount=1;2",
          );
          await settle(tester);
          final estimates = wallet.feeEstimateAmounts.length;
          final amountField = find.descendant(
            of: find.byType(Recipient).first,
            matching: find.byKey(view.cryptoAmountField),
          );

          await tester.enterText(amountField, "5");
          await tester.pump(const Duration(milliseconds: 100));
          await tester.enterText(amountField, "6");
          await settle(tester);

          expect(wallet.feeEstimateAmounts.sublist(estimates), [
            Amount.tryParseCanonicalAmount("8", fractionDigits: 12),
          ]);
        },
      );
    }
  });

  group("the send view", () {
    for (final (coin, wallet) in <(String, Wallet Function())>[
      ("Epic Cash", FakeEpiccashWallet.new),
      ("Xelis", FakeXelisWallet.new),
    ]) {
      testWithoutAnimation("rebuilds nothing for an amount without a fee "
          "(mobile $coin)", (tester) async {
        await mobileCoin.pump(tester, wallet: wallet());
        await tester.enterText(find.byKey(mobileCoin.cryptoAmountField), "1");
        await tester.pump();

        await tester.binding.delayed(const Duration(seconds: 1));

        expect(tester.element(find.byType(SendView)).dirty, isFalse);
      });
    }
  });
}
