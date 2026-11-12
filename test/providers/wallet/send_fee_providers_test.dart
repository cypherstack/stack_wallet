import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/ui/fee_rate_type_state_provider.dart';
import 'package:stackwallet/providers/wallet/send_fee_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../pages/send_view/support/fake_wallets.dart';
import '../../pages/send_view/support/send_view_harness.dart';
import '../../wallets/support/xelis_test_fakes.dart';

Amount _btc(int satoshis) =>
    Amount(rawValue: BigInt.from(satoshis), fractionDigits: 8);

Amount _units(Wallet wallet, int raw) => Amount(
  rawValue: BigInt.from(raw),
  fractionDigits: wallet.cryptoCurrency.fractionDigits,
);

final _balance = StateProvider<Balance?>((_) => null);

final _tertiaryBalance = StateProvider<Balance?>((_) => null);

class _FeeForm extends ConsumerStatefulWidget {
  const _FeeForm({required this.walletId});

  final String walletId;

  @override
  ConsumerState<_FeeForm> createState() => _FeeFormState();
}

/// A send form showing its fee in raw units, as the send views show theirs.
class _FeeFormState extends ConsumerState<_FeeForm> with SendFeeForm<_FeeForm> {
  @override
  void initState() {
    super.initState();
    fees = SendFeeRates(ref.read, walletId: widget.walletId, isToken: false);
  }

  @override
  Widget build(BuildContext context) {
    final estimate = watchFee();
    return FutureBuilder<Amount>(
      // The send views show "Calculating" until each new fee answers.
      key: ObjectKey(estimate),
      future: estimate,
      builder: (_, fee) => Text(
        "${fee.data?.raw ?? "Calculating"}",
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

void main() {
  (SendFeeRates, ProviderContainer) feesOf(Wallet wallet) {
    final container = ProviderContainer(
      overrides: [
        pWallets.overrideWithValue(ConfirmationWallets(wallet)),
        pWalletBalance.overrideWithProvider(
          (_) => Provider(
            (ref) => ref.watch(_balance) ?? wallet.info.cachedBalance,
          ),
        ),
        pWalletBalanceTertiary.overrideWithProvider(
          (_) => Provider(
            (ref) =>
                ref.watch(_tertiaryBalance) ??
                wallet.info.cachedBalanceTertiary,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return (
      SendFeeRates(container.read, walletId: wallet.walletId, isToken: false),
      container,
    );
  }

  Future<_FeeFormState> pumpForm(WidgetTester tester, Wallet wallet) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletBalance(wallet.walletId)
              .overrideWithValue(wallet.info.cachedBalance),
          pWalletBalanceTertiary(wallet.walletId)
              .overrideWithValue(wallet.info.cachedBalanceTertiary),
        ],
        child: _FeeForm(walletId: wallet.walletId),
      ),
    );
    return tester.state(find.byType(_FeeForm));
  }

  void pickLevel(_FeeFormState form, FeeRateType level) =>
      ProviderScope.containerOf(form.context)
              .read(pFeeRateType.notifier)
              .state =
          level;

  // A fee choice closed at once.
  void choose(_FeeFormState form) => unawaited(form.chooseFee((_, _) async {}));

  void chooseLevel(_FeeFormState form, FeeRateType level) =>
      unawaited(form.chooseFee((_, _) async => pickLevel(form, level)));

  FeeObject testFeesTimes({
    int fast = 1,
    int medium = 1,
    int slow = 1,
    int blocks = 1,
  }) => FeeObject(
    numberOfBlocksFast: testFees.numberOfBlocksFast * blocks,
    numberOfBlocksAverage: testFees.numberOfBlocksAverage * blocks,
    numberOfBlocksSlow: testFees.numberOfBlocksSlow * blocks,
    fast: testFees.fast * BigInt.from(fast),
    medium: testFees.medium * BigInt.from(medium),
    slow: testFees.slow * BigInt.from(slow),
  );

  Future<bool> showsInNextFrames(WidgetTester tester, Finder finder) async {
    var isShown = false;
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      isShown |= finder.evaluate().isNotEmpty;
    }
    return isShown;
  }

  group("the fee shown", () {
    test("follows the private balance (Spark)", () async {
      final wallet = FakeFiroWallet();
      final (fees, container) = feesOf(wallet);
      Future<Amount> fee() => fees.estimate(
        container.read,
        FeeRateType.average,
        amount: _btc(100000),
      );
      await fee();

      container.read(_tertiaryBalance.notifier).state = testBalance("1", 8);
      await fee();

      expect(wallet.feeEstimates, 2);
    });

    testWithoutAnimation("stays on screen through a retry", (tester) async {
      final form = await pumpForm(tester, FakeBitcoinWallet());
      form.setFeeAmount(_btc(10000000));
      await tester.pumpAndSettle();

      form.retryFee();

      expect(
        await showsInNextFrames(tester, find.text("Calculating")),
        isFalse,
      );
    });
  });

  group("the fee choice", () {
    test("gives each level the confirmation time of its own block count", () {
      final coin = Bitcoin(CryptoCurrencyNetwork.main);

      expect(sendFeeTime(coin, testFees, FeeRateType.fast), "~10 minutes");
      expect(sendFeeTime(coin, testFees, FeeRateType.average), "~30 minutes");
      expect(sendFeeTime(coin, testFees, FeeRateType.slow), "~1 hour");
    });

    testWithoutAnimation("shows its fresh fee once closed", (tester) async {
      final wallet = FakeBitcoinWallet();
      final form = await pumpForm(tester, wallet);
      form.setFeeAmount(_btc(10000000));
      await tester.pumpAndSettle();
      wallet.feeRateFactor = 2;

      choose(form);
      await tester.pumpAndSettle();

      expect(find.text("4000"), findsOneWidget);
    });

    testWithoutAnimation("offers the fees of the amount being typed", (
      tester,
    ) async {
      final form = await pumpForm(tester, FakeBitcoinWallet());
      final amounts = <Amount?>[];
      form.followFeeAmount(_btc(10000000));

      unawaited(form.chooseFee((_, amount) async => amounts.add(amount)));
      await tester.pumpAndSettle();

      expect(amounts, [_btc(10000000)]);
    });

    testWithoutAnimation("keeps the shown fee when its fresh rates fail", (
      tester,
    ) async {
      final wallet = FakeBitcoinWallet();
      final form = await pumpForm(tester, wallet);
      form.setFeeAmount(_btc(10000000));
      await tester.pumpAndSettle();
      wallet.failingFeeRateFetches = wallet.feeRateFetches + 1;

      choose(form);
      await tester.pumpAndSettle();

      expect(find.text("2000"), findsOneWidget);
    });

    testWithoutAnimation(
      "keeps the shown fee once Custom was picked while its fresh rates "
      "failed",
      (tester) async {
        final wallet = FakeBitcoinWallet();
        final form = await pumpForm(tester, wallet);
        form.setFeeAmount(_btc(10000000));
        await tester.pumpAndSettle();
        wallet.failingFeeRateFetches = wallet.feeRateFetches + 2;
        unawaited(
          form.chooseFee((fees, _) async {
            fees.rates.ignore();
            pickLevel(form, FeeRateType.custom);
          }),
        );
        await tester.pumpAndSettle();

        chooseLevel(form, FeeRateType.average);
        await tester.pumpAndSettle();

        expect(find.text("2000"), findsOneWidget);
      },
    );

    testWithoutAnimation("shows a picked level's fee at once", (tester) async {
      final form = await pumpForm(tester, FakeBitcoinWallet());
      form.setFeeAmount(_btc(10000000));
      await tester.pumpAndSettle();

      chooseLevel(form, FeeRateType.fast);

      expect(
        await showsInNextFrames(tester, find.text("Calculating")),
        isFalse,
      );
    });

    testWithoutAnimation(
      "leaves the rates of an amount typed while its fee was estimated",
      (tester) async {
        final wallet = FakeBitcoinWallet();
        final form = await pumpForm(tester, wallet);
        form.setFeeAmount(_btc(10000000));
        await tester.pumpAndSettle();
        final rates = Completer<void>();
        wallet
          ..feeRateFactor = 2
          ..holdFeeRateFetches = rates;
        choose(form);
        await tester.pumpAndSettle();
        form.setFeeAmount(_btc(20000000));
        await tester.pumpAndSettle();

        rates.complete();
        await tester.pumpAndSettle();

        expect(find.text("2000"), findsOneWidget);
      },
    );

    testWithoutAnimation("wins over an earlier one still estimated", (
      tester,
    ) async {
      final wallet = FakeBitcoinWallet();
      final form = await pumpForm(tester, wallet);
      form.setFeeAmount(_btc(10000000));
      await tester.pumpAndSettle();
      final rates = Completer<void>();
      wallet
        ..feeRateFactor = 2
        ..holdFeeRateFetches = rates;
      choose(form);
      await tester.pumpAndSettle();
      wallet
        ..feeRateFactor = 3
        ..holdFeeRateFetches = null;
      choose(form);
      await tester.pumpAndSettle();

      rates.complete();
      await tester.pumpAndSettle();

      expect(find.text("6000"), findsOneWidget);
    });

    for (final (level, rates, fee) in [
      (FeeRateType.fast, testFeesTimes(fast: 2), "6000"),
      (FeeRateType.average, testFeesTimes(medium: 2), "4000"),
      (FeeRateType.slow, testFeesTimes(slow: 2), "2000"),
    ]) {
      testWithoutAnimation("shows the new fee once closed when only the "
          "${level.prettyName} rate changed", (tester) async {
        final wallet = FakeBitcoinWallet();
        final form = await pumpForm(tester, wallet);
        form.setFeeAmount(_btc(10000000));
        await tester.pumpAndSettle();
        chooseLevel(form, level);
        await tester.pumpAndSettle();
        wallet.feeRates = rates;

        choose(form);
        await tester.pumpAndSettle();

        expect(find.text(fee), findsOneWidget);
      });
    }

    testWithoutAnimation(
      "keeps the shown fee at the same rates with new confirmation "
      "times",
      (tester) async {
        final wallet = FakeBitcoinWallet();
        final form = await pumpForm(tester, wallet);
        form.setFeeAmount(_btc(10000000));
        await tester.pumpAndSettle();
        wallet.feeRates = testFeesTimes(blocks: 2);

        choose(form);

        expect(
          await showsInNextFrames(tester, find.text("Calculating")),
          isFalse,
        );
      },
    );
  });

  group("a failed fee", () {
    test("is logged once when its rates fail", () async {
      final wallet = FakeBitcoinWallet()..failingFeeRateFetches = 1;
      final (fees, container) = feesOf(wallet);

      final logged = await logs(
        () => Future.wait([
          fees.estimate(container.read, FeeRateType.fast),
          fees.estimate(container.read, FeeRateType.average),
          fees.estimate(container.read, FeeRateType.slow),
        ]).then<void>((_) {}, onError: (Object _) {}),
      );

      expect("Failed to calculate".allMatches(logged.join()), hasLength(1));
    });

    testWithoutAnimation("shows once its rates answer, even a minute later", (
      tester,
    ) async {
      final rates = Completer<void>();
      final form = await pumpForm(
        tester,
        FakeBitcoinWallet()..holdFeeRateFetches = rates,
      );
      form.setFeeAmount(_btc(10000000));
      await tester.pump(const Duration(minutes: 1));

      rates.complete();
      await tester.pumpAndSettle();

      expect(find.text("2000"), findsOneWidget);
    });
  });

  group("fee estimates", () {
    test("reuse the fee of an unchanged rate once refreshed", () async {
      final wallet = FakeBitcoinWallet();
      final (fees, container) = feesOf(wallet);
      await fees.estimate(container.read, FeeRateType.average);

      await fees.refreshed().estimate(container.read, FeeRateType.average);

      expect(wallet.feeEstimates, 1);
    });

    test("reuse the Spark fee at another level once refreshed", () async {
      final wallet = FakeFiroWallet();
      final (fees, container) = feesOf(wallet);
      await fees.estimate(
        container.read,
        FeeRateType.average,
        amount: _btc(100000),
      );

      await fees.refreshed().estimate(
        container.read,
        FeeRateType.fast,
        amount: _btc(100000),
      );

      expect(wallet.feeEstimates, 1);
    });

    test("are asked by the fee choice once the wallet has synchronized "
        "(Monero)", () async {
      final wallet = FakeMoneroWallet()..isSynced = false;
      final (fees, container) = feesOf(wallet);
      container.read(_balance.notifier).state = testBalance("10", 12);
      unawaited(
        fees.estimate(
          container.read,
          FeeRateType.average,
          amount: _units(wallet, 1),
        ),
      );
      await pumpEventQueue();
      wallet.isSynced = true;

      final fee = await fees.refreshed().estimate(
        container.read,
        FeeRateType.average,
        amount: _units(wallet, 1),
      );

      expect(fee, _units(wallet, 20000000));
    });

    for (final (coin, newWallet) in <(String, Wallet Function())>[
      ("Ethereum", FakeEthereumWallet.new),
      ("Solana", FakeSolanaWallet.new),
      ("Stellar", FakeStellarWallet.new),
      ("Cardano", FakeCardanoWallet.new),
    ]) {
      test("are asked once for every $coin amount", () async {
        final wallet = newWallet();
        final (fees, container) = feesOf(wallet);
        await fees.estimate(
          container.read,
          FeeRateType.average,
          amount: _units(wallet, 1),
        );

        await fees.estimate(
          container.read,
          FeeRateType.average,
          amount: _units(wallet, 2),
        );

        expect((wallet as FakeWallet).feeEstimates, 1);
      });
    }

    test("are asked again only once funds arrive when the fee ignores the "
        "amount (Cardano)", () async {
      final wallet = FakeCardanoWallet();
      final (fees, container) = feesOf(wallet);
      await fees.estimate(container.read, FeeRateType.average);
      container.read(_balance.notifier).state = testBalance("10", 6);
      await fees.estimate(container.read, FeeRateType.average);

      container.read(_balance.notifier).state = testBalance("20", 6);
      await fees.estimate(container.read, FeeRateType.average);

      expect(wallet.feeEstimates, 2);
    });
  });
}
