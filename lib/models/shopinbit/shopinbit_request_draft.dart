import 'shopinbit_enums.dart';

class ShopinbitRequestDraft {
  final ShopInBitCategory category;
  final String requestDescription;
  final String deliveryCountryName;
  final String deliveryCountryCode;
  final String? deliveryState;
  final String? voucherCode;

  bool get requiresState => switch (deliveryCountryCode) {
    "US" || "CA" => category != .travel,
    _ => false,
  };

  ShopinbitRequestDraft({
    required this.category,
    required this.requestDescription,
    required this.deliveryCountryName,
    required this.deliveryCountryCode,
    required this.deliveryState,
    required this.voucherCode,
  });

  Map<String, dynamic> toMap() => {
    "category": category.apiValue,
    "requestDescription": requestDescription,
    "deliveryCountryName": deliveryCountryName,
    "deliveryCountryCode": deliveryCountryCode,
    "deliveryState": deliveryState,
    "voucherCode": voucherCode,
  };

  @override
  String toString() => toMap().toString();
}
