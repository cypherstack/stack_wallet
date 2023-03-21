import 'package:isar/isar.dart';
import 'package:stackduo/models/isar/exchange_cache/pair.dart';
import 'package:stackduo/utilities/enums/coin_enum.dart';

part 'currency.g.dart';

@Collection(accessor: "currencies")
class Currency {
  Id? id;

  @Index()
  final String exchangeName;

  /// Currency ticker
  @Index(composite: [
    CompositeIndex("exchangeName"),
    CompositeIndex("name"),
  ])
  final String ticker;

  /// Currency name
  final String name;

  /// Currency network
  final String network;

  /// Currency logo url
  final String image;

  /// external id if it exists
  final String? externalId;

  /// Indicates if a currency is a fiat currency (EUR, USD)
  final bool isFiat;

  /// Indicates if a currency is available on a fixed-rate flow
  @enumerated
  final SupportedRateType rateType;

  /// (Optional - based on api call) Indicates whether the pair is
  /// currently supported by change now
  final bool? isAvailable;

  @Index()
  final bool isStackCoin;

  @ignore
  bool get supportsFixedRate =>
      rateType == SupportedRateType.fixed || rateType == SupportedRateType.both;

  @ignore
  bool get supportsEstimatedRate =>
      rateType == SupportedRateType.estimated ||
      rateType == SupportedRateType.both;

  Currency({
    required this.exchangeName,
    required this.ticker,
    required this.name,
    required this.network,
    required this.image,
    this.externalId,
    required this.isFiat,
    required this.rateType,
    this.isAvailable,
    required this.isStackCoin,
  });

  factory Currency.fromJson(
    Map<String, dynamic> json, {
    required String exchangeName,
    required SupportedRateType rateType,
  }) {
    try {
      final ticker = (json["ticker"] as String).toUpperCase();

      return Currency(
        exchangeName: exchangeName,
        ticker: ticker,
        name: json["name"] as String,
        network: json["network"] as String? ?? "",
        image: json["image"] as String,
        externalId: json["externalId"] as String?,
        isFiat: json["isFiat"] as bool,
        rateType: rateType,
        isAvailable: json["isAvailable"] as bool?,
        isStackCoin:
            json["isStackCoin"] as bool? ?? Currency.checkIsStackCoin(ticker),
      )..id = json["id"] as int?;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "id": id,
      "exchangeName": exchangeName,
      "ticker": ticker,
      "name": name,
      "network": network,
      "image": image,
      "externalId": externalId,
      "isFiat": isFiat,
      "rateType": rateType,
      "isAvailable": isAvailable,
      "isStackCoin": isStackCoin,
    };

    return map;
  }

  Currency copyWith({
    Id? id,
    String? exchangeName,
    String? ticker,
    String? name,
    String? network,
    String? image,
    String? externalId,
    bool? isFiat,
    SupportedRateType? rateType,
    bool? isAvailable,
    bool? isStackCoin,
  }) {
    return Currency(
      exchangeName: exchangeName ?? this.exchangeName,
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      network: network ?? this.network,
      image: image ?? this.image,
      externalId: externalId ?? this.externalId,
      isFiat: isFiat ?? this.isFiat,
      rateType: rateType ?? this.rateType,
      isAvailable: isAvailable ?? this.isAvailable,
      isStackCoin: isStackCoin ?? this.isStackCoin,
    )..id = id ?? this.id;
  }

  @override
  String toString() {
    return "Currency: ${toJson()}";
  }

  static bool checkIsStackCoin(String ticker) {
    try {
      coinFromTickerCaseInsensitive(ticker);
      return true;
    } catch (_) {
      return false;
    }
  }
}
