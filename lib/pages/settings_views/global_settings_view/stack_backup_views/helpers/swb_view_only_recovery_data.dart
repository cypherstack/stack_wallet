import 'dart:convert';

import '../../../../../models/keys/view_only_wallet_data.dart';
import '../../../../../wallets/isar/models/wallet_info.dart';

class SWBViewOnlyRecoveryData {
  final String encodedData;
  final Map<String, dynamic> otherData;

  const SWBViewOnlyRecoveryData({
    required this.encodedData,
    required this.otherData,
  });

  String get otherDataJsonString => jsonEncode(otherData);
}

void normalizeSWBViewOnlyWalletBackups(List<dynamic> wallets) {
  for (final entry in wallets) {
    if (entry is! Map) {
      throw const FormatException("Cannot restore invalid wallet record");
    }
    final wallet = Map<String, dynamic>.from(entry);
    final walletName = wallet["name"];
    final walletId = wallet["id"];
    if (walletName is! String || walletId is! String) {
      throw const FormatException("Cannot restore invalid wallet record");
    }

    Map<String, dynamic>? otherData;
    if (wallet["otherDataJsonString"] is String) {
      try {
        final decoded = jsonDecode(wallet["otherDataJsonString"] as String);
        otherData = Map<String, dynamic>.from(decoded as Map);
      } catch (_) {
        if (wallet["viewOnlyWalletDataKey"] == null) {
          continue;
        }
      }
    }

    final normalized = normalizeSWBViewOnlyRecoveryData(
      operation: "restore",
      walletName: walletName,
      walletId: walletId,
      otherData: otherData,
      encodedData: wallet["viewOnlyWalletDataKey"],
    );
    if (normalized != null) {
      entry["otherDataJsonString"] = normalized.otherDataJsonString;
    }
  }
}

SWBViewOnlyRecoveryData? normalizeSWBViewOnlyRecoveryData({
  required String operation,
  required String walletName,
  required String walletId,
  required Map<String, dynamic>? otherData,
  required Object? encodedData,
}) {
  final declaresViewOnly = otherData?[WalletInfoKeys.isViewOnlyKey] == true;

  if (encodedData == null) {
    if (declaresViewOnly) {
      throw FormatException(
        'Cannot $operation view-only wallet "$walletName": '
        'recovery data is missing',
      );
    }
    return null;
  }

  if (encodedData is! String) {
    throw FormatException(
      'Cannot $operation view-only wallet "$walletName": '
      'recovery data is invalid',
    );
  }

  final ViewOnlyWalletData data;
  try {
    data = ViewOnlyWalletData.fromJsonEncodedString(
      encodedData,
      walletId: walletId,
    );
  } catch (_) {
    throw FormatException(
      'Cannot $operation view-only wallet "$walletName": '
      'recovery data is invalid',
    );
  }

  if (!_hasRequiredRecoveryData(data)) {
    throw FormatException(
      'Cannot $operation view-only wallet "$walletName": '
      'recovery data is incomplete',
    );
  }

  final storedType = otherData?[WalletInfoKeys.viewOnlyTypeIndexKey];
  if (storedType != null &&
      (storedType is! int || storedType != data.type.index)) {
    throw FormatException(
      'Cannot $operation view-only wallet "$walletName": '
      'recovery metadata conflicts with its data',
    );
  }

  final normalized = Map<String, dynamic>.from(otherData ?? const {})
    ..[WalletInfoKeys.isViewOnlyKey] = true
    ..[WalletInfoKeys.viewOnlyTypeIndexKey] = data.type.index;

  return SWBViewOnlyRecoveryData(
    encodedData: encodedData,
    otherData: Map.unmodifiable(normalized),
  );
}

bool _hasRequiredRecoveryData(ViewOnlyWalletData data) => switch (data) {
  CryptonoteViewOnlyWalletData() =>
    data.address.isNotEmpty && data.privateViewKey.isNotEmpty,
  AddressViewOnlyWalletData() => data.address.isNotEmpty,
  ExtendedKeysViewOnlyWalletData() =>
    data.xPubs.isNotEmpty &&
        data.xPubs.every((xPub) => xPub.encoded.isNotEmpty),
  SparkViewOnlyWalletData() => data.viewKey.isNotEmpty,
};
