import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_spend_planner.dart';

void main() {
  test('splits a payment into one plan per Spark coin', () async {
    final plans = await planSingleInputSparkSpends(
      coinValues: [BigInt.from(7000), BigInt.from(5000)],
      recipients: [
        SparkSpendRecipientRequest(
          type: SparkSpendRecipientType.private,
          index: 0,
          amount: BigInt.from(9000),
        ),
      ],
      estimateFee:
          ({
            required privateRecipientCount,
            required transparentRecipientCount,
          }) async => BigInt.from(1000),
      maxTransparentAmount: BigInt.from(50000),
      maxPrivateRecipients: 14,
      maxTransactions: 50,
      maxTransactionWeight: 1000000,
    );

    expect(plans.map((e) => e.coinIndex), [0, 1]);
    expect(plans.map((e) => e.recipients.single.amount), [
      BigInt.from(6000),
      BigInt.from(3000),
    ]);
    expect(plans.map((e) => e.fee), [BigInt.from(1000), BigInt.from(1000)]);
  });

  test('applies the transparent limit to each transaction', () async {
    final plans = await planSingleInputSparkSpends(
      coinValues: [BigInt.from(7000), BigInt.from(7000)],
      recipients: [
        SparkSpendRecipientRequest(
          type: SparkSpendRecipientType.transparent,
          index: 0,
          amount: BigInt.from(6000),
        ),
      ],
      estimateFee:
          ({
            required privateRecipientCount,
            required transparentRecipientCount,
          }) async => BigInt.from(1000),
      maxTransparentAmount: BigInt.from(4000),
      maxPrivateRecipients: 14,
      maxTransactions: 50,
      maxTransactionWeight: 1000000,
    );

    expect(plans.map((e) => e.recipients.single.amount), [
      BigInt.from(4000),
      BigInt.from(2000),
    ]);
  });
}
