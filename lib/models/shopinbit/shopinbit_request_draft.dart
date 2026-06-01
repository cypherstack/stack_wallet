import 'shopinbit_enums.dart';

class ShopinbitRequestDraft {
  final ShopInBitCategory category;
  final String requestDescription;
  final String deliveryCountry;
  final String? voucherCode;

  ShopinbitRequestDraft({
    required this.category,
    required this.requestDescription,
    required this.deliveryCountry,
    required this.voucherCode,
  });

  Map<String, dynamic> toMap() => {
    "category": category.apiValue,
    "requestDescription": requestDescription,
    "deliveryCountry": deliveryCountry,
    "voucherCode": voucherCode,
  };

  @override
  String toString() => toMap().toString();
}
