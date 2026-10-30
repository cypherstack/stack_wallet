import "package:decimal/decimal.dart";

/// A single AML signal returned when a transaction status is `aml_check_failed`
class AmlErrorSignal {
  AmlErrorSignal({
    required this.signal,
    required this.signalId,
    required this.signalPercent,
    required this.level,
  });

  final String signal;
  final int signalId;
  final double signalPercent;
  final int level;

  factory AmlErrorSignal.fromJson(Map<String, dynamic> json) => AmlErrorSignal(
    signal: json["signal"] as String,
    signalId: json["signalId"] as int,
    signalPercent: json["signalPercent"] as double,
    level: json["level"] as int,
  );

  Map<String, dynamic> toMap() => {
    "signal": signal,
    "signalId": signalId,
    "signalPercent": signalPercent,
    "level": level,
  };

  @override
  String toString() => toMap().toString();
}

class Transaction {
  Transaction({
    required this.transactionId,
    required this.status,
    required this.coinFrom,
    required this.coinFromName,
    required this.coinFromNetwork,
    required this.coinTo,
    required this.coinToName,
    required this.coinToNetwork,
    required this.depositAmount,
    required this.withdrawalAmount,
    required this.realDepositAmount,
    required this.realWithdrawalAmount,
    required this.deposit,
    required this.depositExtraId,
    required this.withdrawal,
    required this.withdrawalExtraId,
    required this.rate,
    required this.hashIn,
    required this.hashOut,
    required this.returnAddress,
    required this.returnHash,
    required this.returnAmount,
    required this.returnExtraId,
    required this.isFloat,
    required this.coinFromExplorerUrl,
    required this.coinToExplorerUrl,
    required this.needConfirmations,
    required this.confirmations,
    required this.executionTime,
    required this.profit,
    required this.amlErrorSignals,
  });

  final String transactionId;
  final String status;
  final String coinFrom;
  final String coinFromName;
  final String coinFromNetwork;
  final String coinTo;
  final String coinToName;
  final String coinToNetwork;
  final Decimal depositAmount;
  final Decimal withdrawalAmount;

  /// `GET /v1/transaction/{id}` only — received deposit amount.
  final Decimal? realDepositAmount;

  /// `GET /v1/transaction/{id}` only — recalculated withdrawal amount.
  final Decimal? realWithdrawalAmount;
  final String deposit;
  final String? depositExtraId;
  final String withdrawal;
  final String? withdrawalExtraId;
  final Decimal rate;

  /// `GET /v1/transaction/{id}` only — incoming transaction hash.
  final String? hashIn;

  /// `GET /v1/transaction/{id}` only — outgoing transaction hash.
  final String? hashOut;
  final String? returnAddress;
  final String? returnHash;
  final Decimal? returnAmount;
  final String? returnExtraId;
  final bool isFloat;
  final String coinFromExplorerUrl;
  final String coinToExplorerUrl;
  final int needConfirmations;

  /// `GET /v1/transaction/{id}` only — current number of confirmations.
  final int? confirmations;

  /// `GET /v1/transaction/{id}` only — exchange duration in seconds.
  final int? executionTime;

  /// `GET /v1/transaction/{id}` only — bonus value in BTC when a promo code
  /// was used.
  final Decimal? profit;
  final List<AmlErrorSignal> amlErrorSignals;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final String? rawRealDeposit = json["real_deposit_amount"] as String?;
    final String? rawRealWithdrawal = json["real_withdrawal_amount"] as String?;
    final num? rawProfit = json["profit"] as num?;
    return Transaction(
      transactionId: json["transaction_id"] as String,
      status: json["status"] as String,
      coinFrom: json["coin_from"] as String,
      coinFromName: json["coin_from_name"] as String,
      coinFromNetwork: json["coin_from_network"] as String,
      coinTo: json["coin_to"] as String,
      coinToName: json["coin_to_name"] as String,
      coinToNetwork: json["coin_to_network"] as String,
      depositAmount: Decimal.parse(json["deposit_amount"] as String),
      withdrawalAmount: Decimal.parse(json["withdrawal_amount"] as String),
      realDepositAmount: rawRealDeposit == null
          ? null
          : Decimal.tryParse(rawRealDeposit),
      realWithdrawalAmount: rawRealWithdrawal == null
          ? null
          : Decimal.tryParse(rawRealWithdrawal),
      deposit: json["deposit"] as String,
      depositExtraId: json["deposit_extra_id"] as String?,
      withdrawal: json["withdrawal"] as String,
      withdrawalExtraId: json["withdrawal_extra_id"] as String?,
      rate: Decimal.parse(json["rate"] as String),
      hashIn: json["hash_in"] as String?,
      hashOut: json["hash_out"] as String?,
      returnAddress: json["return"] as String?,
      returnHash: json["return_hash"] as String?,
      returnAmount: Decimal.tryParse(json["return_amount"] as String? ?? ""),
      returnExtraId: json["return_extra_id"] as String?,
      isFloat: switch (json["is_float"]) {
        final bool value => value,
        "true" => true,
        _ => false,
      },
      coinFromExplorerUrl: json["coin_from_explorer_url"] as String,
      coinToExplorerUrl: json["coin_to_explorer_url"] as String,
      needConfirmations: json["need_confirmations"] as int,
      confirmations: json["confirmations"] as int?,
      executionTime: json["execution_time"] as int?,
      profit: rawProfit == null ? null : Decimal.parse(rawProfit.toString()),
      amlErrorSignals: ((json["aml_error_signals"] as List?) ?? const [])
          .map((e) => AmlErrorSignal.fromJson((e as Map).cast()))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    "transaction_id": transactionId,
    "status": status,
    "coin_from": coinFrom,
    "coin_from_name": coinFromName,
    "coin_from_network": coinFromNetwork,
    "coin_to": coinTo,
    "coin_to_name": coinToName,
    "coin_to_network": coinToNetwork,
    "deposit_amount": depositAmount.toString(),
    "withdrawal_amount": withdrawalAmount.toString(),
    "real_deposit_amount": realDepositAmount?.toString(),
    "real_withdrawal_amount": realWithdrawalAmount?.toString(),
    "deposit": deposit,
    "deposit_extra_id": depositExtraId,
    "withdrawal": withdrawal,
    "withdrawal_extra_id": withdrawalExtraId,
    "rate": rate.toString(),
    "hash_in": hashIn,
    "hash_out": hashOut,
    "return": returnAddress,
    "return_hash": returnHash,
    "return_amount": returnAmount?.toString(),
    "return_extra_id": returnExtraId,
    "is_float": isFloat,
    "coin_from_explorer_url": coinFromExplorerUrl,
    "coin_to_explorer_url": coinToExplorerUrl,
    "need_confirmations": needConfirmations,
    "confirmations": confirmations,
    "execution_time": executionTime,
    "profit": profit?.toString(),
    "aml_error_signals": amlErrorSignals.map((e) => e.toMap()).toList(),
  };

  @override
  String toString() => toMap().toString();
}
