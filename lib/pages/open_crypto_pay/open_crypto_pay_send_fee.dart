import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

import '../../models/paymint/fee_object_model.dart';
import '../../utilities/amount/amount.dart';
import '../../utilities/enums/fee_rate_type_enum.dart';
import '../../utilities/eth_commons.dart';
import '../../utilities/logger.dart';
import '../../wallets/wallet/impl/ethereum_wallet.dart';
import '../../wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import '../../wallets/wallet/wallet.dart';
import '../../wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import '../../widgets/eth_fee_form.dart';

const _highFeeTitle = "High network fee";
String _highFeeMessage(String required, String fast) =>
    "The payment request requires a network fee of at least $required, "
    "above the current fast estimate of $fast.";
const _unmetFeeTitle = "Network fee too low";
const _unknownFeeTitle = "Network fee unknown";
const _unknownFeeMessage =
    "The network fee could not be estimated, so the payment request's "
    "minimum cannot be checked. Check the wallet's connection and sync.";
String _unmetFeeMessage(String required, String fastest) =>
    "The payment request requires a network fee of at least $required, "
    "above this wallet's fastest fee of $fastest.";

/// Fee values for a send, with the payment request's minimum fee applied.
typedef OpenCryptoPaySendFee = ({
  FeeRateType feeRateType,
  int? satsPerVByte,
  EthEIP1559Fee? ethFee,
});

/// Asks the user to confirm; false when they cancelled.
typedef OpenCryptoPayConfirm = Future<bool> Function(
  BuildContext context,
  String title,
  String message,
);

/// Tells the user the payment cannot be made yet.
typedef OpenCryptoPayNotify = Future<void> Function(
  BuildContext context,
  String title,
  String message,
);

/// The chosen fee, raised to the minimum when below it. Null when the user
/// cancelled the confirmation, no fee level reaches the minimum, or the fee
/// cannot be estimated.
Future<OpenCryptoPaySendFee?> openCryptoPaySendFee(
  BuildContext context,
  Wallet wallet, {
  required Amount amount,
  required num minFee,
  required OpenCryptoPaySendFee chosen,
  required OpenCryptoPayConfirm confirm,
  required OpenCryptoPayNotify unmet,
}) async {
  final bool isUtxo = wallet is ElectrumXInterface;
  final bool isEvm = wallet is EthereumWallet || wallet is EthTokenWallet;
  final FeeObject fees;
  try {
    fees = await wallet.fees;
  } catch (e, s) {
    Logging.instance.w(
      "OpenCryptoPay fee estimate unavailable",
      error: e,
      stackTrace: s,
    );
    if (!context.mounted) return null;
    return _feeUnknown(context, unmet);
  }
  if (!context.mounted) return null;
  if (isUtxo) return _utxoSendFee(context, fees, minFee, chosen, confirm);
  if (isEvm) {
    return _evmSendFee(
      context,
      wallet,
      fees as EthFeeObject,
      minFee,
      chosen,
      confirm,
    );
  }
  return _levelSendFee(context, wallet, fees, amount, minFee, chosen, unmet);
}

/// Picks the lowest fee level at or above the chosen one whose estimated fee
/// reaches the minimum.
Future<OpenCryptoPaySendFee?> _levelSendFee(
  BuildContext context,
  Wallet wallet,
  FeeObject fees,
  Amount amount,
  num minFee,
  OpenCryptoPaySendFee chosen,
  OpenCryptoPayNotify unmet,
) async {
  final required = BigInt.from(minFee.ceil());
  final levels = [
    (type: FeeRateType.slow, rate: fees.slow),
    (type: FeeRateType.average, rate: fees.medium),
    (type: FeeRateType.fast, rate: fees.fast),
  ];
  final start = levels.indexWhere((l) => l.type == chosen.feeRateType);
  Amount? fee;
  for (final level in levels.sublist(start < 0 ? 0 : start)) {
    try {
      fee = await wallet.estimateFeeFor(amount, level.rate);
    } catch (e, s) {
      Logging.instance.w(
        "OpenCryptoPay fee estimate unavailable",
        error: e,
        stackTrace: s,
      );
      if (!context.mounted) return null;
      return _feeUnknown(context, unmet);
    }
    // A zero estimate means the wallet cannot estimate yet.
    if (fee.raw <= BigInt.zero) {
      Logging.instance.w("OpenCryptoPay fee estimate is zero");
      if (!context.mounted) return null;
      return _feeUnknown(context, unmet);
    }
    if (fee.raw >= required) {
      return level.type == chosen.feeRateType
          ? chosen
          : (
              feeRateType: level.type,
              satsPerVByte: chosen.satsPerVByte,
              ethFee: chosen.ethFee,
            );
    }
  }
  final fastest = fee!;
  String coins(BigInt raw) {
    final amount = Amount(
      rawValue: raw,
      fractionDigits: fastest.fractionDigits,
    );
    return "${amount.decimal} ${wallet.cryptoCurrency.ticker}";
  }

  if (!context.mounted) return null;
  await unmet(
    context,
    _unmetFeeTitle,
    _unmetFeeMessage(coins(required), coins(fastest.raw)),
  );
  return null;
}

/// Stops the send when the fee cannot be checked against the minimum.
Future<OpenCryptoPaySendFee?> _feeUnknown(
  BuildContext context,
  OpenCryptoPayNotify unmet,
) async {
  await unmet(context, _unknownFeeTitle, _unknownFeeMessage);
  return null;
}

Future<OpenCryptoPaySendFee?> _utxoSendFee(
  BuildContext context,
  FeeObject fees,
  num minFee,
  OpenCryptoPaySendFee chosen,
  OpenCryptoPayConfirm confirm,
) async {
  final requiredPerKb = BigInt.from((minFee * 1000).ceil());
  final current = switch (chosen.feeRateType) {
    FeeRateType.fast => fees.fast,
    FeeRateType.average => fees.medium,
    FeeRateType.slow => fees.slow,
    FeeRateType.custom => BigInt.from((chosen.satsPerVByte ?? 0) * 1000),
  };
  if (current >= requiredPerKb) return chosen;
  final required = minFee.ceil();
  String perVByte(BigInt perKb) =>
      "${Decimal.fromBigInt(perKb).shift(-3).toStringAsFixed(2)} sats/vByte";
  if (requiredPerKb > fees.fast &&
      !await confirm(
        context,
        _highFeeTitle,
        _highFeeMessage("$required sats/vByte", perVByte(fees.fast)),
      )) {
    return null;
  }
  return (
    feeRateType: FeeRateType.custom,
    satsPerVByte: required,
    ethFee: chosen.ethFee,
  );
}

Future<OpenCryptoPaySendFee?> _evmSendFee(
  BuildContext context,
  Wallet wallet,
  EthFeeObject fees,
  num minFee,
  OpenCryptoPaySendFee chosen,
  OpenCryptoPayConfirm confirm,
) async {
  final minWei = BigInt.from(minFee.ceil());
  final current = switch (chosen.feeRateType) {
    FeeRateType.fast => fees.fast,
    FeeRateType.average => fees.medium,
    FeeRateType.slow => fees.slow,
    FeeRateType.custom => chosen.ethFee?.maxFeePerGasWei ?? BigInt.zero,
  };
  if (current >= minWei) return chosen;
  Decimal gwei(BigInt wei) => Decimal.fromBigInt(wei).shift(-9);
  if (minWei > fees.fast &&
      !await confirm(
        context,
        _highFeeTitle,
        _highFeeMessage(
          "${gwei(minWei).toStringAsFixed(2)} gwei",
          "${gwei(fees.fast).toStringAsFixed(2)} gwei",
        ),
      )) {
    return null;
  }
  // The priority fee tops the base fee up to the minimum gas price; the cap
  // gets the same base fee headroom as the presets.
  var priorityWei = minWei - fees.suggestBaseFee;
  if (priorityWei.isNegative) priorityWei = BigInt.zero;
  final maxFeeWei = fees.suggestBaseFee * BigInt.two + priorityWei;
  return (
    feeRateType: FeeRateType.custom,
    satsPerVByte: chosen.satsPerVByte,
    ethFee: EthEIP1559Fee(
      maxFeePerGasGwei: gwei(maxFeeWei),
      maxPriorityFeePerGasGwei: gwei(priorityWei),
      gasLimit:
          chosen.ethFee?.gasLimit ??
          (wallet is EthTokenWallet
              ? kEthereumTokenMinGasLimit
              : kEthereumMinGasLimit),
    ),
  );
}
