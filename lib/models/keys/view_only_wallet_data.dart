import 'dart:convert';

import '../../wallets/wallet/wallet_mixin_interfaces/extended_keys_interface.dart';
import 'key_data_interface.dart';

// do not remove or change the order of these enum values
enum ViewOnlyWalletType {
  cryptonote,
  addressOnly,
  xPub,
  spark;
}

sealed class ViewOnlyWalletData with KeyDataInterface {
  @override
  final String walletId;

  ViewOnlyWalletType get type;

  ViewOnlyWalletData({
    required this.walletId,
  });

  static ViewOnlyWalletData fromJsonEncodedString(
    String jsonEncodedString, {
    required String walletId,
  }) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);
    final type = ViewOnlyWalletType.values[json["type"] as int];

    switch (type) {
      case ViewOnlyWalletType.cryptonote:
        return CryptonoteViewOnlyWalletData.fromJsonEncodedString(
          jsonEncodedString,
          walletId: walletId,
        );

      case ViewOnlyWalletType.addressOnly:
        return AddressViewOnlyWalletData.fromJsonEncodedString(
          jsonEncodedString,
          walletId: walletId,
        );

      case ViewOnlyWalletType.xPub:
        return ExtendedKeysViewOnlyWalletData.fromJsonEncodedString(
          jsonEncodedString,
          walletId: walletId,
        );

      case ViewOnlyWalletType.spark:
        return SparkViewOnlyWalletData.fromJsonEncodedString(
          jsonEncodedString,
          walletId: walletId,
        );
    }
  }

  String toJsonEncodedString();
}

class CryptonoteViewOnlyWalletData extends ViewOnlyWalletData {
  @override
  final type = ViewOnlyWalletType.cryptonote;

  final String address;
  final String privateViewKey;

  CryptonoteViewOnlyWalletData({
    required super.walletId,
    required this.address,
    required this.privateViewKey,
  });

  static CryptonoteViewOnlyWalletData fromJsonEncodedString(
    String jsonEncodedString, {
    required String walletId,
  }) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);

    return CryptonoteViewOnlyWalletData(
      walletId: walletId,
      address: json["address"] as String,
      privateViewKey: json["privateViewKey"] as String,
    );
  }

  @override
  String toJsonEncodedString() => jsonEncode({
        "type": type.index,
        "address": address,
        "privateViewKey": privateViewKey,
      });
}

class AddressViewOnlyWalletData extends ViewOnlyWalletData {
  @override
  final type = ViewOnlyWalletType.addressOnly;

  final String address;

  AddressViewOnlyWalletData({
    required super.walletId,
    required this.address,
  });

  static AddressViewOnlyWalletData fromJsonEncodedString(
    String jsonEncodedString, {
    required String walletId,
  }) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);

    return AddressViewOnlyWalletData(
      walletId: walletId,
      address: json["address"] as String,
    );
  }

  @override
  String toJsonEncodedString() => jsonEncode({
        "type": type.index,
        "address": address,
      });
}

class ExtendedKeysViewOnlyWalletData extends ViewOnlyWalletData {
  @override
  final type = ViewOnlyWalletType.xPub;

  final List<XPub> xPubs;

  ExtendedKeysViewOnlyWalletData({
    required super.walletId,
    required List<XPub> xPubs,
  }) : xPubs = List.unmodifiable(xPubs);

  static ExtendedKeysViewOnlyWalletData fromJsonEncodedString(
    String jsonEncodedString, {
    required String walletId,
  }) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);

    return ExtendedKeysViewOnlyWalletData(
      walletId: walletId,
      xPubs: List<Map<String, dynamic>>.from((json["xPubs"] as List))
          .map(
            (e) => XPub(
              path: e["path"] as String,
              encoded: e["encoded"] as String,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  String toJsonEncodedString() => jsonEncode({
        "type": type.index,
        "xPubs": [
          ...xPubs.map(
            (e) => {
              "path": e.path,
              "encoded": e.encoded,
            },
          ),
        ],
      });
}

class SparkViewOnlyWalletData extends ViewOnlyWalletData {
  @override
  final type = ViewOnlyWalletType.spark;

  final String viewKey;

  SparkViewOnlyWalletData({
    required super.walletId,
    required this.viewKey,
  });

  static SparkViewOnlyWalletData fromJsonEncodedString(
    String jsonEncodedString, {
    required String walletId,
  }) {
    final map = jsonDecode(jsonEncodedString) as Map;
    final json = Map<String, dynamic>.from(map);

    return SparkViewOnlyWalletData(
      walletId: walletId,
      viewKey: json["viewKey"] as String,
    );
  }

  @override
  String toJsonEncodedString() => jsonEncode({
        "type": type.index,
        "viewKey": viewKey,
      });
}
