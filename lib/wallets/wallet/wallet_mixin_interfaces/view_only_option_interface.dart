import 'dart:convert';

import '../../crypto_currency/interfaces/view_only_option_currency_interface.dart';
import '../wallet.dart';

class ViewOnlyWalletData {
  final String? address;
  final String? privateViewKey;

  ViewOnlyWalletData({required this.address, required this.privateViewKey});

  factory ViewOnlyWalletData.fromJsonEncodedString(String jsonEncodedString) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);
    return ViewOnlyWalletData(
      address: json["address"] as String?,
      privateViewKey: json["privateViewKey"] as String?,
    );
  }

  String toJsonEncodedString() => jsonEncode({
        "address": address,
        "privateViewKey": privateViewKey,
      });
}

mixin ViewOnlyOptionInterface<T extends ViewOnlyOptionCurrencyInterface>
    on Wallet<T> {
  bool get isViewOnly;

  Future<void> recoverViewOnly();

  Future<ViewOnlyWalletData> getViewOnlyWalletData();
}
