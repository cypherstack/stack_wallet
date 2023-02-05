import 'package:isar/isar.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

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
  @Index()
  final bool supportsFixedRate;

  /// Indicates if a currency is available on a fixed-rate flow
  @Index()
  final bool supportsEstimatedRate;

  /// (Optional - based on api call) Indicates whether the pair is
  /// currently supported by change now
  final bool? isAvailable;

  @Index()
  final bool isStackCoin;

  Currency({
    required this.exchangeName,
    required this.ticker,
    required this.name,
    required this.network,
    required this.image,
    this.externalId,
    required this.isFiat,
    required this.supportsFixedRate,
    required this.supportsEstimatedRate,
    this.isAvailable,
    required this.isStackCoin,
  });

  factory Currency.fromJson(
    Map<String, dynamic> json, {
    required String exchangeName,
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
        supportsFixedRate: json["supportsFixedRate"] as bool,
        supportsEstimatedRate: json["supportsEstimatedRate"] as bool,
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
      "supportsFixedRate": supportsFixedRate,
      "supportsEstimatedRate": supportsEstimatedRate,
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
    bool? supportsFixedRate,
    bool? supportsEstimatedRate,
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
      supportsFixedRate: supportsFixedRate ?? this.supportsFixedRate,
      supportsEstimatedRate:
          supportsEstimatedRate ?? this.supportsEstimatedRate,
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
