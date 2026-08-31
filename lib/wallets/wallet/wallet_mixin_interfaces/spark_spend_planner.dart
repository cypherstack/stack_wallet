typedef SparkSpendFeeEstimator =
    Future<BigInt> Function({
      required int privateRecipientCount,
      required int transparentRecipientCount,
    });

const _sparkBaseSize = 924;
const _sparkInputSize = 1803;
const _sparkPrivateOutputSize = 322;
const _transparentOutputSize = 34;
const _witnessScaleFactor = 4;

enum SparkSpendRecipientType { transparent, private }

final class SparkSpendRecipientRequest {
  final SparkSpendRecipientType type;
  final int index;
  final BigInt amount;

  const SparkSpendRecipientRequest({
    required this.type,
    required this.index,
    required this.amount,
  });
}

final class SparkSpendRecipientFragment {
  final SparkSpendRecipientType type;
  final int index;
  final BigInt amount;

  const SparkSpendRecipientFragment({
    required this.type,
    required this.index,
    required this.amount,
  });
}

final class SingleInputSparkSpendPlan {
  final int coinIndex;
  final BigInt fee;
  final List<SparkSpendRecipientFragment> recipients;

  const SingleInputSparkSpendPlan({
    required this.coinIndex,
    required this.fee,
    required this.recipients,
  });
}

final class _RemainingSparkRecipient {
  final SparkSpendRecipientRequest recipient;
  BigInt amount;

  _RemainingSparkRecipient(this.recipient) : amount = recipient.amount;
}

Future<List<SingleInputSparkSpendPlan>> planSingleInputSparkSpends({
  required List<BigInt> coinValues,
  required List<SparkSpendRecipientRequest> recipients,
  required SparkSpendFeeEstimator estimateFee,
  required BigInt maxTransparentAmount,
  required int maxPrivateRecipients,
  required int maxTransactions,
  required int maxTransactionWeight,
}) async {
  if (recipients.isEmpty) {
    throw Exception("No recipients provided.");
  }
  if (recipients.any((e) => e.amount <= BigInt.zero)) {
    throw Exception("Recipient has invalid amount.");
  }

  final remaining = recipients.map(_RemainingSparkRecipient.new).toList();
  final plans = <SingleInputSparkSpendPlan>[];
  int recipientIndex = 0;

  for (
    int coinIndex = 0;
    coinIndex < coinValues.length && recipientIndex < remaining.length;
    coinIndex++
  ) {
    final coinValue = coinValues[coinIndex];
    final fragments = <SparkSpendRecipientFragment>[];
    BigInt amount = BigInt.zero;
    BigInt fee = BigInt.zero;
    BigInt transparentAmount = BigInt.zero;
    int privateRecipientCount = 0;
    int transparentRecipientCount = 0;

    while (recipientIndex < remaining.length) {
      final current = remaining[recipientIndex];
      final isPrivate =
          current.recipient.type == SparkSpendRecipientType.private;
      final nextPrivateCount = privateRecipientCount + (isPrivate ? 1 : 0);
      final nextTransparentCount =
          transparentRecipientCount + (isPrivate ? 0 : 1);

      if (nextPrivateCount > maxPrivateRecipients ||
          (!isPrivate && transparentAmount >= maxTransparentAmount)) {
        break;
      }
      final estimatedSize =
          _sparkBaseSize +
          _sparkInputSize +
          _sparkPrivateOutputSize * (nextPrivateCount + 1) +
          _transparentOutputSize * nextTransparentCount;
      if (estimatedSize * _witnessScaleFactor >= maxTransactionWeight) {
        break;
      }

      final nextFee = await estimateFee(
        privateRecipientCount: nextPrivateCount,
        transparentRecipientCount: nextTransparentCount,
      );
      if (nextFee < BigInt.zero) {
        throw Exception("Invalid Spark transaction fee.");
      }

      BigInt available = coinValue - amount - nextFee;
      if (!isPrivate) {
        final transparentAvailable = maxTransparentAmount - transparentAmount;
        if (available > transparentAvailable) {
          available = transparentAvailable;
        }
      }
      if (available <= BigInt.zero) {
        break;
      }

      final fragmentAmount = current.amount < available
          ? current.amount
          : available;
      fragments.add(
        SparkSpendRecipientFragment(
          type: current.recipient.type,
          index: current.recipient.index,
          amount: fragmentAmount,
        ),
      );
      amount += fragmentAmount;
      fee = nextFee;
      if (isPrivate) {
        privateRecipientCount = nextPrivateCount;
      } else {
        transparentRecipientCount = nextTransparentCount;
        transparentAmount += fragmentAmount;
      }

      current.amount -= fragmentAmount;
      if (current.amount == BigInt.zero) {
        recipientIndex++;
      } else {
        break;
      }
    }

    if (fragments.isEmpty) {
      continue;
    }

    plans.add(
      SingleInputSparkSpendPlan(
        coinIndex: coinIndex,
        fee: fee,
        recipients: List.unmodifiable(fragments),
      ),
    );
    if (plans.length == maxTransactions && recipientIndex < remaining.length) {
      throw Exception(
        "A Spark payment may use at most $maxTransactions transactions.",
      );
    }
  }

  if (recipientIndex != remaining.length) {
    throw Exception(
      "The available Spark coins cannot cover the amount and transaction fees.",
    );
  }

  return List.unmodifiable(plans);
}
