import 'shopinbit_enums.dart';

class ShopinbitRequestDraft {
  final ShopInBitCategory category;
  final String requestDescription;
  final String deliveryCountryName;
  final String deliveryCountryCode;
  final String? voucherCode;

  ShopinbitRequestDraft({
    required this.category,
    required this.requestDescription,
    required this.deliveryCountryName,
    required this.deliveryCountryCode,
    required this.voucherCode,
  });

  Map<String, dynamic> toMap() => {
    "category": category.apiValue,
    "requestDescription": requestDescription,
    "deliveryCountryName": deliveryCountryName,
    "deliveryCountryCode": deliveryCountryCode,
    "voucherCode": voucherCode,
  };

  @override
  String toString() => toMap().toString();
}
