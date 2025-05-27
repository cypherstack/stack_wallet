import "package:decimal/decimal.dart";

import "../../../services/exchange/change_now/change_now_api.dart";

/// Immutable model representing exchange rate information.
class EstimatedExchangeAmount {
  /// Ticker of the currency you want to exchange.
  final String fromCurrency;

  /// Network of the currency you want to exchange.
  final String fromNetwork;

  /// Ticker of the currency you want to receive.
  final String toCurrency;

  /// Network of the currency you want to receive.
  final String toNetwork;

  /// Type of exchange flow. Either `standard` or `fixed-rate`.
  final CNFlow flow;

  /// Direction of exchange flow. Either `direct` or `reverse`.
  ///
  /// - `direct`: set amount for `fromCurrency`, get amount of `toCurrency`.
  /// - `reverse`: set amount for `toCurrency`, get amount of `fromCurrency`.
  final CNExchangeType type;

  /// RateId is needed for fixed-rate flow. Used to freeze estimated amount.
  final String? rateId;

  /// Date and time before which the estimated amount is valid if using `rateId`.
  final DateTime? validUntil;

  /// Dash-separated min and max estimated time in minutes.
  final String? transactionSpeedForecast;

  /// Some warnings, such as if a currency has moved to another network or transactions take longer.
  final String? warningMessage;

  /// Deposit fee in the selected currency.
  final Decimal depositFee;

  /// Withdrawal fee in the selected currency.
  final Decimal withdrawalFee;

  /// A personal and permanent identifier under which information is stored in the database.
  ///
  /// Only enabled for special partners.
  final String? userId;

  /// Exchange amount of `fromCurrency`.
  ///
  /// If `type=reverse`, this is an estimated value.
  final Decimal fromAmount;

  /// Exchange amount of `toCurrency`.
  ///
  /// If `type=direct`, this is an estimated value.
  final Decimal toAmount;

  /// Creates an immutable [EstimatedExchangeAmount] instance.
  const EstimatedExchangeAmount({
    required this.fromCurrency,
    required this.fromNetwork,
    required this.toCurrency,
    required this.toNetwork,
    required this.flow,
    required this.type,
    required this.rateId,
    required this.validUntil,
    this.transactionSpeedForecast,
    this.warningMessage,
    required this.depositFee,
    required this.withdrawalFee,
    this.userId,
    required this.fromAmount,
    required this.toAmount,
  });

  /// Creates an instance of [EstimatedExchangeAmount] from a JSON map.
  factory EstimatedExchangeAmount.fromJson(Map<String, dynamic> json) {
    return EstimatedExchangeAmount(
      fromCurrency: json["fromCurrency"] as String,
      fromNetwork: json["fromNetwork"] as String,
      toCurrency: json["toCurrency"] as String,
      toNetwork: json["toNetwork"] as String,
      flow: _parseFlow(json["flow"] as String),
      type: _parseType(json["type"] as String),
      rateId: json["rateId"] as String?,
      validUntil: DateTime.tryParse(json["validUntil"] as String? ?? ""),
      transactionSpeedForecast: json["transactionSpeedForecast"] as String?,
      warningMessage: json["warningMessage"] as String?,
      depositFee: Decimal.parse(json["depositFee"].toString()),
      withdrawalFee: Decimal.parse(json["withdrawalFee"].toString()),
      userId: json["userId"]?.toString(),
      fromAmount: Decimal.parse(json["fromAmount"].toString()),
      toAmount: Decimal.parse(json["toAmount"].toString()),
    );
  }

  /// Converts this [EstimatedExchangeAmount] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "fromCurrency": fromCurrency,
      "fromNetwork": fromNetwork,
      "toCurrency": toCurrency,
      "toNetwork": toNetwork,
      "flow": flow.name.replaceAll("fixedRate", "fixed-rate"),
      "type": type.name,
      "rateId": rateId,
      "validUntil": validUntil?.toIso8601String(),
      "transactionSpeedForecast": transactionSpeedForecast,
      "warningMessage": warningMessage,
      "depositFee": depositFee.toString(),
      "withdrawalFee": withdrawalFee.toString(),
      "userId": userId,
      "fromAmount": fromAmount.toString(),
      "toAmount": toAmount.toString(),
    };
  }

  static CNFlow _parseFlow(String value) {
    switch (value) {
      case "fixed-rate":
        return CNFlow.fixedRate;
      case "standard":
      default:
        return CNFlow.standard;
    }
  }

  static CNExchangeType _parseType(String value) {
    switch (value) {
      case "reverse":
        return CNExchangeType.reverse;
      case "direct":
      default:
        return CNExchangeType.direct;
    }
  }

  @override
  String toString() {
    return "EstimatedExchangeAmount: ${toJson()}";
  }
}
