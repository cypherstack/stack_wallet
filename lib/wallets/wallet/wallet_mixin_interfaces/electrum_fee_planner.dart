enum ElectrumFeeMode { fixedAmount, subtractFeeFromAmount, sweep }

final class ElectrumFeeInsufficientFunds implements Exception {
  /// The fee the rejected transaction needed to pay. Callers retrying with
  /// more funds should select inputs covering at least the recipient amount
  /// plus this fee.
  final BigInt requiredFee;

  const ElectrumFeeInsufficientFunds({required this.requiredFee});
}

typedef ElectrumFeeTransactionBuilder<T> =
    Future<({T transaction, int vSize})> Function({
      required BigInt recipientAmount,
      BigInt? changeAmount,
    });

final class ElectrumFeeResult<T> {
  final T transaction;
  final BigInt fee;

  const ElectrumFeeResult({required this.transaction, required this.fee});
}

/// The fee paid is always at least [minimumFeeAmount] (when non-null), the
/// rate-based fee for the measured vSize, and one sat per vByte, whichever is
/// greatest. [minimumFeeAmount] is a floor, not an exact override.
Future<ElectrumFeeResult<T>> planElectrumFee<T>({
  required ElectrumFeeMode mode,
  required BigInt inputTotal,
  required BigInt recipientAmount,
  required BigInt dustLimit,
  required int? satsPerVByte,
  required BigInt feeRatePerKB,
  required BigInt? minimumFeeAmount,
  required ElectrumFeeTransactionBuilder<T> build,
}) async {
  if (mode != ElectrumFeeMode.sweep && recipientAmount < dustLimit) {
    throw Exception(
      "Recipient amount ($recipientAmount) is below dust limit ($dustLimit)",
    );
  }

  BigInt requiredFeeFor(int vSize) {
    final BigInt rateFee;
    if (satsPerVByte != null) {
      rateFee = BigInt.from(satsPerVByte * vSize);
    } else {
      final kb = BigInt.from(1000);
      rateFee = (feeRatePerKB * BigInt.from(vSize) + kb - BigInt.one) ~/ kb;
    }

    final vSizeFloor = BigInt.from(vSize);
    final minimumFloor = minimumFeeAmount ?? BigInt.zero;
    final feeFloor = rateFee > minimumFloor ? rateFee : minimumFloor;
    return feeFloor > vSizeFloor ? feeFloor : vSizeFloor;
  }

  final selectedSurplus = inputTotal - recipientAmount;
  final subDustSurplus =
      mode == .subtractFeeFromAmount &&
          selectedSurplus > BigInt.zero &&
          selectedSurplus < dustLimit
      ? selectedSurplus
      : BigInt.zero;
  BigInt fee = -subDustSurplus;
  while (true) {
    final amountToSend = switch (mode) {
      .fixedAmount => recipientAmount,
      .subtractFeeFromAmount => recipientAmount - fee,
      .sweep => inputTotal - fee,
    };
    if (amountToSend < dustLimit) {
      throw Exception("Estimated fee ($fee sats) leaves no spendable amount!");
    }

    final possibleChange = switch (mode) {
      .fixedAmount => inputTotal - recipientAmount - fee,
      .subtractFeeFromAmount => inputTotal - recipientAmount,
      .sweep => null,
    };
    final changeAmount = possibleChange != null && possibleChange >= dustLimit
        ? possibleChange
        : null;

    final built = await build(
      recipientAmount: amountToSend,
      changeAmount: changeAmount,
    );
    final feePaid = inputTotal - amountToSend - (changeAmount ?? BigInt.zero);
    final requiredFee = requiredFeeFor(built.vSize);
    if (feePaid >= requiredFee) {
      return ElectrumFeeResult(transaction: built.transaction, fee: feePaid);
    }
    if (mode == ElectrumFeeMode.fixedAmount && possibleChange! < dustLimit) {
      throw ElectrumFeeInsufficientFunds(requiredFee: requiredFee);
    }
    fee += requiredFee - feePaid;
  }
}
