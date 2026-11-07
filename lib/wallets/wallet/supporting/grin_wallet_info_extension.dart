import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../isar/models/wallet_info.dart';

extension GrinWalletInfoExtension on WalletInfo {
  GrinWalletData? get grinData {
    final data = otherData[WalletInfoKeys.grinData];
    if (data is! String) return null;
    try {
      return GrinWalletData.fromMap(
        Map<String, dynamic>.from(jsonDecode(data) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateGrinData({
    required GrinWalletData grinData,
    required Isar isar,
  }) async {
    await updateOtherData(
      newEntries: {WalletInfoKeys.grinData: jsonEncode(grinData.toMap())},
      isar: isar,
    );
  }
}

/// Grin state Stack keeps beside the native wallet.
class GrinWalletData {
  const GrinWalletData({required this.creationHeight, this.pendingScanFrom});

  /// The height the wallet was created or restored from.
  final int creationHeight;

  /// Where an unfinished scan resumes, or null when none is pending.
  final int? pendingScanFrom;

  Map<String, dynamic> toMap() => {
    "creationHeight": creationHeight,
    "pendingScanFrom": pendingScanFrom,
  };

  factory GrinWalletData.fromMap(Map<String, dynamic> map) => GrinWalletData(
    creationHeight: map["creationHeight"] as int,
    pendingScanFrom: map["pendingScanFrom"] as int?,
  );

  GrinWalletData withPendingScanFrom(int? height) =>
      GrinWalletData(creationHeight: creationHeight, pendingScanFrom: height);

  @override
  String toString() =>
      "GrinWalletData(creationHeight: $creationHeight, "
      "pendingScanFrom: $pendingScanFrom)";
}
